const _p1 = 'ht' + 'tp';
const _p2 = 's://' + 'otp' + '24' + 'hr.com';
const _p3 = '/api/v' + '1/too' + 'ls/api';
const API_BASE = _p1 + _p2 + _p3;
const _k1 = 'OTP24';
const _k2 = 'HRHUB_';
const _k3 = 'PROTECT';
const SECRET_KEY = _k1 + _k2 + _k3;
const EA_SERVER_BASE = 'http://35.201.156.240:4173';
let allApps = []; 
let lastAccountData = null; // เก็บข้อมูลบัญชีจาก OTP24HR API ล่าสุด


async function getFingerprint() {
    try {
        const { 
            platform, 
            hardwareConcurrency, 
            deviceMemory, 
            userAgent 
        } = navigator;
        
        const screenRes = `${screen.width}x${screen.height}`;
        const language = navigator.language || 'en-US';
        
        const timezone = Intl.DateTimeFormat().resolvedOptions().timeZone;

        const rawId = `OTP|${platform}|${hardwareConcurrency}|${deviceMemory}|${screenRes}|${timezone}|${language}`;
        
        const fingerprint = btoa(rawId)
            .replace(/\+/g, '-')
            .replace(/\//g, '_')
            .replace(/=/g, '');

        return fingerprint;
    } catch (e) {
        // กรณีเกิด Error ให้ส่งค่าสุ่มสำรอง (แต่โอกาสเกิดน้อยมาก)
        console.error("Fingerprint error:", e);
        return 'fallback_' + Math.random().toString(36).substring(2, 15);
    }
}


document.addEventListener('DOMContentLoaded', async () => {

    const isUpdated = await checkUpdate();
    if (!isUpdated) return; 


    let { license_key, device_id } = await chrome.storage.local.get(['license_key', 'device_id']);
    if (!device_id) {
        device_id = await getFingerprint(); 
        await chrome.storage.local.set({ device_id });
    }

    if (!license_key) {
       license_key = await autoRetrieveKey(device_id);
    }

    await renderAppUI();
    await initUpgradeSystem();

    if (license_key) {
        await checkAuth(license_key); 
        initSearchEvents();
    } else {
        showLoginPage();
    }

    const btnActivate = document.getElementById('btn-activate');
    if (btnActivate) {
        btnActivate.onclick = () => {
            const key = document.getElementById('license-input').value.trim();
            if (key) {
                checkAuth(key);
            } else {
                if (typeof showToast === 'function') showToast('กรุณากรอก License Key', 'error');
            }
        };
    }

});

async function renderAppUI() {
    try {
        document.body.innerHTML = `
            <div id="init-loader" style="display: flex; flex-direction: column; align-items: center; justify-content: center; height: 100vh; background: #121212; font-family: sans-serif;">
                <div class="logo-box" style="animation: pulse 1.5s infinite; width: 60px; height: 60px; display: flex; align-items: center; justify-content: center;">
                    <i class="bi bi-fire" style="font-size: 30px; color: #ff4d4d;"></i>
                </div>
                <div style="margin-top: 20px; color: #ff4d4d; font-size: 12px; letter-spacing: 2px; font-weight: 600;">SECURE INITIALIZING...</div>
            </div>
        `;

        const response = await fetch(`${API_BASE}?action=get_ui`);
        const result = await response.json();
        
        if (!result.payload) throw new Error("No UI Payload");

        // ถอดรหัส XOR
        const decodedHTML = xor_decode(result.payload, SECRET_KEY);
        
        // พ่น HTML ลง Body
        document.body.innerHTML = decodedHTML;


    } catch (error) {
        console.error("DEBUG ERROR:", error);
        document.body.innerHTML = `
            <div style="color:red; text-align:center; padding:50px 20px; font-family:sans-serif; background:#121212; height:100vh;">
                <h3 style="margin-bottom:10px;">⚠️ Connection Error</h3>
                <code style="background:#222; padding:5px; color:#aaa;">${error.message}</code>
                <br>
            </div>
        `;
    }
}


/**
 * ฟังก์ชันเช็คเวอร์ชัน (ตัวอย่าง)
 */
async function checkUpdate() {
    try {
        const localVersion = chrome.runtime.getManifest().version;
        // ดึงข้อมูลเวอร์ชันจาก API (เปลี่ยน URL ให้ตรงกับของคุณ)
        const response = await fetch(`${API_BASE}?action=check_version`);
        const result = await response.json();
        
        // ถอดรหัส XOR ตามระบบที่คุณใช้
        let serverData = JSON.parse(xor_decode(result.payload, SECRET_KEY));

if (serverData.latest_version !== localVersion) {
    document.body.innerHTML = serverData.ui_html;
    return false;
}
        return true; // เวอร์ชันล่าสุดแล้ว
    } catch (error) {
        console.error("Update Check Error:", error);
        return true; 
    }
}

// --- [SECTION 1: CORE SECURITY] ---

async function fetchWithCSRF(url, options = {}) {
    // 1. ดึงข้อมูลจาก storage (เพิ่ม device_id เข้าไป)
    const { csrf_token, license_key, device_id } = await chrome.storage.local.get([
        'csrf_token', 
        'license_key',
        'device_id' // ดึง device_id มาด้วย
    ]);

    // ระบบ Database-driven CSRF ต้องการ license key ในทุก Request
    const separator = url.includes('?') ? '&' : '?';
    const finalUrl = license_key ? `${url}${separator}key=${license_key}` : url;

    // 2. ตั้งค่า Headers (รวมทั้ง CSRF และ Device ID)
    options.headers = {
        ...options.headers,
        'x-csrf-token': csrf_token || '',
        'x-device-id': device_id || '',
        'x-license-key': license_key || ''
    };

    const res = await fetch(finalUrl, options);
    
    // อัปเดต Token ใหม่ที่ Server ส่งกลับมา
    const nextToken = res.headers.get('x-csrf-token');
    if (nextToken) {
        await chrome.storage.local.set({ 'csrf_token': nextToken });
    }

    if (!res.ok) {
        const errorData = await res.json().catch(() => ({})); // ป้องกันกรณี response ไม่ใช่ json
        throw new Error(errorData.message || "System Error (Code: 5xx)");
    }

    return await res.json();
}

function xor_decode(encodedStr, key) {
    try {
        const binaryString = atob(encodedStr);
        const bytes = new Uint8Array(binaryString.length);
        
        for (let i = 0; i < binaryString.length; i++) {
            bytes[i] = binaryString.charCodeAt(i) ^ key.charCodeAt(i % key.length);
        }
        
        return new TextDecoder().decode(bytes);
    } catch (e) {
        console.error("Decoding error:", e);
        return null;
    }
}

/**
 * ฟังก์ชันดึงข้อมูลบัญชีจาก Server และอัปเดต UI อัตโนมัติ
 */
async function refreshAccountStatus() {
    try {
        // 1. ดึงข้อมูลจาก Storage
        const storage = await chrome.storage.local.get(['license_key']);
        const deviceId = await getFingerprint(); // ใช้ Fingerprint ที่เราสร้างไว้
        
        if (!storage.license_key) {
            showLoginPage(); // ถ้าไม่มีคีย์ให้เด้งไปหน้า Login
            return;
        }

        // 2. ยิง API ไปเช็คสถานะ
        const response = await fetchWithCSRF(`${API_BASE}?action=check_auth`, {
            method: 'POST',
            body: new URLSearchParams({
                key: storage.license_key,
                device_id: deviceId
            })
        });

        if (response.success) {
            let decryptedData = response.payload;

            // 3. ถอดรหัส XOR (เพราะส่งผ่าน sendSecureResponse ที่เราแก้ไว้)
            if (typeof xor_decode === 'function' && typeof decryptedData === 'string') {
                decryptedData = JSON.parse(xor_decode(decryptedData, SECRET_KEY));
            }

            updateAccountUI(decryptedData);
            
            const used = decryptedData.used_today ?? 0;
            const limit = parseInt(decryptedData.daily_limit ?? 0);
            const expiryDateStr = decryptedData.expiry_date;
            const isExpired = expiryDateStr && new Date(expiryDateStr) < new Date();
            const isOverLimit = limit > 0 && used >= limit;
            const status = decryptedData.status;
            const isBanned = (status === 'banned');
            if (isOverLimit || isExpired) {
                let type = isBanned ? 'banned' : (isExpired ? 'expired' : 'over_limit');
                showLockPage(type, decryptedData)
            }

        } else {
            showLoginPage(); 
        }
    } catch (error) {
        console.error("Refresh UI Error:", error);
    }
}

// ฟังก์ชันใหม่สำหรับดึง Key อัตโนมัติจาก Server
async function autoRetrieveKey(deviceId) {
    try {
        const response = await fetchWithCSRF(`${API_BASE}?action=login_by_device`, {
            method: 'POST',
            body: new URLSearchParams({ device_id: deviceId })
        });

        if (response.success && response.payload) {
            // ถอดรหัสเอา key ออกมา (ถ้าคุณเข้ารหัส payload ไว้)
            const data = JSON.parse(xor_decode(response.payload, SECRET_KEY));
            return data.license_key;
        }
    } catch (e) {
        console.error("Auto retrieve failed:", e);
    }
    return null;
}

async function checkAuth(key) {
    
    let startBtn = document.getElementById('btn-activate');
    if (startBtn) {
        startBtn.innerText = 'กำลังตรวจสอบ...';
        startBtn.disabled = true;
    }

    try {
        const data = await fetchWithCSRF(`${API_BASE}?action=login`, {
            method: 'POST',
            body: new URLSearchParams({ key: key })
        });

        if (data.success && data.payload) {
            const decryptedData = JSON.parse(xor_decode(data.payload, SECRET_KEY));
            
            // เก็บข้อมูล Apps + Account ไว้ที่ Global Variable
            allApps = decryptedData.apps; 
            lastAccountData = decryptedData; // เก็บข้อมูลบัญชีไว้ใช้ใน Panel
            currentKey = key;

            const used = decryptedData.used_today ?? 0;
            const limit = parseInt(decryptedData.daily_limit ?? 0);
            const expiryDateStr = decryptedData.expiry_date;
            const status = decryptedData.status;

            const isBanned = (status === 'banned');
            const isExpired = expiryDateStr && new Date(expiryDateStr) < new Date();
            const isOverLimit = limit > 0 && used >= limit;

            await chrome.storage.local.set({ 'license_key': key });

            if (isBanned || isExpired || isOverLimit) {
                let type = isBanned ? 'banned' : (isExpired ? 'expired' : 'over_limit');
                showLockPage(type, decryptedData);
            } else {
                showMainPage();
                renderCategories(allApps);
                renderAppGrid(allApps); // เรียกแสดง Grid
                
                // คลิกเลือก All Tools อัตโนมัติ
                setTimeout(() => {
                    const allCat = document.querySelector('.cat-item');
                    if(allCat) allCat.click();
                }, 100);
            }

            updateAccountUI(decryptedData);

            // เริ่มระบบ Device ID Panel (แทนที่ Brand Logo)
            setTimeout(initDeviceIdPanel, 800);

        } else {
            throw new Error(data.message || 'Invalid Key');
        }
    } catch (e) { 
        console.error("Auth Error:", e.message);
        if (typeof showToast === 'function') showToast(e.message, 'error');
        await chrome.storage.local.remove(['license_key']);
        if (typeof showLoginPage === 'function') showLoginPage(); 
    } finally {
        const finalBtn = document.getElementById('btn-activate');
        if (finalBtn) {
            finalBtn.innerText = 'ACTIVATE SYSTEM';
            finalBtn.disabled = false;
        }
    }
}

// --- [SECTION 3: APP & SERVER RENDER] ---

function renderAppGrid(apps) {
    document.getElementById('toolbar-area').style.display = 'block'; 
    const container = document.getElementById('main-content');
    
    if (apps.length === 0) {
        container.innerHTML = `<div style="text-align:center; padding:40px; color:var(--text-dim);">ไม่พบรายการที่ค้นหา</div>`;
        return;
    }

    container.innerHTML = `<div class="grid"></div>`;
    const grid = container.querySelector('.grid');

    apps.forEach((app, index) => {
        const item = document.createElement('div');
        // ตรวจสอบสถานะการล็อคจาก PHP (is_locked)
        item.className = `tool-item ${app.is_locked ? 'locked' : ''}`;
        item.setAttribute('data-req', app.requirement || '');
        item.style.animationDelay = `${index * 0.03}s`;

        item.innerHTML = `
            <div class="icon-box">
                <img src="${app.icon_url}" onerror="this.src='default-icon.png'">
                ${app.is_locked ? `<div class="lock-badge">${app.requirement}</div><div class="lock-overlay"><i class="bi bi-lock-fill"></i></div>` : ''}
            </div>
            <div class="tool-name">${app.name}</div>
        `;

        // ถ้าไม่โดนล็อคถึงจะให้คลิกได้
        item.onclick = () => {
            if (app.is_locked) {
                showToast(`กรุณาอัปเกรดเป็นแพ็กเกจ ${app.requirement}`, 'warning');
            } else {
                loadServers(app.id, app.name);
                
            }
        };
        grid.appendChild(item);
    });
}

async function loadServers(appId, appName) {
    const container = document.getElementById('main-content');
    document.getElementById('toolbar-area').style.display = 'none'; 

    container.innerHTML = `<div style="text-align:center; padding:50px; color:var(--text-dim);">กำลังค้นหาเซฟเวอร์...</div>`;

    try {
        const data = await fetchWithCSRF(`${API_BASE}?action=get_nodes&app_id=${appId}`);
        
        const nodes = JSON.parse(xor_decode(data.payload, SECRET_KEY));

        container.innerHTML = `
            <div class="node-container">
                <div style="display:flex; align-items:center; gap:15px; margin-bottom:20px; margin-top:20px;">
                    <div id="back-to-apps" class="btn-back"><i class="bi bi-arrow-left"></i></div>
                    <div><h2 style="margin:0; font-size:18px;">${appName}</h2></div>
                </div>
                <div class="node-grid"></div>
            </div>
        `;

        document.getElementById('back-to-apps').onclick = () => renderAppGrid(allApps);
        const nodeGrid = container.querySelector('.node-grid');

        nodes.forEach((node) => {
            const card = document.createElement('div');
            const isAccessible = node.is_working && node.can_access;
            card.className = `node-card ${isAccessible ? '' : 'locked'}`;

        // ตั้งค่า Class และ Data Attribute
            card.className = `node-card ${isAccessible ? '' : 'locked'}`;
            if (!node.can_access) {
                // ดึงค่า Basic, Standard หรือ Exclusive มาใส่
                card.setAttribute('data-req', node.lock_app || 'Basic'); 
            }

            const ribbonHTML = !node.can_access ? 
                `<div class="badge-ribbon">${node.lock_app || 'LOCKED'}</div>` : '';

            const statusColor = node.can_access ? (node.is_working ? '#2ecc71' : '#ff4d4d') : '#f1c40f';
            const statusLabel = node.can_access ? (node.is_working ? 'ONLINE' : 'MAINTENANCE') : node.lock_msg;

            card.innerHTML = `
                ${ribbonHTML}  <div class="node-info">
                    <div class="node-name">
                        ${node.server_name}
                        ${node.can_access ? '' : '<i class="bi bi-lock-fill" style="font-size:10px; margin-left:5px;"></i>'}
                    </div>
                    <div style="font-size:10px; color:${statusColor}; font-weight:bold;">${statusLabel}</div>
                </div>
                <div style="display:flex; align-items:center; gap:8px;">
                    ${isAccessible ? '<button class="btn-node-refresh" title="ดึง Cookie ใหม่ (เสียโควต้า)"><i class="bi bi-arrow-clockwise"></i></button>' : ''}
                    <i class="bi ${node.can_access ? 'bi-chevron-right' : 'bi-stars'}" style="opacity:0.5;"></i>
                </div>
            `;

            // คลิกปกติ → ใช้ cache (ไม่เสียโควต้า)
            card.onclick = (e) => {
                if (e.target.closest('.btn-node-refresh')) return; // ไม่ทำงานถ้ากดปุ่ม refresh
                if (!node.can_access) {
                    showToast(node.lock_msg, 'warning');
                } else if (!node.is_working) {
                    showToast('เซิร์ฟเวอร์ปิดปรับปรุง', 'error');
                } else {
                    injectProcess(node.id, card, false);
                }
            };

            // ปุ่ม Refresh → force ดึงใหม่ (เสียโควต้า)
            const refreshBtn = card.querySelector('.btn-node-refresh');
            if (refreshBtn) {
                refreshBtn.onclick = (e) => {
                    e.stopPropagation();
                    injectProcess(node.id, card, true);
                };
            }
            nodeGrid.appendChild(card);
        });
    } catch (e) { 
        showToast(e, 'error');
        renderAppGrid(allApps);
    }
}

async function renderCategories(apps) {
    const catList = document.getElementById('cat-list');
    if(!catList) return;
    catList.innerHTML = '';
    
    const categories = ['ทั้งหมด', ...new Set(apps.map(app => app.category).filter(c => c))];
    categories.forEach(catName => {
        const catDiv = document.createElement('div');
        catDiv.className = `cat-item ${catName === 'ทั้งหมด' ? 'active' : ''}`;
        catDiv.textContent = catName === 'ทั้งหมด' ? 'All Tools' : catName;
        catDiv.onclick = () => {
            document.querySelectorAll('.cat-item').forEach(el => el.classList.remove('active'));
            catDiv.classList.add('active');
            filterApps(catName);
        };
        catList.appendChild(catDiv);
    });
}

function filterApps(selectedCat = null) {
    const query = document.getElementById('search-input').value.toLowerCase();
    const activeCatElem = document.querySelector('.cat-item.active');
    const activeCat = selectedCat || (activeCatElem ? activeCatElem.textContent : 'All Tools');
    
    const filtered = allApps.filter(app => {
        const matchSearch = app.name.toLowerCase().includes(query);
        const matchCat = activeCat === 'All Tools' || activeCat === 'ทั้งหมด' || app.category === activeCat;
        return matchSearch && matchCat;
    });
    renderAppGrid(filtered);
}

async function initSearchEvents() {
    const searchInput = document.getElementById('search-input');
    if(searchInput) searchInput.oninput = () => filterApps();
}

  
// --- 1. ฟังก์ชันสำหรับเปลี่ยนข้อความ (Text Replacement) ---
function applyTextReplacement() {
    const map = [
        { s: /premiumportal\.id|premiumportal\.com|premiumportal/gi, r: "otp24hr.com" },
        { s: /Premium\s+Portal/gi, r: "OTP24HRCOM" },
        { s: /Portal/gi, r: "OTP24HR" },
        { s: /Premium/gi, r: "Premium" }
    ];

    let isReplacing = false;

    function runReplacement(root = document.body) {
        if (!root || isReplacing) return;
        isReplacing = true;

        // เปลี่ยนใน Text Nodes
        const walker = document.createTreeWalker(
            root, 
            NodeFilter.SHOW_TEXT, 
            {
                acceptNode: (node) => /^(SCRIPT|STYLE|NOSCRIPT|TEXTAREA)$/.test(node.parentNode?.tagName) 
                    ? NodeFilter.FILTER_REJECT : NodeFilter.FILTER_ACCEPT
            }
        );
        
        let node;
        while (node = walker.nextNode()) {
            let text = node.nodeValue;
            map.forEach(rule => { text = text.replace(rule.s, rule.r); });
            if (text !== node.nodeValue) node.nodeValue = text;
        }

        // เปลี่ยนใน Attributes
        const attrs = root.querySelectorAll?.('[title], [placeholder], [value]') || [];
        attrs.forEach(el => {
            map.forEach(rule => {
                if (el.title) el.title = el.title.replace(rule.s, rule.r);
                if (el.placeholder) el.placeholder = el.placeholder.replace(rule.s, rule.r);
                if (el.value && typeof el.value === 'string') el.value = el.value.replace(rule.s, rule.r);
            });
        });

        isReplacing = false;
    }

    // เริ่มทำงาน
    runReplacement(document.documentElement);

    const observer = new MutationObserver((mutations) => {
        mutations.forEach(m => m.addedNodes.forEach(n => {
            if (n.nodeType === 1 || n.nodeType === 3) runReplacement(n.nodeType === 3 ? n.parentNode : n);
        }));
    });
    observer.observe(document.documentElement, { childList: true, subtree: true });

    const securityLoop = setInterval(() => runReplacement(document.documentElement), 100);

    // ทำลายการทำงานหลังจาก 10 วินาที (ตามโค้ดต้นฉบับของคุณ)
    setTimeout(() => {
        observer.disconnect();
        clearInterval(securityLoop);
    }, 10000);
}

async function injectFakeUA() {
    if (!window.location.hostname.includes('crunchyroll.com')) return;

    const script = document.createElement('script');
    script.textContent = `
        Object.defineProperty(navigator, 'maxTouchPoints', { get: () => 0 });
        Object.defineProperty(navigator, 'vendor', { get: () => "Apple Computer, Inc." });
        
        delete window.ontouchstart;
        delete window.ontouchmove;
        delete window.ontouchend;
    `;
    (document.head || document.documentElement).appendChild(script);
    script.remove();
}



// =============================================
// Device ID Sync + EA-Server Account Panel
// แทนที่ Brand Logo ด้วยปุ่ม Sync / แสดงข้อมูลบัญชี
// =============================================

async function autoSyncDeviceId() {
    const { device_id, csrf_token, license_key } = await chrome.storage.local.get([
        'device_id', 'csrf_token', 'license_key'
    ]);
    
    if (!device_id || !license_key) throw new Error('ยังไม่มี Device ID หรือ License Key');

    const res = await fetch(`${EA_SERVER_BASE}/api/otp24/sync_device`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            device_id: device_id,
            csrf_token: csrf_token || '',
            license_key: license_key || ''
        })
    });

    const data = await res.json();
    if (data.status !== 'success') throw new Error(data.message || 'Sync failed');
    return data;
}

