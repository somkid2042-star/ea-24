import PageBreadcrumb from '@/components/PageBreadcrumb';
import PageMeta from '@/components/PageMeta';
import CreateLeave from './components/CreateLeave';

const Index = () => {
  return (
    <>
      <PageMeta title="Add Leave (HR)" />
      <main>
        <PageBreadcrumb title="Add Leave (HR)" subtitle="Menu" />
        <CreateLeave />
      </main>
    </>
  );
};

export default Index;
