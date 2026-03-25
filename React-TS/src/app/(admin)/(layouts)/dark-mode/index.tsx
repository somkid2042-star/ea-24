import PageMeta from '@/components/PageMeta';
import DarkMode from './components/DarkMode';

const Index = () => {
  return (
    <>
      <PageMeta title="Dark Mode" />
      <main>
        <DarkMode />
      </main>
    </>
  );
};

export default Index;