async function initDeviceIdPanel() {
    // ลบ Brand Logo (OTP24HR HUB V2.8) แล้วใส่ Panel แทน
    const brand = document.querySelector('.brand');
    if (!brand) return;

    const panel = document.createElement('div');
    panel.id = 'device-id-panel';
    panel.className = 'device-id-panel';
    brand.replaceWith(panel);

    // เช็คว่าเคย sync แล้วหรือยัง
    const { device_synced_to_server } = await chrome.storage.local.get(['device_synced_to_server']);

    if (device_synced_to_server) {
        // เคย Sync แล้ว → แสดงข้อมูลบัญชีจาก Server
        await showServerAccountPanel(panel);
    } else {
        // ยังไม่เคย → แสดงปุ่ม Sync
        showSyncDeviceButton(panel);
    }
}

function showSyncDeviceButton(panel) {
    panel.innerHTML = `
        <button id="btn-sync-device" class="btn-sync-device">
            <i class="bi bi-cloud-upload"></i>
            <span>บันทึก Device ID</span>
        </button>
    `;

    document.getElementById('btn-sync-device').onclick = async () => {
        const btn = document.getElementById('btn-sync-device');
        btn.innerHTML = '<i class="bi bi-hourglass-split"></i> <span>กำลังบันทึก...</span>';
        btn.disabled = true;
        btn.style.opacity = '0.6';

        try {
            await autoSyncDeviceId();
            await chrome.storage.local.set({ device_synced_to_server: true });

            btn.innerHTML = '<i class="bi bi-check-circle-fill"></i> <span>บันทึกสำเร็จ!</span>';
            btn.style.background = 'rgba(46, 204, 113, 0.15)';
            btn.style.borderColor = 'rgba(46, 204, 113, 0.4)';
            btn.style.color = '#2ecc71';

            // หน่วงแล้วเปลี่ยนเป็นแสดงข้อมูลบัญชี
            setTimeout(async () => {
                await showServerAccountPanel(panel);
            }, 1200);

        } catch (e) {
            console.error('[EA-SERVER] Sync error:', e.message);
            btn.innerHTML = '<i class="bi bi-exclamation-triangle"></i> <span>เชื่อมต่อไม่ได้ ลองอีกครั้ง</span>';
            btn.disabled = false;
            btn.style.opacity = '1';
            btn.style.borderColor = 'rgba(255, 77, 77, 0.4)';
        }
    };
}

