import logoDark from '@/assets/images/logo-dark.png';
import logoLight from '@/assets/images/logo-light.png';
import IconifyIcon from '@/components/client-wrapper/IconifyIcon';
import PageMeta from '@/components/PageMeta';
import { Link } from 'react-router';

const Index = () => {
  return (
    <>
      <PageMeta title="Logged Out" />
      <div className="relative min-h-screen w-full flex justify-center items-center py-16 md:py-10">
        <div className="card md:w-lg w-screen z-10">
          <div className="text-center px-10 py-12">
            <Link to="/index" className="flex justify-center">
              <img src={logoDark} alt="logo dark" className="h-6 flex dark:hidden" width={111} />
              <img src={logoLight} alt="logo light" className="h-6 hidden dark:flex" width={111} />
            </Link>

            <div className="mt-8 text-center">
              <h4 className="mb-2.5 text-xl font-semibold text-primary">
                Create your free account
              </h4>
              <p className="text-base text-default-500">Get your free Tailwick account now</p>
            </div>

            <form action="/index" className="text-left w-full mt-10">
              <div className="mb-4">
                <label htmlFor="email" className="block  font-medium text-default-900 text-sm mb-2">
                  Enter email
                </label>
                <input
                  type="text"
                  id="email"
                  className="form-input"
                  placeholder="Enter Username or email"
                />
              </div>

              <div className="mb-4">
                <label
                  htmlFor="Username"
                  className="block  font-medium text-default-900 text-sm mb-2"
                >
                  Username
                </label>
                <input
                  type="text"
                  id="Username"
                  className="form-input"
                  placeholder="Enter Username"
                />
              </div>

              <div className="mb-4">
                <label
                  htmlFor="Password"
                  className="block  font-medium text-default-900 text-sm mb-2"
                >
                  Password
                </label>
                <input
                  type="text"
                  id="Password"
                  className="form-input"
                  placeholder="Enter Password"
                />
              </div>

              <p className="italic text-sm font-medium text-default-500">
                By registering you agree to the Tailwick{' '}
                <Link to="#" className="underline">
                  Terms of Use
                </Link>
              </p>

              <div className="mt-10 text-center">
                <button type="submit" className="btn bg-primary text-white w-full">
                  Sign Up
                </button>
              </div>

              <div className="my-9 relative text-center  before:absolute before:top-2.5 before:left-0 before:border-t before:border-t-default-200 before:w-full before:h-0.5 before:right-0 before:-z-0">
                <h4 className="relative z-1 py-0.5 px-2 inline-block font-medium bg-card text-default-600">
                  Create Account with
                </h4>
              </div>

              <div className="flex w-full justify-center items-center gap-2">
                <Link
                  to="#"
                  className="btn border border-default-200 flex-grow hover:bg-default-150 shadow-sm hover:text-default-800"
                >
                  <IconifyIcon icon={'logos:google-icon'} />
                  Use Google
                </Link>

                <Link
                  to="#"
                  className="btn border border-default-200 flex-grow hover:bg-default-150 shadow-sm hover:text-default-800"
                >
                  <IconifyIcon icon={'logos:apple'} className="text-mono" />
                  Use Apple
                </Link>
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
            <rect width="100%" height="100%" stroke-width="0" fill="url(#authPattern)"></rect>
          </svg>
        </div>
      </div>
    </>
  );
};

export default Index;
