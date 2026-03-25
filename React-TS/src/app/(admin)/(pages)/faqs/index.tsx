import PageBreadcrumb from '@/components/PageBreadcrumb';
import PageMeta from '@/components/PageMeta';
import FaqsCard from './components/FaqsCard';
import ProductsVideo from './components/ProductsVideo';
import Questions from './components/Questions';

const Index = () => {
  return (
    <>
      <PageMeta title="FAQs" />
      <main>
        <PageBreadcrumb title="FAQs" subtitle="Pages" />
        <FaqsCard />
        <Questions />
        <ProductsVideo />
      </main>
    </>
  );
};

export default Index;
