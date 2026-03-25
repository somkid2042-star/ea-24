import PageBreadcrumb from '@/components/PageBreadcrumb';
import OrderDetails from './components/OrderDetails';
import OrderDetailTable from './components/OrderDetailTabel';
import OrderOverView from './components/OrderOverView';
import PageMeta from '@/components/PageMeta';

const Index = () => {
  return (
    <>
      <PageMeta title="Orders" />
      <main>
        <PageBreadcrumb title="Orders List" subtitle="Orders" />
        <div className="grid lg:grid-cols-3 grid-cols-1 gap-5 mb-5">
          <OrderDetails />
          <OrderOverView />
        </div>
        <OrderDetailTable />
      </main>
    </>
  );
};

export default Index;
