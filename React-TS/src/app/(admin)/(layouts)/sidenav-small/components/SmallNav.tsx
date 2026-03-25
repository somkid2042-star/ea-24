import PageBreadcrumb from '@/components/PageBreadcrumb';
import { useLayoutContext } from '@/context/useLayoutContext';
import { useEffect } from 'react';

const SmallNav = () => {
  const { updateSettings } = useLayoutContext();

  useEffect(() => {
    updateSettings({
      sidenav: {
        size: 'sm',
        color: 'light',
      },
    });
  }, [updateSettings]);

  return (
    <>
      <PageBreadcrumb subtitle="Layouts" title="Small Sidenav" />
      <div className="card h-40"></div>
    </>
  );
};

export default SmallNav;
