import PageBreadcrumb from '@/components/PageBreadcrumb';
import PageMeta from '@/components/PageMeta';
import { LuShoppingCart } from 'react-icons/lu';
import OrdersSummary from './components/OrdersSummary';
import ShoppingInformation from './components/ShoppingInformation';

const Index = () => {
  return (
    <>
      <PageMeta title="Checkout" />
      <main>
        <PageBreadcrumb title="Checkout" subtitle="Menu" />
        <div className="flex gap-1.25 px-4 py-3 mb-5 text-teal-700 border border-teal-200 rounded-md bg-teal-50">
          <LuShoppingCart className="size-4 text-teal-700" />
          <p className="text-13xl">
            The minimum order requirement is <b>$1,800</b>. To meet this threshold, please add
            additional products with a combined value of <b>$300</b>.
          </p>
        </div>
        <div className="grid lg:grid-cols-3 grid-cols-1 gap-5 mb-5">
          <ShoppingInformation />
          <OrdersSummary />
        </div>
      </main>
    </>
  );
};

export default Index;
