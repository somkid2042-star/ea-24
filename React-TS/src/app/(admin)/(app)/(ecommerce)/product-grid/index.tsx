import PageMeta from '@/components/PageMeta';
import ProductFilter from './components/ProductFilter';
import Products from './components/Products';
import PageBreadcrumb from '@/components/PageBreadcrumb';

const Index = () => {
  return (
    <>
      <PageMeta title="Product Grid" />
      <main>
        <PageBreadcrumb title="Product Grid" subtitle="Menu" />
        <div className="grid lg:grid-cols-4 grid-cols-1 gap-5">
          <div className="col-span-1 lg:block hidden">
            <ProductFilter />
          </div>
          <Products />
        </div>
      </main>
    </>
  );
};

export default Index;
