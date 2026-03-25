import PageBreadcrumb from '@/components/PageBreadcrumb';
import PageMeta from '@/components/PageMeta';
import Estimates from './components/Estimates';
import EstimentModal from './components/EstimentModal';

const Index = () => {
  return (
    <>
      <PageMeta title="Sales Estimates" />
      <main>
        <PageBreadcrumb title="Sales Estimates" subtitle="Menu" />
        <Estimates />
        <EstimentModal />
      </main>
    </>
  );
};

export default Index;
