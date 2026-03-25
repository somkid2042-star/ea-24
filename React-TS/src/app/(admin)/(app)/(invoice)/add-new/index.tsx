import PageBreadcrumb from '@/components/PageBreadcrumb';
import AddNew from './components/AddNew';
import PageMeta from '@/components/PageMeta';

const Index = () => {
  return (
    <>
      <PageMeta title="Add New" />
      <main>
        <PageBreadcrumb title="Add New" subtitle="Menu" />
        <AddNew />
      </main>
    </>
  );
};

export default Index;
