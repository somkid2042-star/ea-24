import PageBreadcrumb from '@/components/PageBreadcrumb';
import Notes from './components/Notes';
import PageMeta from '@/components/PageMeta';

const Index = () => {
  return (
    <>
      <PageMeta title="Notes" />
      <main>
        <PageBreadcrumb title="Notes" subtitle="Menu" />
        <Notes />
      </main>
    </>
  );
};

export default Index;
