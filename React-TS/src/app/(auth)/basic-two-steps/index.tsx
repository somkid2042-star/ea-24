import logoDark from '@/assets/images/logo-dark.png';
import logoLight from '@/assets/images/logo-light.png';
import PageMeta from '@/components/PageMeta';
import { Link } from 'react-router';

const Index = () => {
  return (
    <>
      <PageMeta title="Two Steps" />
      <div className="relative min-h-screen w-full flex justify-center items-center py-16 md:py-10">
        <div className="card md:w-lg w-screen z-10">
          <div className="text-center px-10 py-12">
            <Link to="/index" className="flex justify-center">
              <img src={logoDark} alt="logo dark" className="h-6 flex dark:hidden" width={111} />
              <img src={logoLight} alt="logo light" className="h-6 hidden dark:flex" width={111} />
            </Link>

            <div className="mt-8">
              <h4 className="mb-4 text-primary text-xl font-semibold">Verify Email</h4>
              <p className="text-base/normal mb-8 text-default-500">
                Please enter the 4 digit code sent to tailwick@themesdesign.in
              </p>
            </div>

            <form action="index" className="mt-">
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

              <div className="mt-6">
                <button type="submit" className="btn text-white bg-primary w-full">
                  Confirm
                </button>
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
