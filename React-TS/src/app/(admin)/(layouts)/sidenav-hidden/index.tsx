import PageMeta from '@/components/PageMeta';
import SideHidden from './components/SideHidden';

const Index = () => {
  return (
    <>
      <PageMeta title="Hidden Sidenav" />
      <main>
        <SideHidden />
      </main>
    </>
  );
};

export default Index;
