import authBgDark from '@/assets/images/auth-bg-dark.jpg';
import authBg from '@/assets/images/auth-bg.jpg';
import logoDark from '@/assets/images/logo-dark.png';
import logoLight from '@/assets/images/logo-light.png';
import maintenance from '@/assets/images/maintenance.png';
import PageMeta from '@/components/PageMeta';
import { LuHouse } from 'react-icons/lu';
import { Link } from 'react-router';

const Index = () => {
  return (
    <>
      <PageMeta title="Maintenance" />
      <div className="relative h-screen w-full flex justify-center items-center">
        <div
          className="absolute inset-0 bg-cover bg-no-repeat dark:hidden"
          style={{ backgroundImage: `url(${authBg})` }}
        />

        <div
          className="absolute inset-0 bg-cover bg-no-repeat hidden dark:block"
          style={{ backgroundImage: `url(${authBgDark})` }}
        />

        <div className="relative z-10">
          <div className="bg-default-100 rounded-lg w-lg relative">
            <div className="text-center px-10 py-12">
              <Link to="/index" className="flex justify-center">
                <img src={logoDark} alt="logo dark" className="h-6 block dark:hidden" width={111} />
                <img
                  src={logoLight}
                  alt="logo light"
                  className="h-6 hidden dark:block"
                  width={111}
                />
              </Link>

              <div className="mt-10">
                <img src={maintenance} alt="" className="h-72 mx-auto" width={373} />
              </div>

              <div className="mt-8 text-center">
                <h4 className="mb-2 text-purple-500 text-xl font-semibold dark:text-white">
                  Currently in Maintenance Mode !!!
                </h4>
                <p className="mb-6 text-base text-default-500">
                  Website is Under Construction. Please check back later!
                </p>
                <Link to="/index">
                  <button type="button" className="btn bg-primary text-white">
                    <LuHouse className="size-3.5" />
                    Back to Home
                  </button>
                </Link>
              </div>
            </div>
          </div>
        </div>
      </div>
    </>
  );
};

export default Index;