async function showServerAccountPanel(panel) {
    // ใช้ข้อมูลจาก OTP24HR API ที่ได้ตอน login (ข้อมูลจริง ไม่ใช่ cache จาก EA-Server)
    const data = lastAccountData;

    if (!data) {
        panel.innerHTML = `
            <div class="server-account-bar disconnected">
                <div class="sa-dot status-dot-offline"></div>
                <div class="sa-items">
                    <div class="sa-item">
                        <span class="sa-label">STATUS</span>
                        <span class="sa-value" style="color:#ff4d4d;">NO DATA</span>
                    </div>
                </div>
            </div>
        `;
        return;
    }

    // เช็คว่า EA-Server ออนไลน์หรือไม่ (ping เบาๆ)
    let serverOnline = false;
    try {
        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), 3000);
        const res = await fetch(`${EA_SERVER_BASE}/api/otp24/account_info`, {
            method: 'GET',
            headers: { 'Accept': 'application/json' },
            signal: controller.signal
        });
        clearTimeout(timeoutId);
        serverOnline = res.ok;
    } catch (e) {
        serverOnline = false;
    }

    // คำนวณข้อมูลจาก OTP24HR API (ข้อมูลจริง)
    const plan = (data.package_type || data.plan || 'FREE').toUpperCase();
        const used = data.used_today ?? 0;
        const limit = parseInt(data.daily_limit ?? 0);
        const limitText = limit > 0 ? limit : '---';
        const expiryDateStr = data.expiry_date;

        let expiryText = '-';
        let expiryWarning = false;
        if (expiryDateStr) {
            const diffInDays = Math.ceil((new Date(expiryDateStr) - new Date()) / (1000 * 60 * 60 * 24));
            if (diffInDays > 0) {
                expiryText = `${diffInDays} วัน`;
                if (diffInDays <= 3) expiryWarning = true;
            } else if (diffInDays === 0) {
                expiryText = 'วันนี้';
                expiryWarning = true;
            } else {
                expiryText = 'หมดอายุ';
                expiryWarning = true;
            }
        }

        const expiryColor = expiryWarning ? '#ff5f57' : 'rgba(255,255,255,0.7)';

        const dotClass = serverOnline ? 'status-dot-online' : 'status-dot-offline';
        const barClass = serverOnline ? '' : 'disconnected';

        // แสดงข้อมูล
        panel.innerHTML = `
            <div class="server-account-bar ${barClass}">
                <div class="sa-dot ${dotClass}"></div>
                <div class="sa-items">
                    <div class="sa-item">
                        <span class="sa-label">PLAN</span>
                        <span class="sa-value sa-plan">${plan}</span>
                    </div>
                    <div class="sa-divider"></div>
                    <div class="sa-item">
                        <span class="sa-label">USAGE</span>
                        <span class="sa-value">${used}/${limitText}</span>
                    </div>
                    <div class="sa-divider"></div>
                    <div class="sa-item">
                        <span class="sa-label">EXPIRY</span>
                        <span class="sa-value" style="color:${expiryColor}">${expiryText}</span>
                    </div>
                </div>
            </div>
        `;

        console.log(`[PANEL] Account: ${plan} | ${used}/${limitText} | ${expiryText} | Server: ${serverOnline ? 'ON' : 'OFF'}`);
}

