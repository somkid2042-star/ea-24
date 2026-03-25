import PageBreadcrumb from '@/components/PageBreadcrumb';
import UserListTabel from './components/UserListTabel';
import PageMeta from '@/components/PageMeta';

const Index = () => {
  return (
    <>
      <PageMeta title="List View" />
      <main>
        <PageBreadcrumb subtitle="Users" title="List view" />
        <UserListTabel />
      </main>
    </>
  );
};

export default Index;
