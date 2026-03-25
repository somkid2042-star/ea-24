import authBgDark from '@/assets/images/auth-bg-dark.jpg';
import authBg from '@/assets/images/auth-bg.jpg';
import ArabianFlag from '@/assets/images/flags/arebian.svg';
import FrenchFlag from '@/assets/images/flags/french.jpg';
import GermanyFlag from '@/assets/images/flags/germany.jpg';
import ItalyFlag from '@/assets/images/flags/italy.jpg';
import JapaneseFlag from '@/assets/images/flags/japanese.svg';
import RussiaFlag from '@/assets/images/flags/russia.jpg';
import SpainFlag from '@/assets/images/flags/spain.jpg';
import UsFlag from '@/assets/images/flags/us.jpg';
import LogoDark from '@/assets/images/logo-dark.png';
import LogoLight from '@/assets/images/logo-light.png';
import Boxed from '@/assets/images/boxed.png';
import IconifyIcon from '@/components/client-wrapper/IconifyIcon';
import { Link } from 'react-router';
import PageMeta from '@/components/PageMeta';
const Index = () => {
  return (
    <>
      <PageMeta title="Login" />
      <div className="h-screen w-full flex justify-center items-center">
        <div className="absolute inset-0">
          <div className="block dark:hidden h-full w-full relative">
            <img src={authBg} alt="background" className="object-cover" />
          </div>
          <div className="hidden dark:block h-full w-full relative">
            <img src={authBgDark} alt="background dark" className="object-cover" width={111} />
          </div>
        </div>
        <div className="relative dark:bg-[url('../images/auth-bg-dark.jpg')]">
          <div className="bg-card/70 rounded-lg w-2/3 mx-auto">
            <div className="grid lg:grid-cols-12 grid-cols-1 items-center gap-0">
              <div className="lg:col-span-5">
                <div className="text-center px-10 py-12">
                  <h4 className="mb-3 text-xl font-semibold text-purple-500">Welcome Back !</h4>
                  <p className="text-base text-default-500">Sign in to continue to Tailwick.</p>

                  <form action="/index" className="text-left w-full mt-10">
                    <div className="mb-4">
                      <label
                        htmlFor="Username"
                        className="block font-medium text-default-900 text-sm mb-2"
                      >
                        Username/ Email ID
                      </label>
                      <input
                        type="text"
                        id="Username"
                        className="form-input"
                        placeholder="Enter Username or email"
                      />
                    </div>

                    <div className="mb-4">
                      <Link
                        to="/boxed-reset-password"
                        className="text-primary font-medium text-sm mb-2 float-end"
                      >
                        Forgot Password ?
                      </Link>
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

                    <div className="flex items-center gap-2">
                      <input id="checkbox-1" type="checkbox" className="form-checkbox" />
                      <label htmlFor="checkbox-1" className="text-default-900 text-sm font-medium">
                        Remember Me
                      </label>
                    </div>

                    <div className="mt-10 text-center">
                      <button type="button" className="btn bg-primary text-white w-full">
                        Sign In
                      </button>
                    </div>

                    <div className="my-9 relative text-center before:absolute before:top-2.5 before:left-0 before:border-t before:border-default-200 before:w-full before:h-0.5 before:right-0 before:-z-0">
                      <h4 className="relative z-1 py-0.5 px-2 inline-block font-medium bg-card rounded-md">
                        Sign In with
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
                        Don't have an account ?{' '}
                        <Link
                          to="/boxed-register"
                          className="font-semibold underline hover:text-primary transition duration-200"
                        >
                          SignUp
                        </Link>
                      </p>
                    </div>
                  </form>
                </div>
              </div>

              <div className="lg:col-span-7 bg-card/60 mx-2 my-2 shadow-[0_14px_15px_-3px_#f1f5f9,0_4px_6px_-4px_#f1f5f9] dark:shadow-none rounded-lg">
                <div className="pt-10 px-10 h-full">
                  <div className="flex items-center justify-between gap-3">
                    <Link to="/index">
                      <img
                        src={LogoDark}
                        alt="logo dark"
                        className="h-6 block dark:hidden"
                        width={111}
                      />
                      <img
                        src={LogoLight}
                        alt="logo light"
                        className="h-6 hidden dark:block"
                        width={111}
                      />
                    </Link>

                    <div className="hs-dropdown [--placement:bottom-right] relative inline-flex">
                      <button
                        type="button"
                        className="hs-dropdown-toggle py-2 px-4 bg-transparent border border-default-200 text-default-600 hover:border-primary rounded-md hover:text-primary font-medium text-sm gap-2 flex items-center"
                      >
                        <img src={UsFlag} alt="US Flag" className="size-5 rounded-full" />
                        English
                      </button>

                      <div className="hs-dropdown-menu">
                        <Link
                          to=""
                          className="flex items-center gap-x-3.5 py-1.5 font-medium px-3 text-default-600 hover:bg-default-150 rounded"
                        >
                          <img src={UsFlag} alt="US Flag" className="size-4 rounded-full" />
                          English
                        </Link>
                        <Link
                          to=""
                          className="flex items-center gap-x-3.5 py-1.5 font-medium px-3 text-default-600 hover:bg-default-150 rounded"
                        >
                          <img src={SpainFlag} alt="Spain Flag" className="size-4 rounded-full" />
                          Spanish
                        </Link>
                        <Link
                          to=""
                          className="flex items-center gap-x-3.5 py-1.5 font-medium px-3 text-default-600 hover:bg-default-150 rounded"
                        >
                          <img
                            src={GermanyFlag}
                            alt="Germany Flag"
                            className="size-4 rounded-full"
                          />
                          German
                        </Link>
                        <Link
                          to=""
                          className="flex items-center gap-x-3.5 py-1.5 font-medium px-3 text-default-600 hover:bg-default-150 rounded"
                        >
                          <img src={FrenchFlag} alt="French Flag" className="size-4 rounded-full" />
                          French
                        </Link>
                        <Link
                          to=""
                          className="flex items-center gap-x-3.5 py-1.5 font-medium px-3 text-default-600 hover:bg-default-150 rounded"
                        >
                          <img
                            src={JapaneseFlag}
                            alt="Japanese Flag"
                            className="size-4 rounded-full"
                          />
                          Japanese
                        </Link>
                        <Link
                          to=""
                          className="flex items-center gap-x-3.5 py-1.5 font-medium px-3 text-default-600 hover:bg-default-150 rounded"
                        >
                          <img src={ItalyFlag} alt="Italy Flag" className="size-4 rounded-full" />
                          Italian
                        </Link>
                        <Link
                          to=""
                          className="flex items-center gap-x-3.5 py-1.5 font-medium px-3 text-default-600 hover:bg-default-150 rounded"
                        >
                          <img src={RussiaFlag} alt="Russia Flag" className="size-4 rounded-full" />
                          Russian
                        </Link>
                        <Link
                          to=""
                          className="flex items-center gap-x-3.5 py-1.5 font-medium px-3 text-default-600 hover:bg-default-150 rounded"
                        >
                          <img
                            src={ArabianFlag}
                            alt="Arabic Flag"
                            className="size-4 rounded-full"
                          />
                          Arabic
                        </Link>
                      </div>
                    </div>
                  </div>

                  <div className="mt-auto">
                    <img src={Boxed} alt="Boxed Illustration" />
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </>
  );
};

export default Index;
