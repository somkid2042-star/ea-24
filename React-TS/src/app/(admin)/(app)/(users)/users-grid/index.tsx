import PageBreadcrumb from '@/components/PageBreadcrumb';
import UserGrid from './components/UserGrid';
import PageMeta from '@/components/PageMeta';

const Index = () => {
  return (
    <>
      <PageMeta title="Grid View" />
      <main>
        <PageBreadcrumb title="Grid View" subtitle="Mesnu" />
        <UserGrid />
      </main>
    </>
  );
};

export default Index;
