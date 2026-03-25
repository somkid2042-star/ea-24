import PageBreadcrumb from '@/components/PageBreadcrumb';
import Payments from './components/Payments';
import PageMeta from '@/components/PageMeta';

const Index = () => {
  return (
    <>
      <PageMeta title="Sales Payments" />
      <main>
        <PageBreadcrumb title="Sales Payments" subtitle="Menu" />
        <Payments />
      </main>
    </>
  );
};

export default Index;
