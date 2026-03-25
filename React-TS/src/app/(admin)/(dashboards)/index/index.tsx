import PageBreadcrumb from '@/components/PageBreadcrumb';
import PageMeta from '@/components/PageMeta';
import Audience from './components/Audience';
import CustomerService from './components/CustomerService';
import OrderStatistics from './components/OrderStatistics';
import ProductOrderDetails from './components/ProductOrderDetails';
import ProductOrders from './components/ProductOrders';
import SalesRevenueOverview from './components/SalesRevenueOverview';
import SalesThisMonth from './components/SalesThisMonth';
import TopSellingProducts from './components/TopSellingProducts';
import TrafficResources from './components/TrafficResources';
import WelcomeUser from './components/WelcomeUser';

const Index = () => {
  return (
    <>
      <PageMeta title="Ecommerce" />
      <main>
        <PageBreadcrumb title="Ecommerce" subtitle="Dashboards" />
        <div className="grid lg:grid-cols-3 grid-cols-1 gap-5 mb-5">
          <div className="lg:col-span-2 col-span-1">
            <WelcomeUser />
            <ProductOrderDetails />
          </div>
          <OrderStatistics />
        </div>
        <div className="grid lg:grid-cols-3 grid-cols-1 gap-5 mb-5">
          <SalesRevenueOverview />
          <TrafficResources />
        </div>
        <ProductOrders />
        <div className="grid lg:grid-cols-4 grid-cols-1 gap-5">
          <CustomerService />
          <SalesThisMonth />
          <TopSellingProducts />
          <Audience />
        </div>
      </main>
    </>
  );
};

export default Index;
