import PageBreadcrumb from '@/components/PageBreadcrumb';
import PageMeta from '@/components/PageMeta';
import CartItems from './components/CartItems';
import Modal from './components/Modal';
import OrderSummary from './components/OrderSummary';

const Index = () => {
  return (
    <>
      <PageMeta title="Shopping Cart" />
      <main>
        <PageBreadcrumb title="Shopping Cart" subtitle="Menu" />
        <div className="grid lg:grid-cols-4 grid-cols-1 gap-5">
          <CartItems />
          <OrderSummary />
        </div>
      </main>
      <Modal />
    </>
  );
};

export default Index;
