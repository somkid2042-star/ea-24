import PageBreadcrumb from '@/components/PageBreadcrumb';
import { useLayoutContext } from '@/context/useLayoutContext';
import { useEffect } from 'react';

const RtlMode = () => {
  const { updateSettings } = useLayoutContext();
  useEffect(() => {
    updateSettings({
      dir: 'rtl',
      sidenav: {
        size: 'default',
        color: 'light',
      },
    });
  }, []);

  return (
    <>
      <PageBreadcrumb subtitle="Layouts" title="RTL Mode" />
      <div className="card h-40"></div>
    </>
  );
};

export default RtlMode;
