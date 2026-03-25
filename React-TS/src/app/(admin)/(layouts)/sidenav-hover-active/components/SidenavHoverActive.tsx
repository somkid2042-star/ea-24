import PageBreadcrumb from '@/components/PageBreadcrumb';
import { useLayoutContext } from '@/context/useLayoutContext';
import { useEffect } from 'react';

const SidenavHoverActive = () => {
  const { updateSettings } = useLayoutContext();

  useEffect(() => {
    updateSettings({
      sidenav: {
        size: 'hover-active',
        color: 'light',
      },
    });
  }, [updateSettings]);

  return (
    <>
      <PageBreadcrumb subtitle="Layouts" title="Hover Active Sidenav" />
      <div className="card h-40"></div>
    </>
  );
};

export default SidenavHoverActive;
