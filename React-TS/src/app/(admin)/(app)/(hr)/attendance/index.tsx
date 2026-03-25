import PageBreadcrumb from '@/components/PageBreadcrumb';
import EmployeeDetails from './components/EmployeeDetails';
import EmployeeWork from './components/EmployeeWork';
import EmployeeWorkDetails from './components/EmployeeWorkDetails';
import PageMeta from '@/components/PageMeta';

const Index = () => {
  return (
    <>
      <PageMeta title="Attendance" />
      <main>
        <PageBreadcrumb title="Attendance" subtitle="Menu" />
        <div className="grid lg:grid-cols-4 grid-cols-1 gap-5">
          <EmployeeDetails />
          <div className="lg:col-span-3 col-span-1">
            <EmployeeWorkDetails />
            <EmployeeWork />
          </div>
        </div>
      </main>
    </>
  );
};

export default Index;
