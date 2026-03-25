import logoDark from '@/assets/images/logo-dark.png';
import logoLight from '@/assets/images/logo-light.png';
import PageMeta from '@/components/PageMeta';
import { Link } from 'react-router';

const Index = () => {
  return (
    <>
      <PageMeta title="Create Password" />
      <div className="relative min-h-screen w-full flex justify-center items-center py-16 md:py-10">
        <div className="card md:w-lg w-screen z-10">
          <div className="text-center px-10 py-12">
            <Link to="/index" className="flex justify-center">
              <img src={logoDark} alt="logo dark" className="h-6 flex dark:hidden" width={111} />
              <img src={logoLight} alt="logo light" className="h-6 hidden dark:flex" width={111} />
            </Link>

            <div className="mt-8">
              <h4 className="mb-2 text-primary text-xl font-semibold">Set a New Password</h4>
              <p className="text-base/normal mb-8 text-default-500">
                Your new password should be distinct from any of your prior passwords
              </p>
            </div>

            <form action="/index">
              <div className="text-start">
                <label
                  htmlFor="Email"
                  className="inline-block mb-2 text-sm text-default-800 font-medium"
                >
                  Password
                </label>
                <input type="text" id="Email" className="form-input" placeholder="Password" />
              </div>

              <div className="text-start mt-4">
                <label
                  htmlFor="Email"
                  className="inline-block mb-2 text-sm text-default-800 font-medium"
                >
                  Confirm Password
                </label>
                <input
                  type="text"
                  id="Email"
                  className="form-input"
                  placeholder="Confirm Password"
                />
              </div>

              <div className="flex items-center gap-2 mt-4">
                <input id="checkbox-1" type="checkbox" className="form-checkbox" />
                <label className="text-default-900 text-sm font-medium" htmlFor="checkbox-1">
                  Remember Me
                </label>
              </div>

              <div className="mt-8">
                <button type="button" className="btn bg-primary text-white w-full">
                  Reset Password
                </button>
              </div>
              <div className="mt-4 text-center">
                <p className="text-base text-default-800">
                  Hold on, I've got my password...{' '}
                  <Link to="/basic-login" className="text-primary underline">
                    {' '}
                    Click here{' '}
                  </Link>
                </p>
              </div>
            </form>
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
