import AuthBg from '@/assets/images/auth-bg.jpg';
import Boxed from '@/assets/images/boxed.png';
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
import IconifyIcon from '@/components/client-wrapper/IconifyIcon';
import PageMeta from '@/components/PageMeta';
import { LuMail, LuSmartphone } from 'react-icons/lu';
import { Link } from 'react-router';

const Index = () => {
  return (
    <>
      <PageMeta title="Register" />
      <div
        className="bg-cover bg-no-repeat min-h-screen flex justify-center items-center"
        style={{ backgroundImage: `url(${AuthBg})` }}
      >
        <div className="relative">
          <div className="bg-card/70 rounded-lg w-2/3 mx-auto">
            <div className="grid lg:grid-cols-12 grid-cols-1 items-center gap-0">
              <div className="lg:col-span-5">
                <div>
                  <div
                    className="flex justify-center gap-x-3"
                    role="tablist"
                    aria-orientation="horizontal"
                  >
                    <button
                      type="button"
                      className="hs-tab-active:bg-primary hs-tab-active:text-white text-sm py-2.5 px-12 text-default-500 rounded-md bg-default-200 font-medium gap-2 flex items-center transition-all duration-300 active"
                      id="tabs-with-underline-item-1"
                      aria-selected="true"
                      data-hs-tab="#tabsForEmail"
                      aria-controls="tabsForEmail"
                      role="tab"
                    >
                      <LuMail className="size-4" />
                      Email
                    </button>

                    <button
                      type="button"
                      className="hs-tab-active:bg-primary hs-tab-active:text-white text-sm py-2.5 px-12 text-default-500 rounded-md bg-default-200 font-medium gap-2 flex items-center transition-all duration-300"
                      id="tabs-with-underline-item-2"
                      aria-selected="false"
                      data-hs-tab="#tabsForPhone"
                      aria-controls="tabsForPhone"
                      role="tab"
                    >
                      <LuSmartphone className="size-4" />
                      Phone
                    </button>
                  </div>

                  <div className="mt-10 w-110 mx-auto">
                    <div id="tabsForEmail" role="tabpanel">
                      <form className="text-left w-full mt-10">
                        <div className="mb-4">
                          <label
                            htmlFor="email"
                            className="block font-medium text-default-900 text-sm mb-2"
                          >
                            Email ID
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

                        <div className="my-9 relative text-center before:absolute before:top-2.5 before:left-0 before:border-t before:border-default-200 before:w-full before:h-0.5 before:right-0 before:-z-0">
                          <h4 className="relative z-1 py-0.5 px-2 inline-block font-medium bg-card rounded-md">
                            Create account with
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
                            Already have an account?{' '}
                            <Link
                              to="/boxed-login"
                              className="font-semibold underline hover:text-primary transition duration-200"
                            >
                              Login
                            </Link>
                          </p>
                        </div>
                      </form>
                    </div>

                    <div
                      id="tabsForPhone"
                      className="hidden"
                      role="tabpanel"
                      aria-labelledby="tabs-with-underline-item-2"
                    >
                      <form className="text-left w-full mt-10">
                        <div className="mb-4">
                          <label
                            htmlFor="phone"
                            className="block font-medium text-default-900 text-sm mb-2"
                          >
                            Phone Number
                          </label>
                          <input
                            type="text"
                            id="phone"
                            className="form-input"
                            placeholder="Enter phone"
                          />
                        </div>

                        <div className="mb-4">
                          <label
                            htmlFor="UsernamePhone"
                            className="block font-medium text-default-900 text-sm mb-2"
                          >
                            Username
                          </label>
                          <input
                            type="text"
                            id="UsernamePhone"
                            className="form-input"
                            placeholder="Enter Username"
                          />
                        </div>

                        <div className="mb-4">
                          <label
                            htmlFor="PasswordPhone"
                            className="block font-medium text-default-900 text-sm mb-2"
                          >
                            Password
                          </label>
                          <input
                            type="password"
                            id="PasswordPhone"
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

                        <div className="my-9 relative text-center before:absolute before:top-2.5 before:left-0 before:border-t before:border-default-200 before:w-full before:h-0.5 before:right-0 before:-z-0">
                          <h4 className="relative z-1 py-0.5 px-2 inline-block font-medium bg-card rounded-md">
                            Create account with
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
                            Already have an account?{' '}
                            <Link
                              to="/basic-login"
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
                        <a className="flex items-center gap-x-3.5 py-1.5 font-medium px-3 text-default-600 hover:bg-default-150 rounded">
                          <img src={UsFlag} alt="US Flag" className="size-4 rounded-full" />
                          English
                        </a>
                        <a className="flex items-center gap-x-3.5 py-1.5 font-medium px-3 text-default-600 hover:bg-default-150 rounded">
                          <img src={SpainFlag} alt="Spain" className="size-4 rounded-full" />
                          Spanish
                        </a>
                        <a className="flex items-center gap-x-3.5 py-1.5 font-medium px-3 text-default-600 hover:bg-default-150 rounded">
                          <img src={GermanyFlag} alt="Germany" className="size-4 rounded-full" />
                          German
                        </a>
                        <a className="flex items-center gap-x-3.5 py-1.5 font-medium px-3 text-default-600 hover:bg-default-150 rounded">
                          <img src={FrenchFlag} alt="France" className="size-4 rounded-full" />
                          French
                        </a>
                        <a className="flex items-center gap-x-3.5 py-1.5 font-medium px-3 text-default-600 hover:bg-default-150 rounded">
                          <img src={JapaneseFlag} alt="Japan" className="size-4 rounded-full" />
                          Japanese
                        </a>
                        <a className="flex items-center gap-x-3.5 py-1.5 font-medium px-3 text-default-600 hover:bg-default-150 rounded">
                          <img src={ItalyFlag} alt="Italy" className="size-4 rounded-full" />
                          Italian
                        </a>
                        <a className="flex items-center gap-x-3.5 py-1.5 font-medium px-3 text-default-600 hover:bg-default-150 rounded">
                          <img src={RussiaFlag} alt="Russia" className="size-4 rounded-full" />
                          Russian
                        </a>
                        <a className="flex items-center gap-x-3.5 py-1.5 font-medium px-3 text-default-600 hover:bg-default-150 rounded">
                          <img src={ArabianFlag} alt="Arabic" className="size-4 rounded-full" />
                          Arabic
                        </a>
                      </div>
                    </div>
                  </div>

                  <div className="mt-auto">
                    <img src={Boxed} alt="Illustration" />
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