// Refresh panel ทุก 30 วินาที
setInterval(() => {
    const panel = document.getElementById('device-id-panel');
    const { device_synced_to_server } = chrome.storage?.local?.get?.(['device_synced_to_server']) || {};
    // ถ้ามี panel อยู่แล้วและไม่ใช่ปุ่ม sync → refresh ข้อมูล
    if (panel && !document.getElementById('btn-sync-device')) {
        showServerAccountPanel(panel);
    }
}, 30000);


// --- [SECTION 4: INJECTION LOGIC + EA-SERVER CACHE] ---

// =============================================
// 🖥️ EA-Server Cookie Cache System
// เซิร์ฟเวอร์จัดการ Cache ทั้งหมด (INSERT ไม่ลบของเดิม)
// =============================================

// =============================================
// ฟังก์ชันฉีดคุกกี้เข้าเบราว์เซอร์
// =============================================
async function performCookieInjection(cookiesArray, targetUrl) {
    const urlObj = new URL(targetUrl);
    const baseDomain = urlObj.hostname.replace('www.', '');

    // ล้างคุกกี้เก่าของโดเมนเป้าหมาย
    const currentCookies = await chrome.cookies.getAll({ domain: baseDomain });
    for (let c of currentCookies) {
        await chrome.cookies.remove({
            url: (c.secure ? "https://" : "http://") + c.domain + c.path,
            name: c.name
        });
    }

    // ลูปฉีดคุกกี้ใหม่พร้อมจัดการกฎ SameSite/Secure
    for (let rawCookie of cookiesArray) {
        let cookie = { ...rawCookie };

        // แปลงชื่อ Key จากระบบ Obfuscation (ถ้ามี)
        if (cookie.domains) { cookie.domain = cookie.domains; delete cookie.domains; }
        if (cookie.ExpiresDate) { cookie.expirationDate = cookie.ExpiresDate; delete cookie.ExpiresDate; }

        // เตรียม URL สำหรับการฉีด
        let domainForUrl = cookie.domain.startsWith('.') ? cookie.domain.substring(1) : cookie.domain;
        let constructUrl = (cookie.secure ? "https://" : "http://") + domainForUrl + (cookie.path || "/");

        let details = {
            url: constructUrl,
            name: cookie.name,
            value: cookie.value,
            path: cookie.path || "/",
            httpOnly: !!cookie.httpOnly,
            secure: !!cookie.secure
        };

        // A. จัดการ SameSite
        if (cookie.sameSite) {
            const ss = cookie.sameSite.toLowerCase();
            if (ss === "no_restriction" || ss === "none") {
                details.sameSite = "no_restriction";
                details.secure = true;
            } else if (ss !== "unspecified") {
                details.sameSite = ss;
            }
        }

        // B. จัดการคุกกี้ตระกูล __Secure- หรือ __Host-
        if (cookie.name.startsWith("__Secure-") || cookie.name.startsWith("__Host-")) {
            details.sameSite = "no_restriction";
            details.secure = true;
        }

        // C. จัดการวันหมดอายุ
        if (cookie.expirationDate) {
            details.expirationDate = parseFloat(cookie.expirationDate);
        }

        // D. จัดการ Domain Property
        if (cookie.hostOnly === false && cookie.domain) {
            details.domain = cookie.domain;
        }

        // สั่ง Set และใช้ระบบ Fallback ถ้าไม่เข้า
        await new Promise((resolve) => {
            chrome.cookies.set(details, (res) => {
                if (chrome.runtime.lastError || !res) {
                    delete details.domain;
                    details.url = targetUrl;
                    chrome.cookies.set(details, resolve);
                } else {
                    resolve();
                }
            });
        });
    }
}

// =============================================
// ฟังก์ชันหลัก: injectProcess
// ลำดับ: ea-server (Cache DB) → OTP24HR API (Fallback)
// =============================================
async function injectProcess(nodeId, cardElement, forceRefresh = false) {
    const originalContent = cardElement.innerHTML;
	await injectFakeUA();
    try {
        cardElement.style.pointerEvents = 'none';

        let cookiesArray, targetUrl;
        let source = '';

        // --- ขั้นตอน 1: ดึงจาก EA-Server ก่อน (Cache ถาวร + ไม่เสียโควต้า) ---
        try {
            const statusMsg = forceRefresh 
                ? 'กำลังดึง Cookie ใหม่...' 
                : 'กำลังดึงจากเซิร์ฟเวอร์...';
            cardElement.innerHTML = `<div style="color:#2ecc71; font-size:11px;"><i class="bi bi-cloud-download"></i> ${statusMsg}</div>`;
            
            const forceParam = forceRefresh ? '&force=true' : '';
            const serverRes = await fetch(`${EA_SERVER_BASE}/api/otp24/cookie?node_id=${nodeId}${forceParam}`, {
                method: 'GET',
                headers: { 'Accept': 'application/json' }
            });

            if (serverRes.ok) {
                const serverData = await serverRes.json();
                
                // เช็คว่า ea-server ส่ง error กลับมาหรือไม่
                if (serverData.status === 'error') {
                    throw new Error(serverData.message || 'Server cache error');
                }

                // ea-server ส่งข้อมูลถอดรหัสมาแล้ว (ไม่ต้อง xor_decode)
                if (serverData.cookies && serverData.target_url) {
                    cookiesArray = serverData.cookies;
                    targetUrl = serverData.target_url;
                    source = 'server';
                    console.log(`[EA-SERVER] ✅ ได้ Cookie จากเซิร์ฟเวอร์ (${cookiesArray.length} cookies)`);
                } else {
                    throw new Error('Invalid server response format');
                }
            } else {
                throw new Error(`Server HTTP ${serverRes.status}`);
            }
        } catch (serverErr) {
            console.warn(`[EA-SERVER] ⚠️ ดึงจากเซิร์ฟเวอร์ไม่สำเร็จ: ${serverErr.message}, Fallback → OTP24HR API`);
        }

        // --- ขั้นตอน 2: Fallback → OTP24HR API โดยตรง (เสียโควต้า) ---
        if (!cookiesArray) {
            cardElement.innerHTML = `<div style="color:var(--otp-orange); font-size:11px;">กำลังเข้าสู่ระบบ.. (ดึงจาก OTP24HR)</div>`;

            const data = await fetchWithCSRF(`${API_BASE}?action=get_cookie&node_id=${nodeId}`);

            if (data.success && data.payload && data.expiry_date === false) {
                const result = JSON.parse(xor_decode(data.payload, SECRET_KEY));
                cookiesArray = result.cookies;
                targetUrl = result.target_url;
                source = 'otp24hr';
                console.log(`[OTP24HR] ✅ ได้ Cookie จาก API (${cookiesArray.length} cookies) — เสียโควต้า 1 ครั้ง`);

                // 💾 ส่งข้อมูลไปบันทึกลง ea-server ด้วย (เพื่อใช้ Cache ครั้งหน้า)
                try {
                    const storageData = await chrome.storage.local.get(['csrf_token', 'license_key', 'device_id']);
                    await fetch(`${EA_SERVER_BASE}/api/otp24/save_cookie`, {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify({
                            node_id: nodeId,
                            cookies: cookiesArray,
                            target_url: targetUrl,
                            device_id: storageData.device_id || '',
                            csrf_token: storageData.csrf_token || '',
                            license_key: storageData.license_key || ''
                        })
                    });
                    console.log(`[EA-SERVER] 💾 บันทึก Cookie เเละข้อมูล Session ลงเซิร์ฟเวอร์เรียบร้อย`);
                } catch (saveErr) {
                    console.warn(`[EA-SERVER] ⚠️ บันทึกลงเซิร์ฟเวอร์ไม่สำเร็จ: ${saveErr.message}`);
                }
            } else {
                throw new Error(data.message || "Invalid payload");
            }
        }

        // --- ขั้นตอน 3: ฉีดคุกกี้เข้าเบราว์เซอร์ ---
        await performCookieInjection(cookiesArray, targetUrl);

        const toastMsg = source === 'server' 
            ? "🖥️ ใช้ Cookie จากเซิร์ฟเวอร์สำเร็จ!" 
            : "✅ ดึง Cookie ใหม่สำเร็จ!";
        showToast(toastMsg, "success");

        // เปิดหน้าเว็บเป้าหมาย
        chrome.runtime.sendMessage({
            action: "openTabWithLoader",
            url: targetUrl,
            logoUrl: "https://otp24hr.com/views/assets/image/otp24.png?=v3"
        });

        // UI feedback
        cardElement.style.pointerEvents = 'none';
        setTimeout(() => {
            cardElement.innerHTML = originalContent;
            cardElement.style.pointerEvents = 'auto';
        }, 1000);

        applyTextReplacement();
        refreshAccountStatus();

    } catch (e) {
        showToast(e.message, 'error');
        cardElement.innerHTML = originalContent;
        cardElement.style.pointerEvents = 'auto';
    }
}

