import authBgDark from '@/assets/images/auth-bg-dark.jpg';
import authBg from '@/assets/images/auth-bg.jpg';
import logoDark from '@/assets/images/logo-dark.png';
import logoLight from '@/assets/images/logo-light.png';
import IconifyIcon from '@/components/client-wrapper/IconifyIcon';
import PageMeta from '@/components/PageMeta';
import { Link } from 'react-router';

const Index = () => {
  return (
    <>
      <PageMeta title="Register" />
      <div className="relative h-screen w-full flex justify-center items-center">
        <div className="absolute inset-0">
          <div className="block dark:hidden h-full w-full relative">
            <img src={authBg} alt="background" className="object-cover" />
          </div>
          <div className="hidden dark:block h-full w-full relative">
            <img src={authBgDark} alt="background dark" className="object-cover" />
          </div>
        </div>

        <div className="relative z-10 bg-card/70 rounded-lg w-lg">
          <div className="text-center px-10 py-12">
            <Link to="/index" className="flex justify-center">
              <div className="h-6 w-auto relative flex dark:hidden">
                <img src={logoDark} alt="logo dark" className="object-contain" />
              </div>
              <div className="h-6 w-auto relative hidden dark:flex">
                <img src={logoLight} alt="logo light" className="object-contain" />
              </div>
            </Link>

            <div className="mt-8 text-center">
              <h4 className="mb-2.5 text-xl font-semibold text-purple-500">Welcome Back !</h4>
              <p className="text-base text-default-500">Sign in to continue to Tailwick.</p>
            </div>

            <form action="/index" className="text-left w-full mt-10">
              <div className="mb-4">
                <label htmlFor="email" className="block font-medium text-default-900 text-sm mb-2">
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
                  className="block font-medium text-default-900 text-sm mb-2"
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
                  className="block font-medium text-default-900 text-sm mb-2"
                >
                  Password
                </label>
                <input
                  type="password"
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
                <button type="button" className="btn bg-primary text-white w-full">
                  Sign In
                </button>
              </div>

              <div className="my-9 relative text-center before:absolute before:top-2.5 before:left-0 before:border-t before:border-t-default-200 before:w-full before:h-0.5 before:right-0 before:-z-0">
                <h4 className="relative z-1 py-0.5 px-2 inline-block font-medium bg-card rounded-md">
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

              <div className="mt-10 text-center">
                <p className="text-base text-default-500">
                  Already have an account ?{' '}
                  <Link
                    to="/cover-login"
                    className="font-semibold underline hover:text-primary transition duration-200"
                  >
                    Login
                  </Link>
                </p>
              </div>
            </form>
          </div>
        </div>
      </div>
    </>
  );
};

export default Index;
