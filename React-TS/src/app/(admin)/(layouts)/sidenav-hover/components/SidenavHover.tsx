import PageBreadcrumb from '@/components/PageBreadcrumb';
import { useLayoutContext } from '@/context/useLayoutContext';
import { useEffect } from 'react';

const SidenavHover = () => {
  const { updateSettings } = useLayoutContext();
  useEffect(() => {
    updateSettings({
      sidenav: {
        size: 'hover',
        color: 'light',
      },
    });
  }, [updateSettings]);

  return (
    <>
      <PageBreadcrumb subtitle="Layouts" title="Hover View Sidenav" />
      <div className="card h-40"></div>
    </>
  );
};

export default SidenavHover;