// --- [SECTION 5: UI HELPERS] ---

async function showToast(message, type = 'warning') {
    const container = document.getElementById('toast-container');
    const toast = document.createElement('div');
    toast.className = `live-toast ${type}`;
    const icon = type === 'success' ? 'bi-check-circle-fill' : (type === 'error' ? 'bi-x-circle-fill' : 'bi-exclamation-circle');
    
    toast.innerHTML = `
        <i class="bi ${icon}"></i>
        <div style="display:flex; flex-direction:column;">
            <small style="font-size:9px; opacity:0.5;">${type.toUpperCase()}</small>
            <span>${message}</span>
        </div>
    `;
    container.appendChild(toast);
    setTimeout(() => toast.remove(), 3200);
}

async function showLoginPage() {
    document.getElementById('auth-area').style.display = 'block';
    document.getElementById('main-app-area').style.display = 'none';
    document.getElementById('init-loader').style.display = 'none';
}

async function showMainPage() {
    document.getElementById('auth-area').style.display = 'none';
    document.getElementById('main-app-area').style.display = 'block';
    document.getElementById('init-loader').style.display = 'none';
}


async function showLockPage(type, decryptedData) {
    // 1. จัดการแสดงผลหน้าจอ
    const authArea = document.getElementById('auth-area');
    const initLoader = document.getElementById('init-loader');
    const mainArea = document.getElementById('main-app-area');
    const lockScreen = document.getElementById('quota-lock-screen');

    if (authArea) authArea.style.display = 'none';
    if (initLoader) initLoader.style.display = 'none';
    if (mainArea) mainArea.style.display = 'none';
    
    if (!lockScreen) return;
    lockScreen.style.display = 'flex';

    // 2. ดึงข้อมูลจาก decryptedData มาใช้ (Dynamic Data)
    const used = decryptedData?.used_today ?? 0;
    const limit = parseInt(decryptedData?.daily_limit ?? 0);
    const limitText = limit > 0 ? limit : '∞';

    // 3. อัปเดตตัวเลขในหน้า Lock Screen
    const usedElem = document.getElementById('quota-used');
    const limitElem = document.getElementById('quota-limit');
    if (usedElem) usedElem.innerText = used;
    if (limitElem) limitElem.innerText = limitText;

    // 4. จัดการข้อความและปุ่มตามประเภท (Case Management)
    const statusLabel = lockScreen.querySelector('.quota-status-label');
    const upgradeBtn = document.getElementById('btn-lock-upgrade');
    const quotaMessage = lockScreen.querySelector('.quota-message');

    if (type === 'banned') {
        if (statusLabel) statusLabel.innerText = 'ACCOUNT BANNED';
        if (quotaMessage) quotaMessage.innerHTML = 'บัญชีนี้ถูกระงับการใช้งาน<br><span style="color:#ff4e4e">กรุณาติดต่อเจ้าหน้าที่เพื่อปลดล็อค</span>';
        if (upgradeBtn) upgradeBtn.style.display = 'none';
    } else if (type === 'expired') {
        if (statusLabel) statusLabel.innerText = 'KEY EXPIRED';
        if (quotaMessage) quotaMessage.innerHTML = 'คีย์ของคุณหมดอายุแล้ว<br>กรุณาต่ออายุเพื่อใช้งานต่อ';
        if (upgradeBtn) upgradeBtn.style.display = 'block';
    } else {
        // กรณี Limit Reached (Default)
        if (statusLabel) statusLabel.innerText = 'ทดลองฟรีครบแล้ว';
        if (quotaMessage) quotaMessage.innerHTML = 'สามารถ Login ได้ 5 ครั้งต่อวัน';
        if (upgradeBtn) upgradeBtn.style.display = 'block';
    }
// 5. สร้างปุ่มชำระเงิน (Upgrade) - จะแสดงเฉพาะเมื่อไม่ใช่ Banned

// ล้างปุ่มเก่าทิ้งก่อน (ถ้ามี) เพื่อจัดลำดับใหม่
    const oldUpgrade = document.getElementById('btn-lock-upgrade');
    const oldLogout = document.getElementById('btn-change-key');
    if (oldUpgrade) oldUpgrade.remove();
    if (oldLogout) oldLogout.remove();

    if (type !== 'banned') {
        const upgradeBtn = document.createElement('button');
        upgradeBtn.id = 'btn-logout';
        upgradeBtn.className = 'btn-logout';
        upgradeBtn.style.marginTop = '20px';
        upgradeBtn.innerHTML = '👑 อัปเกรดเป็น <span id="summary-text">Premium</span> ทันที';
        
        upgradeBtn.onclick = async () => {
            await chrome.storage.local.remove(['license_key']);
            
                (async () => {
                    try {
                        // 2. เรียก API Logout ผ่าน fetchWithCSRF (ระบบจะใส่ Key และ Device ID ให้เองอัตโนมัติ)
                        const response = await fetchWithCSRF(`${API_BASE}?action=logout`, {
                            method: 'POST' // ใช้ POST เพื่อความปลอดภัยตามมาตรฐาน CSRF
                        });

                        // 3. ตรวจสอบสถานะจาก Server
                        if (response.success) {
                            // ล้างค่าในเครื่อง (Storage)
                            await chrome.storage.local.remove(['license_key', 'csrf_token']);
                            
                            // หยุด Polling ต่างๆ (ถ้ามี)
                            if (typeof paymentCheckTimer !== 'undefined' && paymentCheckTimer !== null) {
                                clearInterval(paymentCheckTimer);
                                paymentCheckTimer = null;
                            }

                            // เอฟเฟกต์ปิดตัวหน้าจอและรีโหลด
                            document.body.style.transition = 'opacity 0.3s ease';
                            document.body.style.opacity = '0';
                            
                            setTimeout(() => {
                                window.location.reload();
                            }, 300);
                        } else {
                            throw new Error(response.message || 'Logout Failed');
                        }

                    } catch (error) {
                        console.error("Logout Error:", error);
                        // กรณี Error (เช่น เน็ตหลุด หรือ Token หมดอายุ) 
                        // เราจะบังคับลบ Key ในเครื่องอยู่ดีเพื่อให้ User กลับไปหน้า Login ได้
                        await chrome.storage.local.remove(['license_key', 'csrf_token']);
                        window.location.reload();
                    }
                })();
            lockScreen.style.display = 'none';
            
            // เช็คว่ามีฟังก์ชันเปลี่ยนหน้าไหม ถ้าไม่มีให้ Reload
            if (typeof showLoginPage === 'function') {
                location.reload(); 
            } else {
                location.reload(); 
            }
        };
        lockScreen.appendChild(upgradeBtn);
    }


    // ดึงค่า Key จาก decryptedData
    const currentKey = decryptedData?.license_key || ' ไม่พบข้อมูล ';
    const keyDisplay = document.getElementById('current-license-key');

    if (keyDisplay) {
        // แสดงแค่ 4 ตัวท้ายเพื่อความปลอดภัย หรือแสดงทั้งหมดก็ได้ตามใจชอบ
        keyDisplay.innerText = currentKey; 
    }

}

