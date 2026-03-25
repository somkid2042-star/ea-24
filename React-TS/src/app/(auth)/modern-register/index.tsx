import modernImg from '@/assets/images/auth-modern.png';
import ArabianFlag from '@/assets/images/flags/arebian.svg';
import FrenchFlag from '@/assets/images/flags/french.jpg';
import GermanyFlag from '@/assets/images/flags/germany.jpg';
import ItalyFlag from '@/assets/images/flags/italy.jpg';
import JapaneseFlag from '@/assets/images/flags/japanese.svg';
import RussiaFlag from '@/assets/images/flags/russia.jpg';
import SpainFlag from '@/assets/images/flags/spain.jpg';
import UsFlag from '@/assets/images/flags/us.jpg';
import LogoLight from '@/assets/images/logo-light.png';
import modern from '@/assets/images/modern.svg';
import IconifyIcon from '@/components/client-wrapper/IconifyIcon';
import PageMeta from '@/components/PageMeta';
import { LuMail, LuSmartphone } from 'react-icons/lu';
import { Link } from 'react-router';

const Index = () => {
  return (
    <>
      <PageMeta title="Register" />
      <div className="relative flex flex-row w-full overflow-hidden bg-gradient-to-r from-blue-900 h-screen to-blue-800 dark:to-blue-900 dark:from-blue-950">
        <div className="absolute inset-0 opacity-20">
          <img src={modern} alt="" />
        </div>

        <div className="mx-4 m-4 w-160 py-14 px-10 bg-card flex justify-center rounded-md text-center relative z-10">
          <div className="flex flex-col h-full w-full">
            <div className="flex justify-end">
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

            <div className="my-21">
              <div className="mt-10">
                <div
                  className="flex justify-center gap-x-3"
                  aria-label="Tabs"
                  role="tablist"
                  aria-orientation="horizontal"
                >
                  <button
                    type="button"
                    className="hs-tab-active:bg-primary hs-tab-active:text-white text-sm py-2.5 px-12 text-default-500 rounded-md bg-default-100 font-medium gap-2 flex items-center transition-all duration-300 active"
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
                    className="hs-tab-active:bg-primary hs-tab-active:text-white text-sm py-2.5 px-12 text-default-500 rounded-md bg-default-100 font-medium gap-2 flex items-center transition-all duration-300"
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

                <div className="mt-10 w-100 mx-auto">
                  <div
                    id="tabsForEmail"
                    role="tabpanel"
                    aria-labelledby="tabs-with-underline-item-1"
                  >
                    <form action="/index" className="text-left w-full mt-10">
                      <div className="mb-4 ">
                        <label
                          htmlFor="Username"
                          className="block  font-medium text-default-900 text-sm mb-2"
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
                        <Link
                          to="/modern-reset-password"
                          className="text-primary font-medium text-sm mb-2 float-end"
                        >
                          Forgot Password ?
                        </Link>
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

                      <div className="flex items-center gap-2 mb-4">
                        <input id="checkbox-1" type="checkbox" className="form-checkbox" />
                        <label
                          className="text-default-900 text-sm font-medium"
                          htmlFor="checkbox-1"
                        >
                          Remember Me
                        </label>
                      </div>

                      <div className="mt-10 text-center">
                        <button type="button" className="btn bg-primary text-white w-full">
                          Sign Up
                        </button>
                      </div>

                      <div className="my-9 relative text-center  before:absolute before:top-2.5 before:left-0 before:border-t before:border-t-default-200 before:w-full before:h-0.5 before:right-0 before:-z-0">
                        <h4 className="relative z-1 py-0.5 px-2 inline-block font-medium bg-card text-default-500 rounded-md">
                          Already have an account ?
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
                          Don't have an account ?
                          <Link
                            to="/modern-register"
                            className="font-semibold underline hover:text-primary transition duration-200"
                          >
                            {' '}
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
                    <form action="/index" className="text-left w-full mt-10">
                      <div className="mb-4">
                        <label
                          htmlFor="Phone Number"
                          className="block  font-medium text-default-900 text-sm mb-2"
                        >
                          Phone Number
                        </label>
                        <input
                          type="text"
                          id="Phone Number"
                          className="form-input"
                          placeholder="Enter Phone"
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
                        <Link
                          to="/modern-reset-password"
                          className="text-primary font-medium text-sm mb-2 float-end"
                        >
                          Forgot Password ?
                        </Link>
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

                      <div className="flex items-center gap-2 mb-4">
                        <input id="checkbox-1" type="checkbox" className="form-checkbox" />
                        <label
                          className="text-default-900 text-sm font-medium"
                          htmlFor="checkbox-1"
                        >
                          Remember Me
                        </label>
                      </div>

                      <div className="mt-10 text-center">
                        <button type="button" className="btn bg-primary text-white w-full">
                          Sign Up
                        </button>
                      </div>

                      <div className="my-9 relative text-center  before:absolute before:top-2.5 before:left-0 before:border-t before:border-t-default-200 before:w-full before:h-0.5 before:right-0 before:-z-0">
                        <h4 className="relative z-1 py-0.5 px-2 inline-block font-medium text-default-500 bg-card rounded-md">
                          Already have an account ?
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
                          Don't have an account ?
                          <Link
                            to="/modern-register"
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

            <div className="mt-5 flex justify-center">
              <span className="text-sm text-default-500 flex gap-1">
                <IconifyIcon icon="lucide:copyright" className="w-4 h-4 align-middle" />
                2025 Tailwick. Crafted with
                <IconifyIcon
                  icon="tabler:heart-filled"
                  className="w-4 h-4 text-danger align-middle"
                />
                by{' '}
                <Link
                  to="https://themesdesign.in/"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-default-800 hover:text-primary transition duration-200 underline"
                >
                  Themesdesign
                </Link>
              </span>
            </div>
          </div>
        </div>

        <div className="relative z-10 flex items-center justify-center min-h-screen px-10 py-14 grow">
          <div>
            <Link to="/index" className="index">
              <img src={LogoLight} alt="" className="h-7 mb-14 mx-auto block" width={130} />
            </Link>

            <img src={modernImg} alt="" className="mx-auto rounded-xl block object-cover w-md" />
            <div className="mt-10 text-center">
              <h3 className="mb-3 text-blue-50 text-2xl font-semibold text-center">
                Tools For Crafting Your Business's Brand Identity
              </h3>
              <p className="text-blue-300 text-base w-2xl text-center">
                Unlock the potential of our versatile branding tools, designed to empower your
                business in shaping a distinctive and impactful brand. Elevate your business's image
                and leave a lasting impression with our comprehensive branding solutions.
              </p>
            </div>
          </div>
        </div>
      </div>
    </>
  );
};

export default Index;
