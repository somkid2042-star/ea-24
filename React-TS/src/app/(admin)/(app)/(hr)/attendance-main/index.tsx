import PageBreadcrumb from '@/components/PageBreadcrumb';
import PageMeta from '@/components/PageMeta';
import EmployeeReport from './components/EmployeeReport';
import EmployeeReportTabel from './components/EmployeeReportTabel';

const Index = () => {
  return (
    <>
      <PageMeta title="Main Attendance" />
      <main>
        <PageBreadcrumb title="Main Attendance" subtitle="Menu" />
        <EmployeeReport />
        <EmployeeReportTabel />
      </main>
    </>
  );
};

export default Index;
