import PageBreadcrumb from '@/components/PageBreadcrumb';
import Product from './components/Product';
import ProductDetails from './components/ProductDetails';
import Ratings from './components/Ratings';
import PageMeta from '@/components/PageMeta';

const Index = () => {
  return (
    <>
      <PageMeta title="product Overview" />
      <main>
        <PageBreadcrumb title="Overview" subtitle="Menu" />
        <div className="grid lg:grid-cols-3 grid-cols-1 lg:gap-5">
          <Product />
          <div className="lg:col-span-2 col-span-1">
            <div className="card">
              <div className="card-body">
                <ProductDetails />
                <Ratings />
              </div>
            </div>
          </div>
        </div>
      </main>
    </>
  );
};

export default Index;
