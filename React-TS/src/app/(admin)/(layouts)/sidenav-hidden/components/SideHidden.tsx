import PageBreadcrumb from '@/components/PageBreadcrumb';
import { useLayoutContext } from '@/context/useLayoutContext';
import { useEffect } from 'react';

const SideHidden = () => {
  const { updateSettings } = useLayoutContext();
  useEffect(() => {
    updateSettings({
      sidenav: {
        size: 'hidden',
        color: 'light',
      },
    });
  }, []);
  return (
    <>
      <PageBreadcrumb subtitle="Layouts" title="Hidden Sidenav" />
      <div className="card h-40"></div>
    </>
  );
};

export default SideHidden;
