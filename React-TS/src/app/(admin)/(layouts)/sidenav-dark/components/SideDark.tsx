import PageBreadcrumb from '@/components/PageBreadcrumb';
import { useLayoutContext } from '@/context/useLayoutContext';
import { useEffect } from 'react';

const SideDark = () => {
  const { updateSettings } = useLayoutContext();
  useEffect(() => {
    updateSettings({
      sidenav: {
        size: 'default',
        color: 'dark',
      },
    });
  }, []);

  return (
    <>
      <PageBreadcrumb subtitle="Layouts" title="Sidenav Dark" />
      <div className="card h-40"></div>
    </>
  );
};

export default SideDark;
