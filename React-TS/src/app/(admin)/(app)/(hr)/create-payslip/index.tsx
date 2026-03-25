import PageBreadcrumb from '@/components/PageBreadcrumb';
import PageMeta from '@/components/PageMeta';
import CreatesSlip from './components/CreatesSlip';

const Index = () => {
  return (
    <>
      <PageMeta title="Create Payslip" />
      <main>
        <PageBreadcrumb title="Create Payslip" subtitle="Menu" />
        <CreatesSlip />
      </main>
    </>
  );
};

export default Index;