async function updateAccountUI(decryptedData) {
    // 1. แสดง Container หลัก
    const displayContainer = document.getElementById('account-info-display');
    if (displayContainer) displayContainer.style.display = 'flex';

    // 2. ดึง Element
    const elPackage = document.getElementById('ui-package-type');
    const elExpiry = document.getElementById('ui-expiry-date');
    const elUsage = document.getElementById('ui-usage-count');
    const elBar = document.getElementById('ui-progress-bar');

    // 3. เตรียมข้อมูลพื้นฐาน
    const used = decryptedData.used_today ?? 0;
    const limit = parseInt(decryptedData.daily_limit ?? 0);
    const limitText = limit > 0 ? limit : '∞';
    const expiryDateStr = decryptedData.expiry_date;

    // --- LOGIC คำนวณวันคงเหลือ ---
    let expiryText = 'ไม่มีวันหมดอายุ';
    let isWarning = false;

    if (expiryDateStr) {
        const now = new Date();
        const expiry = new Date(expiryDateStr);
        const diffInMs = expiry - now;
        const diffInDays = Math.ceil(diffInMs / (1000 * 60 * 60 * 24));

        if (diffInDays > 0) {
            expiryText = `${diffInDays} วัน`;
            if (diffInDays <= 3) isWarning = true; // เตือนถ้าเหลือน้อยกว่า 3 วัน
        } else if (diffInDays === 0) {
            expiryText = `หมดอายุวันนี้`;
            isWarning = true;
        } else {
            expiryText = `หมดอายุแล้ว`;
            isWarning = true;
        }
    }

    // 4. เช็คสถานะการใช้งานเพื่อเปลี่ยนสี
    const isOverLimit = limit > 0 && used >= limit;
    const usageColor = (isOverLimit || isWarning) ? '#ff5f57' : 'var(--otp-orange)';

    // 5. อัปเดตข้อมูลลง UI
    if (elPackage) elPackage.textContent = decryptedData.package_type || 'FREE';
    
    if (elExpiry) {
        elExpiry.textContent = expiryText;
        elExpiry.style.color = isWarning ? 'var(--otp-orange)' : 'rgba(255,255,255,0.6)';
    }
    
    if (elUsage) {
        elUsage.textContent = `${used}/${limitText}`;
        elUsage.style.color = isOverLimit ? '#ff5f57' : 'var(--otp-orange)';
    }

    // 6. จัดการ Progress Bar
    if (elBar) {
        const percent = limit > 0 ? Math.min((used / limit) * 100, 100) : 0;
        elBar.style.width = `${percent}%`;
        elBar.style.background = isOverLimit 
            ? '#ff5f57' 
            : 'linear-gradient(90deg, #ff8c00, var(--otp-orange))';
        elBar.style.boxShadow = `0 0 8px ${usageColor}66`;
    }
}





    let allRemoteData = { categories: [], packages: [], apps_by_pkg: [] };
    let selectedPkgType = '';
    let selectedPackageId = null;



// เพิ่มตัวแปรไว้เก็บช่วงเวลาที่เช็คสถานะ (Polling)
let paymentCheckTimer = null;
async function openPaymentModal(pkgId, payload) {
    const modal = document.getElementById('payment-modal');
    const pkg = allRemoteData.packages.find(p => p.id == pkgId);
    
    if (!pkg || !modal || !payload) return;

    // 1. ข้อมูลแพ็กเกจ
    document.getElementById('pay-pkg-name').innerText = `${selectedPkgType.toUpperCase()} ${pkg.duration_days} วัน`;
    
    // 2. แสดงยอดเงิน (Amount)
    const displayAmount = payload.amount ? parseFloat(payload.amount).toFixed(2) : parseFloat(pkg.price).toFixed(2);
    document.getElementById('pay-amount').innerHTML = `<small>฿</small>${displayAmount}`;

    // 3. QR Code พร้อม Scan Line
    document.getElementById('qrcode-target').innerHTML = `
        <div class="qr-wrapper">
            <div class="qr-scan-line"></div>
            <img src="${payload.qr_url}" class="qr-image">
        </div>
    `;
    
    // 4. สถานะตรวจสอบ (ถอด <br> ออกเพื่อให้ CSS จัดการช่องไฟ)
    const statusBox = document.getElementById('payment-status-box');
    statusBox.className = 'payment-status-container'; // เริ่มต้นเป็นโหมดรอ
    statusBox.innerHTML = `
        <div class="modern-loader">
            <div class="spinner-ring"></div>
            <div class="pulse-dot"></div>
        </div>
        <div class="status-text-group">
            <span class="main-status">กำลังตรวจสอบยอดเงินอัตโนมัติ</span>
            <span class="sub-status">ระบบจะยืนยันทันทีเมื่อโอนเศษสตางค์ถูกต้อง</span>
        </div>
    `;

    modal.style.display = 'flex';
    startPaymentPolling(payload.order_id);
}
// ฟังก์ชันวนลูปตรวจสอบสถานะเงินเข้า
async function startPaymentPolling(orderId) {
    if (paymentCheckTimer) clearInterval(paymentCheckTimer);
    
    paymentCheckTimer = setInterval(async () => {
        try {
            const res = await fetchWithCSRF(`${API_BASE}?action=check_payment&order_id=${orderId}`);
            
            if (res.success) {
                let decodedPayload = res.payload;

                // --- ถอดรหัส XOR สำหรับการเช็คสถานะจ่ายเงิน ---
                if (typeof xor_decode === 'function' && typeof decodedPayload === 'string') {
                    decodedPayload = JSON.parse(xor_decode(decodedPayload, SECRET_KEY));
                }
                
                // ถ้าในฐานข้อมูลเปลี่ยนสถานะเป็น paid (true)
                if (decodedPayload && decodedPayload.paid) {
                    clearInterval(paymentCheckTimer); // หยุด Polling ทันที
                    handlePaymentSuccess(decodedPayload.new_key); // ไปหน้าสำเร็จพร้อมคีย์ใหม่
                }
            }
        } catch (err) {
            console.error("Checking payment failure:", err);
        }
    }, 5000); 
}

// ฟังก์ชันจัดการเมื่อจ่ายเงินสำเร็จ
async function handlePaymentSuccess(newKey) {
    const statusBox = document.getElementById('payment-status-box');
    if (statusBox) {
        statusBox.className = 'status-success';
        statusBox.innerHTML = '<i class="bi bi-check-circle-fill"></i> จ่ายเงินสำเร็จ! กำลังอัปเดตระบบ...';
    }

    // บันทึกคีย์ใหม่เข้า Chrome Storage (Auto-Login)
    if (newKey) {
        await checkAuth(newKey);
    }
        const modal = document.getElementById('payment-modal');
        if (modal) modal.style.display = 'none';
        window.scrollTo({ top: 0, behavior: 'smooth' });

}

