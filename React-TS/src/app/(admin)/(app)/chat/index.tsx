import PageMeta from '@/components/PageMeta';
import Chats from './components/Chats';
import IconTab from './components/IconTab';
import UserChats from './components/UserChats';

const Index = () => {
  return (
    <>
      <PageMeta title="Chat" />
      <main>
        <div className="card overflow-hidden">
          <div className="flex">
            <div className="lg:border-e border-default-200">
              <div
                id="hs-offcanvas-left"
                className="hs-overlay [--auto-close:lg] lg:block lg:translate-x-0 lg:static lg:end-auto lg:bottom-0 w-96 hs-overlay-open:translate-x-0 -translate-x-full transition-all duration-300 transform h-full hidden fixed top-0 start-0 bottom-0 overflow-hidden z-60"
                role="dialog"
                tabIndex={-1}
                aria-label="Sidebar"
              >
                <div className="card rounded-none shadow-none relative flex flex-row h-full max-h-full overflow-hidden divide-x divide-default-200">
                  <IconTab />
                  <Chats />
                </div>
              </div>
            </div>
            <UserChats />
          </div>
        </div>
      </main>
    </>
  );
};

export default Index;
