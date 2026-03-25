import emailImg from '@/assets/images/auth-email.png';
import logoDark from '@/assets/images/logo-dark.png';
import logoLight from '@/assets/images/logo-light.png';
import PageMeta from '@/components/PageMeta';
import { Link } from 'react-router';

const Index = () => {
  return (
    <>
      <PageMeta title="Verify Email" />
      <div className="relative min-h-screen w-full flex justify-center items-center py-16 md:py-10">
        <div className="card md:w-lg w-screen z-10">
          <div className="text-center px-10 py-12">
            <Link to="/index" className="flex justify-center">
              <img src={logoDark} alt="logo dark" className="h-6 flex dark:hidden" width={111} />
              <img src={logoLight} alt="logo light" className="h-6 hidden dark:flex" width={111} />
            </Link>

            <div className="mt-8 text-center">
              <h4 className="mb-3 text-xl font-semibold text-primary">Verify Email</h4>
              <p className="text-base text-default-500 mb-4">
                Did you not receive an email? Please{' '}
                <Link to="#" className="text-primary">
                  {' '}
                  try again
                </Link>
              </p>

              <button type="button" className="btn btn-sm bg-primary text-white">
                Skip Now
              </button>

              <div className="mt-10 text-center">
                <img src={emailImg} alt="" className="block w-1/2 mx-auto" />
              </div>
            </div>
          </div>
        </div>

        <div className="absolute inset-0 overflow-hidden">
          <svg
            aria-hidden="true"
            className="absolute inset-0 size-full fill-black/2 stroke-black/5 dark:fill-white/2.5 dark:stroke-white/2.5"
          >
            <defs>
              <pattern
                id="authPattern"
                width="56"
                height="56"
                patternUnits="userSpaceOnUse"
                x="50%"
                y="16"
              >
                <path d="M.5 56V.5H72" fill="none"></path>
              </pattern>
            </defs>
            <rect width="100%" height="100%" strokeWidth="0" fill="url(#authPattern)"></rect>
          </svg>
        </div>
      </div>
    </>
  );
};

export default Index;