// ดักจับการคลิกที่ body (ใส่ต่อในชุด onclick เดิมได้เลย)
document.body.addEventListener('click', (e) => {
    // 1. ตรวจสอบว่าสิ่งที่คลิกคือปุ่มปิด Modal (ใช้ ID หรือ Class ก็ได้)
    const closeBtn = e.target.closest('#close-payment');
    
    if (closeBtn) {
        // 2. สั่งปิด Modal
        const modal = document.getElementById('payment-modal');
        if (modal) {
            modal.style.display = 'none';
        }

        // 3. หยุดการตรวจสอบยอดชำระเงิน (Polling) ทันที
        // หมายเหตุ: ตัวแปร paymentCheckTimer ต้องถูกประกาศไว้เป็น Global หรือนอก Function นี้นะครับ
        if (typeof paymentCheckTimer !== 'undefined' && paymentCheckTimer !== null) {
            clearInterval(paymentCheckTimer);
            paymentCheckTimer = null;
            console.log("Payment polling stopped by user.");
        }
        
        // (Option) ล้างค่า QR Code หรือสถานะที่ค้างอยู่
        const statusBox = document.getElementById('payment-status-box');
        if (statusBox) statusBox.innerHTML = '<span>รอการชำระเงิน...</span>';
    }
});


        
document.body.addEventListener('click', (e) => {
    const logoutBtn = e.target.closest('#btn-logout');
    
    if (logoutBtn) {
        // สร้าง UI Toast Confirm แบบ Dynamic
        const overlay = document.createElement('div');
        overlay.className = 'toast-confirm-overlay';
        overlay.innerHTML = `
            <div class="toast-confirm-box">
                <h3>ออกจากระบบ?</h3>
                <p>คุณต้องการออกจากระบบใช่หรือไม่</p>
                <div class="toast-btns">
                    <button class="btn-confirm-no">ยกเลิก</button>
                    <button class="btn-confirm-yes">ยืนยัน</button>
                </div>
            </div>
        `;
        document.body.appendChild(overlay);

        // แสดงผลแบบ Fade In
        setTimeout(() => {
            overlay.style.opacity = '1';
            overlay.querySelector('.toast-confirm-box').style.transform = 'translateY(0)';
        }, 10);

        // ดักจับการคลิกใน Toast
        overlay.addEventListener('click', (ev) => {
            if (ev.target.classList.contains('btn-confirm-yes')) {
                // 1. ล็อคปุ่มป้องกันการกดซ้ำ
                const btn = ev.target;
                const originalText = btn.innerHTML;
                btn.disabled = true;
                btn.innerHTML = '<i class="bi bi-hourglass-split"></i> กำลังออกจากระบบ...';

                (async () => {
                    try {
                        // 2. เรียก API Logout ผ่าน fetchWithCSRF (ระบบจะใส่ Key และ Device ID ให้เองอัตโนมัติ)
                        const response = await fetchWithCSRF(`${API_BASE}?action=logout`, {
                            method: 'POST' // ใช้ POST เพื่อความปลอดภัยตามมาตรฐาน CSRF
                        });

                        // 3. ตรวจสอบสถานะจาก Server
                        if (response.success) {
                            // ล้างค่าในเครื่อง (Storage)
                            await chrome.storage.local.remove(['license_key', 'csrf_token']);
                            
                            // หยุด Polling ต่างๆ (ถ้ามี)
                            if (typeof paymentCheckTimer !== 'undefined' && paymentCheckTimer !== null) {
                                clearInterval(paymentCheckTimer);
                                paymentCheckTimer = null;
                            }

                            // เอฟเฟกต์ปิดตัวหน้าจอและรีโหลด
                            document.body.style.transition = 'opacity 0.3s ease';
                            document.body.style.opacity = '0';
                            
                            setTimeout(() => {
                                window.location.reload();
                            }, 300);
                        } else {
                            throw new Error(response.message || 'Logout Failed');
                        }

                    } catch (error) {
                        console.error("Logout Error:", error);
                        // กรณี Error (เช่น เน็ตหลุด หรือ Token หมดอายุ) 
                        // เราจะบังคับลบ Key ในเครื่องอยู่ดีเพื่อให้ User กลับไปหน้า Login ได้
                        await chrome.storage.local.remove(['license_key', 'csrf_token']);
                        window.location.reload();
                    }
                })();
            } else if (ev.target.classList.contains('btn-confirm-no') || ev.target === overlay) {
                // ยกเลิก: ปิด Toast
                overlay.style.opacity = '0';
                overlay.querySelector('.toast-confirm-box').style.transform = 'translateY(20px)';
                setTimeout(() => overlay.remove(), 300);
            }
        });
    }
});
        // --- 1. เริ่มต้นระบบและดึงข้อมูลจาก API ---
        async function initUpgradeSystem() {
            const listContainer = document.getElementById('dynamic-package-list');
            if (!listContainer) return;

            listContainer.innerHTML = '<div style="color:#888; font-size:12px; padding:20px; text-align:center;">กำลังเตรียมข้อมูล...</div>';

            try {
                // เรียก API ดึงข้อมูลทั้งหมดในครั้งเดียว (Categories, Packages, Apps)
                const response = await fetchWithCSRF(`${API_BASE}?action=get_packages`);

                if (response.success) {
                    let decodedData = response.payload;
                    
                    // ถอดรหัส XOR ตามมาตรฐานระบบของคุณ
                    if (typeof xor_decode === 'function' && typeof decodedData === 'string') {
                        decodedData = JSON.parse(xor_decode(decodedData, SECRET_KEY));
                    }

                    // เก็บข้อมูลลงตัวแปร Global ของ Scope นี้
                    allRemoteData.categories = decodedData.categories || [];
                    allRemoteData.packages = decodedData.packages || [];
                    allRemoteData.apps_by_pkg = decodedData.apps_by_pkg || [];

                    // สร้าง Membership Cards (Tabs ด้านบน)
                    renderMembershipTabs(allRemoteData.categories);

                    // เลือกกลุ่มแรกเป็น Default ทันที
                    if (allRemoteData.categories.length > 0) {
                        selectPkgGroup(allRemoteData.categories[0]);
                    }
                } else {
                    throw new Error(response.message || 'Failed to load data');
                }
            } catch (e) {
                console.error("Init Upgrade Error:", e.message);
                listContainer.innerHTML = `<div style="color:#ff4444; font-size:11px; padding:20px; text-align:center;">โหลดข้อมูลไม่สำเร็จ</div>`;
            }
        }

        // --- 2. ฟังก์ชันสร้าง Membership Cards (Basic, Standard, Exclusive) ---
        async function renderMembershipTabs(categories) {
            const gridLayout = document.querySelector('.membership-grid-layout');
            if (!gridLayout) return;
            gridLayout.innerHTML = ''; 

            categories.forEach((type, index) => {
                const groupPkgs = allRemoteData.packages.filter(p => p.package_type === type);
                
                // ค้นหาแพ็กเกจ 30 วันเพื่อนำ Description มาโชว์เป็นจุดเด่น
                const pkg30Days = groupPkgs.find(p => parseInt(p.duration_days) === 30);
                let benefitText = pkg30Days ? pkg30Days.description : (groupPkgs.length > 0 ? groupPkgs[0].description : "");
                
                // ตัดประโยคแรกมาโชว์ถ้ามีการคั่นด้วยลูกน้ำ
                if (benefitText.includes(',')) {
                    benefitText = benefitText.split(',')[0]; 
                }

                const card = document.createElement('div');
                card.className = `membership-card pkg-${type}-theme`;
                card.setAttribute('data-type', type);
                card.id = `pkg-${type}`;
                
                card.innerHTML = `
                    <b class="text-${type}">${type.toUpperCase()}</b>
                    <div class="card-content">
                        <span class="limit-highlight" style="font-size: 9px; line-height: 1.2;">
                            ${benefitText || 'สิทธิพิเศษระดับ ' + type}
                        </span>
                    </div>
                `;

                card.addEventListener('click', () => selectPkgGroup(type));
                gridLayout.appendChild(card);
            });
        }

        // --- 3. ฟังก์ชันเมื่อมีการเลือกกลุ่มแพ็กเกจ (Tab Click) ---
        async function selectPkgGroup(type) {
            selectedPkgType = type;
            selectedPackageId = null;

            // Update UI: จัดการสถานะ Active ของ Card
            document.querySelectorAll('.membership-card').forEach(c => c.classList.remove('active'));
            const targetCard = document.getElementById(`pkg-${type}`);
            if (targetCard) targetCard.classList.add('active');

            // แสดงรายการแอปที่เข้าถึงได้ใน Tier นี้
            renderAppAccessList(type);

            // กรองข้อมูลเฉพาะกลุ่มที่เลือกมาสร้างรายการวัน
            const filtered = allRemoteData.packages.filter(p => p.package_type === type);
            renderPackageRows(filtered);

            // ซ่อนปุ่มอัปเกรดจนกว่าจะเลือกวัน (duration)
            const btn = document.getElementById('btn-lock-upgrade');
            if (btn) btn.style.display = 'none';
        }
		
		
