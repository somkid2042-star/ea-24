import PageBreadcrumb from '@/components/PageBreadcrumb';
import AddLeave from './components/AddLeave';
import PageMeta from '@/components/PageMeta';

const Index = () => {
  return (
    <>
      <PageMeta title="Add Leave (Employee)" />
      <main>
        <PageBreadcrumb title="Add Leave (Employee)" subtitle="Menu" />
        <AddLeave />
      </main>
    </>
  );
};

export default Index;
