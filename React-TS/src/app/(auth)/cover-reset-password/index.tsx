import authBgDark from '@/assets/images/auth-bg-dark.jpg';
import authBg from '@/assets/images/auth-bg.jpg';
import logoDark from '@/assets/images/logo-dark.png';
import logoLight from '@/assets/images/logo-light.png';
import PageMeta from '@/components/PageMeta';
import { Link } from 'react-router';

const Index = () => {
  return (
    <>
      <PageMeta title="Reset Password" />
      <div className="h-screen w-full flex justify-center items-center">
        <div className="absolute inset-0">
          <div className="block dark:hidden h-full w-full relative">
            <img src={authBg} alt="background" className="object-cover" />
          </div>
          <div className="hidden dark:block h-full w-full relative">
            <img src={authBgDark} alt="background dark" className="object-cover" />
          </div>
        </div>{' '}
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
                <h4 className="mb-2 text-primary text-xl font-semibold">Forgot Password?</h4>
                <p className="text-base mb-8 text-default-500">Reset your Tailwick password</p>
              </div>

              <div className="p-3 mb-6 text-warning rounded-md bg-warning/15">
                Provide your email address, and instructions will be sent to you
              </div>

              <form action="/index">
                <div className="text-start">
                  <label
                    htmlFor="Email"
                    className="inline-block mb-2 text-sm text-default-800 font-medium"
                  >
                    Email
                  </label>
                  <input type="text" id="Email" className="form-input" placeholder="Enter Email" />
                </div>

                <div className="mt-8">
                  <button type="button" className="btn bg-primary text-white w-full">
                    Send Reset Link
                  </button>
                </div>

                <div className="mt-4 text-center">
                  <p className="text-base text-default-800">
                    Wait, I remember my password...{' '}
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