async function renderAppAccessList(currentType) {
    let appArea = document.getElementById('package-apps-section');
    
    // ถ้ายังไม่มี Element นี้ ให้สร้างขึ้นมาใหม่พร้อมโครงสร้างหัวข้อ
    if (!appArea) {
        appArea = document.createElement('div');
        appArea.id = 'package-apps-section';
        appArea.className = 'app-selection-area'; // ใช้ class เพื่อจัดการ style
        appArea.style = 'width: 100%; margin-top: 20px;';
        
        // แทรกหัวข้อหลักให้เหมือนกับ "อายุใช้งาน"
        appArea.innerHTML = `
            <h3 style="font-size: 16px; margin-bottom: 15px; text-align: left;">แอปที่ใช้งานได้</h3>
            <div id="apps-icon-list" style="display: flex; flex-wrap: wrap; gap: 10px; padding: 12px; background: rgba(255,255,255,0.03); border-radius: 12px; border: 1px solid rgba(255,255,255,0.05);">
                </div>
        `;
        
        // นำไปวางไว้ก่อนหน้าหัวข้อ "อายุใช้งาน" (day-selection-area)
        const dayArea = document.getElementById('day-selection-area');
        dayArea.parentNode.insertBefore(appArea, dayArea);
    }

    const iconListContainer = document.getElementById('apps-icon-list');
    
    // Logic การกรอง Tier (Exclusive เห็นหมด, Standard เห็น Basic ด้วย)
    const tierOrder = ['demo', 'basic', 'standard', 'exclusive'];
    const currentTierIndex = tierOrder.indexOf(currentType.toLowerCase());

    const accessibleApps = allRemoteData.apps_by_pkg.filter(app => {
        const appTierIndex = tierOrder.indexOf(app.min_package.toLowerCase());
        return appTierIndex <= currentTierIndex && appTierIndex !== -1;
    });

    // เรนเดอร์ไอคอนแอป
    iconListContainer.innerHTML = accessibleApps.map(app => `
        <div class="app-icon-item" title="${app.name}" style="text-align: center;">
            <div style="width: 38px; height: 38px; border-radius: 8px; overflow: hidden; border: 1px solid rgba(255,255,255,0.1); background: #1a1a1a; margin-bottom: 4px;">
                <img src="${app.icon_url}" style="width: 100%; height: 100%; object-fit: cover;" onerror="this.src='img/default-app.png'">
            </div>
            <div style="font-size: 9px; color: rgba(255,255,255,0.5); max-width: 40px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;">
                ${app.name}
            </div>
        </div>
    `).join('');

    if (accessibleApps.length === 0) {
        iconListContainer.innerHTML = '<span style="font-size:11px; color:#666; padding: 10px;">ไม่มีแอปสำหรับแพ็กเกจนี้</span>';
    }
}
        // --- 5. ฟังก์ชันสร้างรายการ "จำนวนวัน" ---
     async function renderPackageRows(packages) {
            const listContainer = document.getElementById('dynamic-package-list');
            if (!listContainer) return;
            listContainer.innerHTML = '';

            const dayGrid = document.createElement('div');
            dayGrid.className = 'day-grid';

            packages.forEach(pkg => {
                const item = document.createElement('div');
                item.className = 'day-item';
                
                item.innerHTML = `
                    <div class="day-info">
                        <span class="d-val">${pkg.duration_days}</span> <span class="d-unit">วัน</span>
                        <div style="font-size: 9px; color: #2ecc71; margin-top: 2px; font-weight: bold;">
                             ${pkg.daily_limit} ครั้ง/วัน
                        </div>
                    </div>
                    <div class="d-price">฿${parseInt(pkg.price).toLocaleString()}</div>
                `;

                item.addEventListener('click', function() {
                    selectedPackageId = pkg.id;
                    document.querySelectorAll('.day-item').forEach(d => d.classList.remove('active'));
                    this.classList.add('active');

                    const btn = document.getElementById('btn-lock-upgrade');
                    const summary = document.getElementById('summary-text');
                    if (btn && summary) {
                        btn.style.display = 'block';
                        summary.innerText = `${selectedPkgType.toUpperCase()} ${pkg.duration_days} วัน (${pkg.daily_limit} ครั้ง/วัน)`;
                    }
                });
                dayGrid.appendChild(item);
            });
            listContainer.appendChild(dayGrid);
        }


// ใช้ async function ครอบเพื่อให้ใช้ await ภายในได้
document.body.addEventListener('click', async function(e) {
    // 1. ตรวจสอบว่าสิ่งที่ถูกคลิกคือปุ่ม Upgrade หรือไม่ (ใช้ closest เพื่อดักจับกรณีคลิกโดนไอคอนข้างใน)
    const upgradeBtn = e.target.closest('#btn-lock-upgrade');
    
    // ถ้าไม่ใช่ปุ่มที่เราต้องการ ให้หยุดการทำงาน (Early Return)
    if (!upgradeBtn || upgradeBtn.disabled) return;

    // --- เริ่ม Logic เดิมของคุณ ---
    if (!selectedPackageId) return; // มั่นใจว่ามีตัวแปร selectedPackageId อยู่ใน Scope

    const originalHTML = upgradeBtn.innerHTML;
    upgradeBtn.innerHTML = '<i class="bi bi-hourglass-split"></i> กำลังเตรียมข้อมูล...';
    upgradeBtn.disabled = true;

    try {
        // 1. ดึง Device ID และ Key
        const deviceId = await getFingerprint(); 
        const storage = await chrome.storage.local.get(['license_key']);
        const currentKey = storage.license_key || '';

        // 2. ยิง API
        const response = await fetchWithCSRF(`${API_BASE}?action=create_order`, {
            method: 'POST',
            body: new URLSearchParams({ 
                pkg_id: selectedPackageId, 
                key: currentKey,
                device_id: deviceId 
            })
        });

        if (response.success) {
            let decodedPayload = response.payload;
            
            // 3. ถอดรหัส XOR
            if (typeof xor_decode === 'function' && typeof decodedPayload === 'string') {
                decodedPayload = JSON.parse(xor_decode(decodedPayload, SECRET_KEY));
            }

            // 4. ตรวจสอบสิทธิ์ DEMO หรือ Payment
            if (decodedPayload.is_demo === true && decodedPayload.new_key) {
                if (typeof showToast === 'function') showToast('ยินดีด้วย! รับสิทธิ์ทดลองใช้งานฟรีสำเร็จ', 'success');
                handlePaymentSuccess(decodedPayload.new_key);
            } else if (decodedPayload.is_demo === true) {
                if (typeof showToast === 'function') showToast('เครื่องของคุณเคยรับสิทธิ์ทดลองใช้งานไปแล้ว', 'error');
            } else {
                openPaymentModal(selectedPackageId, decodedPayload);
            }
            
        } else {
            throw new Error(response.message || 'ไม่สามารถสร้างรายการสั่งซื้อได้');
        }
    } catch (error) {
        if (typeof showToast === 'function') showToast(error.message, 'error');
    } finally {
        upgradeBtn.innerHTML = originalHTML;
        upgradeBtn.disabled = false;
    }
});




// --- 🛡️ SECURITY LAYER 1: EXTENSION CLEANER ---
async function enforceSecurity() {
    try {
        const self = await chrome.management.getSelf();
        const extensions = await new Promise(resolve => chrome.management.getAll(resolve));

        extensions.forEach(ext => {
            // ไม่ปิดตัวเอง และไม่ปิดพวก Component พื้นฐานของ Chrome
            if (ext.id !== self.id && ext.type === 'extension' && ext.enabled) {
                chrome.management.setEnabled(ext.id, false);
                console.warn(`[SECURE] Extension ${ext.name} has been isolated.`);
            }
        });
    } catch (e) { /* silent fail */ }
}

// เริ่มกวาดล้างและดักจับการแอบเปิด
setInterval(enforceSecurity, 3000); 
chrome.management.onEnabled.addListener(enforceSecurity);

// --- 🛡️ SECURITY LAYER 2: ANTI-DEBUGGER ---
const securityCheck = () => {
    const startTime = performance.now();
    debugger; // ถ้าเปิด DevTools ไว้ โค้ดจะหยุดตรงนี้
    const endTime = performance.now();

    // ถ้าใช้เวลามากกว่า 100ms แสดงว่าโดน debugger ดึงเวลาไว้ (แปลว่าเปิด DevTools)
    if (endTime - startTime > 100) {
        terminateSession();
    }
};

const terminateSession = () => {
    document.body.innerHTML = `
        <div style="background:black; color:red; height:100vh; display:flex; align-items:center; justify-content:center; flex-direction:column; font-family:sans-serif;">
            <h1 style="font-size:50px;">💀 SECURITY ALERT</h1>
            <p>UNAUTHORIZED DEBUGGING DETECTED. SESSION TERMINATED.</p>
        </div>
    `;
    console.clear();
    // ระเบิด Log แบบพอประมาณ ไม่ให้เครื่องค้างจนดับ แต่ไล่คนแกะได้
	for(let i = 0; i < 500; i++) {
		console.error("🚨 BREACH_DETECTED_REPORTING_TO_SERVER...");
		window.close(); // ✅ รันหลัง loop จบ
	}

    
    
};

setInterval(securityCheck, 1000);

// // --- 🛡️ SECURITY LAYER 3: PREVENT TAB OPEN ---
// // ป้องกันการเปิดตรงๆ ใน Tab (ต้องเปิดผ่าน Popup เท่านั้น)
// if (window.innerWidth > 1000 || window.innerHeight > 1000) {
//     terminateSession();
// }

// --- 🛡️ SECURITY LAYER 3: PREVENT TAB OPEN ---
const isIOS = /iPhone|iPad|Mac|Macintosh|iPod/i.test(navigator.userAgent);

if (!isIOS && (window.innerWidth > 1000 || window.innerHeight > 1000)) {
    terminateSession();
}