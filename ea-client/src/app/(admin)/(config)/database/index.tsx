import { LuDatabase, LuSave } from 'react-icons/lu';

const DatabaseSettings = () => {
  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h4 className="text-lg font-semibold text-default-900">Database Settings</h4>
          <p className="mt-1 text-sm text-default-500">Configure encrypted SQLite database parameters</p>
        </div>
        <nav className="text-sm text-default-500">Tailwick &gt; Config Server &gt; Database Settings</nav>
      </div>

      <div className="rounded-lg border border-default-200 bg-white p-5 dark:bg-default-50">
        <div className="mb-4 flex items-center gap-2">
          <LuDatabase className="size-5 text-primary" />
          <h5 className="text-base font-semibold text-default-900">Database Configuration</h5>
        </div>
        <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
          <div>
            <label className="mb-1.5 block text-sm font-medium text-default-700">Database Path</label>
            <input type="text" defaultValue="./data/ea24.db" className="w-full rounded-md border border-default-200 px-3 py-2.5 text-sm focus:border-primary focus:outline-none" />
          </div>
          <div>
            <label className="mb-1.5 block text-sm font-medium text-default-700">Encryption Key</label>
            <input type="password" defaultValue="••••••••" className="w-full rounded-md border border-default-200 px-3 py-2.5 text-sm focus:border-primary focus:outline-none" />
          </div>
          <div>
            <label className="mb-1.5 block text-sm font-medium text-default-700">Max Pool Size</label>
            <input type="number" defaultValue="10" className="w-full rounded-md border border-default-200 px-3 py-2.5 text-sm focus:border-primary focus:outline-none" />
          </div>
          <div>
            <label className="mb-1.5 block text-sm font-medium text-default-700">Backup Interval (hours)</label>
            <input type="number" defaultValue="24" className="w-full rounded-md border border-default-200 px-3 py-2.5 text-sm focus:border-primary focus:outline-none" />
          </div>
        </div>
        <button className="mt-4 inline-flex items-center gap-2 rounded-md bg-primary px-4 py-2 text-sm font-medium text-white hover:bg-primary/90">
          <LuSave className="size-4" /> Save Settings
        </button>
      </div>
    </div>
  );
};

export default DatabaseSettings;
