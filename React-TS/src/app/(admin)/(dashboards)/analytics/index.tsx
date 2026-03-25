import PageBreadcrumb from '@/components/PageBreadcrumb';
import Analytics from './components/Analytics';
import AnalyticsReports from './components/AnalyticsReports';
import LocationBased from './components/LocationBased';
import PagesInteraction from './components/PagesInteraction';
import PerspectiveChart from './components/PerspectiveChart';
import ProductsStatistics from './components/ProductsStatistics';
import StatusOfMonthlyCampaign from './components/StatusOfMonthlyCampaign';
import SubscriptionDistribution from './components/SubscriptionDistribution';
import TrafficSource from './components/TrafficSource';
import UserChart from './components/UserChart';
import PageMeta from '@/components/PageMeta';

const Index = () => {
  return (
    <>
      <PageMeta title="Analytics" />
      <main>
        <PageBreadcrumb title="Analytics" subtitle="Dashboard" />
        <div className="grid lg:grid-cols-3 grid-cols-1 gap-5 mb-5">
          <Analytics />
          <PerspectiveChart />
        </div>
        <div className="grid lg:grid-cols-12 grid-cols-1 gap-5 mb-5">
          <LocationBased />
          <PagesInteraction />
        </div>
        <UserChart />
        <ProductsStatistics />
        <div className="grid lg:grid-cols-4 grid-cols-1 gap-5">
          <AnalyticsReports />
          <StatusOfMonthlyCampaign />
          <SubscriptionDistribution />
          <TrafficSource />
        </div>
      </main>
    </>
  );
};

export default Index;
