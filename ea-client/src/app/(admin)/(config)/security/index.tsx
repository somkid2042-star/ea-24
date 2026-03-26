import { LuShieldCheck, LuSave, LuKey } from 'react-icons/lu';

const SecuritySettings = () => {
  return (
    <main className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h4 className="text-lg font-semibold text-default-900">Security & License</h4>
          <p className="mt-1 text-sm text-default-500">Manage API keys, authentication, and license settings</p>
        </div>
        <nav className="text-sm text-default-500">Tailwick &gt; Config Server &gt; Security & License</nav>
      </div>

      <div className="card">
        <div className="p-5">
          <div className="mb-4 flex items-center gap-2">
            <LuShieldCheck className="size-5 text-primary" />
            <h5 className="text-base font-semibold text-default-900">Security Configuration</h5>
          </div>
          <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
            <div>
              <label className="mb-1.5 block text-sm font-medium text-default-700">API Key</label>
              <input type="password" defaultValue="ea24-api-key-xxxx" className="w-full rounded-md border border-default-200 px-3 py-2.5 text-sm bg-transparent focus:border-primary focus:outline-none dark:border-default-200 dark:text-white" />
            </div>
            <div>
              <label className="mb-1.5 block text-sm font-medium text-default-700">JWT Secret</label>
              <input type="password" defaultValue="••••••••••••" className="w-full rounded-md border border-default-200 px-3 py-2.5 text-sm bg-transparent focus:border-primary focus:outline-none dark:border-default-200 dark:text-white" />
            </div>
          </div>
          <button className="mt-4 inline-flex items-center gap-2 rounded-md bg-primary px-4 py-2 text-sm font-medium text-white hover:bg-primary/90">
            <LuSave className="size-4" /> Save Settings
          </button>
        </div>
      </div>

      <div className="card">
        <div className="p-5">
          <div className="mb-4 flex items-center gap-2">
            <LuKey className="size-5 text-primary" />
            <h5 className="text-base font-semibold text-default-900">License</h5>
          </div>
          <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
            <div>
              <label className="mb-1.5 block text-sm font-medium text-default-700">License Key</label>
              <input type="text" placeholder="Enter your license key" className="w-full rounded-md border border-default-200 px-3 py-2.5 text-sm bg-transparent focus:border-primary focus:outline-none dark:border-default-200 dark:text-white" />
            </div>
            <div className="flex items-end">
              <button className="rounded-md bg-green-600 px-4 py-2.5 text-sm font-medium text-white hover:bg-green-700">
                Activate License
              </button>
            </div>
          </div>
          <div className="mt-3 rounded-md bg-yellow-50 p-3 text-sm text-yellow-700 dark:bg-yellow-500/10 dark:text-yellow-500">
            ⚠️ No license activated. Running in trial mode (max 1 MT5 instance).
          </div>
        </div>
      </div>
    </main>
  );
};

export default SecuritySettings;
