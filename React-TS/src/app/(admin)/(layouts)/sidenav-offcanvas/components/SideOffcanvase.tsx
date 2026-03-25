import PageBreadcrumb from '@/components/PageBreadcrumb';
import { useLayoutContext } from '@/context/useLayoutContext';
import { useEffect } from 'react';

const SideOffcanvase = () => {
  const { updateSettings } = useLayoutContext();
  useEffect(() => {
    updateSettings({
      sidenav: {
        size: 'offcanvas',
        color: 'light',
      },
    });
  }, []);
  return (
    <>
      <PageBreadcrumb subtitle="Layouts" title="Offcanvas Sidenav" />
      <div className="card h-40"></div>
    </>
  );
};

export default SideOffcanvase;
