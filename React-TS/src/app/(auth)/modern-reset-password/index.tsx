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
import { Link } from 'react-router';

const Index = () => {
  return (
    <>
      <PageMeta title="Reset Password" />
      <div className="relative flex flex-row w-full overflow-hidden bg-gradient-to-r from-blue-900 h-screen to-blue-800 dark:to-blue-900 dark:from-blue-950">
        <div className="absolute inset-0 opacity-20">
          <img src={modern} alt="" />
        </div>

        <div className="mx-4 m-4 w-160 py-14 px-10 bg-card flex justify-center rounded-md text-center relative z-10">
          <div className="flex flex-col h-full">
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

            <div className="my-auto">
              <div className="mt-8">
                <h4 className="mb-2 text-primary text-xl font-semibold">Forgot Password?</h4>
                <p className="text-base mb-8 text-default-500">Reset your Tailwick password</p>
              </div>

              <div className="p-3 mb-6 text-warning rounded-md bg-warning/15">
                Provide your email address, and instructions will be sent to you
              </div>

              <form action="/index" className="mx-auto">
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
                    <Link to="/modern-login" className="text-primary underline">
                      {' '}
                      Click here{' '}
                    </Link>
                  </p>
                </div>
              </form>
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
