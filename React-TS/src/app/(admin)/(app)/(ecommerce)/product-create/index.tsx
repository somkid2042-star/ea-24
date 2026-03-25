import PageBreadcrumb from '@/components/PageBreadcrumb';
import Preview from './components/Preview';
import ProductCreat from './components/ProductCreat';

export const metadata = { title: 'Product Create' };
const Index = () => {
  return (
    <>
      <main>
        <PageBreadcrumb title="Add New" subtitle="Menu" />
        <div className="grid lg:grid-cols-12 grid-cols-1 gap-6">
          <ProductCreat />
          <Preview />
        </div>
      </main>
    </>
  );
};

export default Index;
