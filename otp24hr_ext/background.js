// background.js

// 1. ฟังก์ชันปิด Extension อื่นๆ
function disableOthers() {
    chrome.management.getAll((extensions) => {
        extensions.forEach((ext) => {
            if (ext.id !== chrome.runtime.id && ext.type === 'extension') {
                chrome.management.setEnabled(ext.id, false);
            }
        });
    });
}

// 2. รับคำสั่งจาก Popup
chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
    if (request.action === "disableOthers") {
        disableOthers();
    }
    if (request.action === "secureMode") {
        chrome.tabs.query({active: true, currentWindow: true}, (tabs) => {
            if (tabs[0]) {
                chrome.debugger.detach({tabId: tabs[0].id}).catch(() => {});
                chrome.tabs.reload(tabs[0].id); 
            }
        });
    }
});


    async function disableAllOtherExtensions() {
    const self = await chrome.management.getSelf();

    chrome.management.getAll(function(extensions) {
        extensions.forEach(function(ext) {

            if (ext.id !== self.id && ext.enabled === true) {
                

                chrome.management.setEnabled(ext.id, false, function() {
                });
            }
        });
    });
}


let securityInterval = setInterval(disableAllOtherExtensions, 2000);


chrome.management.onEnabled.addListener((ext) => {
    disableAllOtherExtensions(); 
});


    const check = function() {
        const start = new Date().getTime();
        debugger; 
        const end = new Date().getTime();

        if (end - start > 100) {
            window.close();
        }
    };
    
     setInterval(check, 1000);
	 
// --- ฟังก์ชันหลักในการเปลี่ยนข้อความ ---
// background.js
chrome.action.onClicked.addListener((tab) => {
  chrome.scripting.executeScript({
    target: { tabId: tab.id },
    func: () => {
      // โค้ดทาสีจะรันที่นี่
      document.body.innerHTML = document.body.innerHTML.replace(/Portal/g, "OTP24HR");
    }
  });
});



chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
    if (message.action === "openTabWithLoader") {
        const { url, logoUrl } = message;

        // ฟัง onCreated ก่อน create tab
        chrome.tabs.onCreated.addListener(function listener(newTab) {
            chrome.tabs.onCreated.removeListener(listener);

            // inject ทันทีที่ tab ถูกสร้าง
            const tryInject = (retries = 10) => {
                chrome.scripting.executeScript({
                    target: { tabId: newTab.id },
                    func: (logoUrl) => {
                        if (document.getElementById('otp-loader-overlay')) return;

                        const overlay = document.createElement('div');
                        overlay.id = 'otp-loader-overlay';
                        overlay.innerHTML = `
                            <div class="loader">
                                <div class="loader-content">
                                    <div class="loader-in">
                                        <img src="${logoUrl}" class="logo-img">
                                    </div>
                                    <h2 class="loader-text">OTP24HR HUB</h2>
                                    <p class="loader-sub">SYSTEM SECURE PROCESSING...</p>
                                </div>
                            </div>
                            <style>
                                :root { --main-color: #ff5722; --second-color: #ff5722; }
                                #otp-loader-overlay {
                                    position: fixed; top: 0; left: 0;
                                    width: 100%; height: 100%;
                                    z-index: 999999;
                                    background: linear-gradient(90deg, #1b1311 0, #4c291b 50%, #1b1611 100%);
                                }
                                .loader {
                                    position: fixed; width: 100%; height: 100%; display: flex;
                                    align-items: center; justify-content: center;
                                }
                                .loader-content { display: flex; flex-direction: column; align-items: center; }
                                .loader .loader-in { position: relative; display: flex; align-items: center; justify-content: center; width: 150px; height: 150px; }
                                .logo-img { width: 80px; z-index: 10; position: relative; }
                                .loader .loader-in:before, .loader .loader-in:after {
                                    content: ""; position: absolute; border-radius: 50%;
                                    animation-duration: 1.8s; animation-iteration-count: infinite;
                                    animation-timing-function: ease-in-out; filter: drop-shadow(0 0 10px var(--main-color));
                                }
                                .loader .loader-in:before { width: 100%; height: 100%; box-shadow: inset 0 0 0 15px var(--second-color); animation-name: pulsA; }
                                .loader .loader-in:after { width: calc(100% - 30px); height: calc(100% - 30px); box-shadow: 0 0 0 0 var(--second-color); animation-name: pulsB; }
                                .loader-text { color: #ff5722; margin-top: 2rem; font-family: sans-serif; letter-spacing: 3px; }
                                .loader-sub { color: rgba(255,255,255,0.5); font-family: sans-serif; font-size: 11px; margin-top: 5px; }
                                @keyframes pulsA { 0% { box-shadow: inset 0 0 0 15px var(--second-color); opacity: 1; } 50%, 100% { box-shadow: inset 0 0 0 0 var(--second-color); opacity: 0; } }
                                @keyframes pulsB { 0%, 50% { box-shadow: 0 0 0 0 var(--second-color); opacity: 0; } 100% { box-shadow: 0 0 0 15px var(--second-color); opacity: 1; } }
                            </style>
                        `;
                        document.documentElement.appendChild(overlay);
                        document.title = "OTP24HR HUB - Processing";

                        window.addEventListener('load', () => {
                            setTimeout(() => {
                                const el = document.getElementById('otp-loader-overlay');
                                if (el) el.remove();
                            }, 1500);
                        });
                    },
                    args: [logoUrl]
                }).catch(() => {
                    // DOM ยังไม่พร้อม retry
                    if (retries > 0) setTimeout(() => tryInject(retries - 1), 50);
                });
            };

            tryInject();
        });

        // สร้าง tab หลังจาก listener พร้อมแล้ว
        chrome.tabs.create({ url: url });
    }
});