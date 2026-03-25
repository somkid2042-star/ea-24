import PageBreadcrumb from '@/components/PageBreadcrumb';
import Expenses from './components/Expenses';
import ExpensesModal from './components/ExpensesModal';
import PageMeta from '@/components/PageMeta';
const Index = () => {
  return (
    <>
      <PageMeta title="Sales Expenses" />
      <main>
        <PageBreadcrumb title="Sales Expenses" subtitle="Menu" />
        <Expenses />
        <ExpensesModal />
      </main>
    </>
  );
};

export default Index;
