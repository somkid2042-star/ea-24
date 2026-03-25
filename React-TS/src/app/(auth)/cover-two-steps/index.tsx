import authBgDark from '@/assets/images/auth-bg-dark.jpg';
import authBg from '@/assets/images/auth-bg.jpg';
import logoDark from '@/assets/images/logo-dark.png';
import logoLight from '@/assets/images/logo-light.png';
import PageMeta from '@/components/PageMeta';
import { Link } from 'react-router';

const Index = () => {
  return (
    <>
      <PageMeta title="Two Steps" />
      <div className=" h-screen w-full flex justify-center items-center">
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
                <h4 className="mb-2 text-primary text-xl font-semibold">Verify Email</h4>
                <p className="text-base mb-8 text-default-500">
                  Please enter the 4 digit code sent to tailwick@themesdesign.in
                </p>
              </div>

              <form action="/index">
                <div className="grid grid-cols-4 gap-2">
                  <input
                    type="text"
                    className="form-input text-center"
                    placeholder="•"
                    maxLength={1}
                  />
                  <input
                    type="text"
                    className="form-input text-center"
                    placeholder="•"
                    maxLength={1}
                  />
                  <input
                    type="text"
                    className="form-input text-center"
                    placeholder="•"
                    maxLength={1}
                  />
                  <input
                    type="text"
                    className="form-input text-center"
                    placeholder="•"
                    maxLength={1}
                  />
                </div>

                <div className="mt-10">
                  <button type="button" className="btn bg-primary text-white w-full">
                    Confirm
                  </button>
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
