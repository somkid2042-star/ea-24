import PageBreadcrumb from '@/components/PageBreadcrumb';
import ProductList from './components/ProductList';
import PageMeta from '@/components/PageMeta';

const Index = () => {
  return (
    <>
      <PageMeta title="Product List" />
      <main>
        <PageBreadcrumb title="List view" subtitle="Products" />
        <ProductList />
      </main>
    </>
  );
};

export default Index;
