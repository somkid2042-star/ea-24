import authBgDark from '@/assets/images/auth-bg-dark.jpg';
import authBg from '@/assets/images/auth-bg.jpg';
import logoDark from '@/assets/images/logo-dark.png';
import logoLight from '@/assets/images/logo-light.png';
import PageMeta from '@/components/PageMeta';
import { Link } from 'react-router';

const Index = () => {
  return (
    <>
      <PageMeta title="Create Password" />
      <div className="h-screen w-full flex justify-center items-center">
        <div className="absolute inset-0">
          <div className="block dark:hidden h-full w-full relative">
            <img src={authBg} alt="background" className="object-cover" />
          </div>
          <div className="hidden dark:block h-full w-full relative">
            <img src={authBgDark} alt="background dark" className="object-cover" />
          </div>
        </div>
        <div className="relative">
          <div className="bg-default-50 rounded-lg w-lg relative">
            <div className="text-center px-10 py-12">
              <Link to="/index" className="flex justify-center">
                <div className="h-6 w-auto relative block dark:hidden">
                  <img src={logoDark} alt="logo dark" className="object-contain" width={111} />
                </div>
                <div className="h-6 w-auto relative hidden dark:block">
                  <img src={logoLight} alt="logo light" width={111} className="object-contain" />
                </div>
              </Link>
              <div className="mt-8">
                <h4 className="mb-2 text-primary text-xl font-semibold">Set a New Password</h4>
                <p className="text-base mb-8 text-default-500">
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
                    <Link to="/cover-login" className="text-primary underline">
                      {' '}
                      Click here{' '}
                    </Link>
                  </p>
                </div>
              </form>
            </div>
          </div>
        </div>
      </div>
    </>
  );
};

export default Index;
