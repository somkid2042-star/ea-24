import type { ReactNode } from 'react';
import Footer from '@/components/layouts/Footer';
import Sidebar from '@/components/layouts/SideNav';
import Topbar from '@/components/layouts/topbar';
import Customizer from '@/components/layouts/customizer';

const Layout = ({ children }: { children: ReactNode }) => {
  return (
    <>
      <div className="wrapper">
        <Sidebar />
        <div className="page-content">
          <Topbar />
          {children}
          <Footer />
        </div>
      </div>
      <Customizer />
    </>
  );
};

export default Layout;
