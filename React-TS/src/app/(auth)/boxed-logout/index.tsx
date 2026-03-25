import authBgDark from '@/assets/images/auth-bg-dark.jpg';
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
import PageMeta from '@/components/PageMeta';
import { LuLogOut } from 'react-icons/lu';
import { Link } from 'react-router';

const Index = () => {
  return (
    <>
      <PageMeta title="Logout" />
      <div className="h-screen w-full flex justify-center items-center">
        <div className="absolute inset-0">
          <div className="block dark:hidden h-full w-full relative">
            <img src={AuthBg} alt="background" className="object-cover" />
          </div>
          <div className="hidden dark:block h-full w-full relative">
            <img src={authBgDark} alt="background dark" className="object-cover" width={111} />
          </div>
        </div>
        <div className="relative">
          <div className="bg-card/70 rounded-lg w-2/3 mx-auto">
            <div className="grid lg:grid-cols-12 grid-cols-1 items-center gap-0">
              <div className="lg:col-span-5">
                <div className="text-center px-10 py-12">
                  <div className="mt-8 text-center">
                    <div className="mb-4">
                      <LuLogOut className="size-6 text-purple-500 fill-purple-100 mx-auto" />
                    </div>

                    <h4 className="mb-2 text-primary text-xl font-semibold">You are Logged Out</h4>
                    <p className="mb-8 text-base text-default-500">
                      Thank you for using tailwick admin template
                    </p>
                  </div>
                  <Link to="/oxed-login">
                    <button className="btn bg-primary text-white w-full">Sign In</button>
                  </Link>
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
