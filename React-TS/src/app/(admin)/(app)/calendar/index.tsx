import PageBreadcrumb from '@/components/PageBreadcrumb';
import PageMeta from '@/components/PageMeta';
import Calender from './components/Calender';

const Index = () => {
  return (
    <>
      <PageMeta title="Calendar" />
      <main>
        <PageBreadcrumb title="Calendar" subtitle="Menu" />
        <div className="grid lg:grid-cols-4 gap-5">
          <Calender />
        </div>
      </main>
    </>
  );
};

export default Index;
