import PageBreadcrumb from '@/components/PageBreadcrumb';
import PageMeta from '@/components/PageMeta';
import AddDepartment from './components/AddDepartment';
import DeleteModal from './components/DeleteModal';
import Departments from './components/Departments';

const Index = () => {
  return (
    <>
      <PageMeta title="Departments" />
      <main>
        <PageBreadcrumb title="Departments" subtitle="Menu" />
        <Departments />
        <DeleteModal />
        <AddDepartment />
      </main>
    </>
  );
};

export default Index;
