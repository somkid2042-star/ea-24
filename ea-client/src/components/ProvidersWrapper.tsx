import React, { useEffect } from 'react';

import LayoutProvider from '@/context/useLayoutContext';
import { useLocation } from 'react-router';

const ProvidersWrapper = ({ children }: { children: React.ReactNode }) => {
  const path = useLocation();

  useEffect(() => {
    import('preline/preline').then(() => {
      if (window.HSStaticMethods) {
        window.HSStaticMethods.autoInit();
      }
    });
  }, []);

  useEffect(() => {
    setTimeout(() => {
      if (window.HSStaticMethods) {
        window.HSStaticMethods.autoInit();
      }
    }, 100);
  }, [path]);

  return (
    <>
      <LayoutProvider>{children}</LayoutProvider>
    </>
  );
};

export default ProvidersWrapper;
