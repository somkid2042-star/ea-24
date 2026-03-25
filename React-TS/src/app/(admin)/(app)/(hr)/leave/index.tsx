import PageBreadcrumb from '@/components/PageBreadcrumb';
import PageMeta from '@/components/PageMeta';
import LeaveCard from './components/LeaveCard';
import LeaveTabel from './components/LeaveTabel';
import Modal from './components/Modal';

const Index = () => {
  return (
    <>
      <PageMeta title="Leave Manage (HR)" />
      <main>
        <PageBreadcrumb title="Leave Manage (HR)" subtitle="Menu" />
        <LeaveCard />
        <LeaveTabel />
        <Modal />
      </main>
    </>
  );
};

export default Index;
