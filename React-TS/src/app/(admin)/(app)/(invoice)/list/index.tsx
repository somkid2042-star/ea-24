import PageBreadcrumb from '@/components/PageBreadcrumb';
import InvoiceList from './components/InvoiceList';
import InvoiceDetails from './components/InvoiceDetails';
import PageMeta from '@/components/PageMeta';

const Index = () => {
  return (
    <>
      <PageMeta title="Invoice List" />
      <main>
        <PageBreadcrumb title="List View" subtitle="Menu" />
        <div className="grid lg:grid-cols-4 grid-cols-1 gap-5">
          <InvoiceList />
          <InvoiceDetails />
        </div>
      </main>
    </>
  );
};

export default Index;
