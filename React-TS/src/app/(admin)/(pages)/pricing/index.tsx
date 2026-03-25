import PageBreadcrumb from '@/components/PageBreadcrumb';
import PageMeta from '@/components/PageMeta';
import HorizontalPricing from './components/HorizontalPricing';
import Pricing from './components/PricingCard';

const Index = () => {
  return (
    <>
      <PageMeta title="Pricing" />
      <main>
        <PageBreadcrumb title="Pricing" subtitle="Pages" />
        <Pricing />
        <HorizontalPricing />
      </main>
    </>
  );
};

export default Index;
