import PageBreadcrumb from '@/components/PageBreadcrumb';
import { useLayoutContext } from '@/context/useLayoutContext';
import { useEffect } from 'react';

const DarkMode = () => {
  const { updateSettings } = useLayoutContext();
  useEffect(() => {
    updateSettings({
      theme: 'dark',
      sidenav: {
        size: 'default',
        color: 'dark',
      },
    });
  }, []);
  return (
    <>
      <PageBreadcrumb subtitle="Layouts" title="Dark" />
      <div className="card h-40"></div>
    </>
  );
};

export default DarkMode;
