import PageBreadcrumb from '@/components/PageBreadcrumb';
import { useLayoutContext } from '@/context/useLayoutContext';
import { useEffect } from 'react';

const SideCompact = () => {
  const { updateSettings } = useLayoutContext();

  useEffect(() => {
    updateSettings({
      sidenav: {
        size: 'md',
        color: 'light',
      },
    });
  }, [updateSettings]);

  return (
    <>
      <PageBreadcrumb subtitle="Layouts" title="Compact Sidenav" />
      <div className="card h-40"></div>
    </>
  );
};

export default SideCompact;
