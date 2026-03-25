import PageBreadcrumb from '@/components/PageBreadcrumb';
import PageMeta from '@/components/PageMeta';

const Index = () => {
  return (
    <>
      <PageMeta title="Starter" />
      <main>
        <PageBreadcrumb title="Starter" subtitle="Menu" />
        <div className="card h-40"></div>
      </main>
    </>
  );
};

export default Index;
