import PageBreadcrumb from '@/components/PageBreadcrumb';
import Emails from './components/Emails';
import Emailsidebar from './components/Emailsidebar';
import EventModal from './components/EventModal';
import MailOffcanavs from './components/MailOffcanavs';
import PageMeta from '@/components/PageMeta';

const Index = () => {
  return (
    <>
      <PageMeta title="Mailbox" />
      <main className="overflow-x-hidden">
        <PageBreadcrumb title="Mailbox" subtitle="Apps" />
        <div className="grid grid-cols-1">
          <div className="col-span-1">
            <div className="card">
              <div className="flex">
                <Emailsidebar />
                <div className="w-full relative">
                  <Emails />
                  <MailOffcanavs />
                </div>
              </div>
            </div>
          </div>
        </div>
      </main>
      <EventModal />
    </>
  );
};

export default Index;
