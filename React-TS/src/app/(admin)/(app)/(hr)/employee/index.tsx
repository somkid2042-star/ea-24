import PageBreadcrumb from '@/components/PageBreadcrumb';
import PageMeta from '@/components/PageMeta';
import EditEmployeeData from './components/EditEmployeeData';
import EmployeeDelete from './components/EmployeeDelete';
import EmployeeDetails from './components/EmployeeDetails';

const Index = () => {
  return (
    <>
      <PageMeta title="Employee List" />
      <main>
        <PageBreadcrumb title="Employee List" subtitle="Menu" />
        <EmployeeDetails />
      </main>
      <EditEmployeeData />
      <EmployeeDelete />
    </>
  );
};

export default Index;
