import PageBreadcrumb from '@/components/PageBreadcrumb';
import PageMeta from '@/components/PageMeta';
import DocumentTrackingOrder from './components/DocumentTrackingOrder';
import OrderDetails from './components/OrderDetails';
import OrdersSummary from './components/OrdersSummary';
import OrderStatus from './components/OrderStatus';
import ShippingDetails from './components/ShippingDetails';

const Index = () => {
  return (
    <>
      <PageMeta title="Order" />
      <main>
        <PageBreadcrumb title="Order Overview" subtitle="Menu" />
        <OrderDetails />
        <div className="grid lg:grid-cols-4 grid-cols-1 gap-5 mb-5">
          <div className="lg:col-span-3 col-span-1">
            <ShippingDetails />
            <OrdersSummary />
            <OrderStatus />
          </div>
          <DocumentTrackingOrder />
        </div>
      </main>
    </>
  );
};

export default Index;
