import PageBreadcrumb from '@/components/PageBreadcrumb';
import ComposeEmail from './components/ComposeEmail';
import EmailBarChart from './components/EmailBarChart';
import EmailData from './components/EmailData';
import EmailLineChart from './components/EmailLineChart';
import EmailMarketing from './components/EmailMarketing';
import EmailPerformance from './components/EmailPerformance';
import PageMeta from '@/components/PageMeta';

const Index = () => {
  return (
    <>
      <PageMeta title="Email" />
      <main>
        <PageBreadcrumb title="Email Analytics" subtitle="Dashboard" />
        <EmailLineChart />
        <EmailBarChart />
        <div className="grid lg:grid-cols-4 grid-cols-1 gap-5 mb-5">
          <EmailData />
          <EmailMarketing />
          <ComposeEmail />
        </div>
        <EmailPerformance />
      </main>
    </>
  );
};

export default Index;
