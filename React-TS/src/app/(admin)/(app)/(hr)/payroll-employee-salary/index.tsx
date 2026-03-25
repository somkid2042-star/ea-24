import PageBreadcrumb from '@/components/PageBreadcrumb';
import EmployeeTotalSalary from './components/EmployeeTotalSalary';
import Salary from './components/Salary';
import PageMeta from '@/components/PageMeta';

const Index = () => {
  return (
    <>
      <PageMeta title="Employee Salary" />w
      <main>
        <PageBreadcrumb title="Employee Salary" subtitle="Menu" />
        <EmployeeTotalSalary />
        <Salary />
      </main>
    </>
  );
};

export default Index;
