import PageBreadcrumb from '@/components/PageBreadcrumb';
import PageMeta from '@/components/PageMeta';
import EmpLeave from './components/EmpLeave';
import LeaveCard from './components/LeaveCard';

const Index = () => {
  return (
    <>
      <PageMeta title="Leave Manage (Employee)" />
      <main>
        <PageBreadcrumb title="Leave Manage (Employee)" subtitle="Menu" />
        <LeaveCard />
        <EmpLeave />
      </main>
    </>
  );
};

export default Index;
