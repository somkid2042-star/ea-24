import logoDark from '@/assets/images/logo-dark.png';
import logoLight from '@/assets/images/logo-light.png';
import { LuMenu, LuX } from 'react-icons/lu';
import { Link } from 'react-router';

const MobileMenu = () => {
  return (
    <>
      <button
        className="btn size-9 bg-primary text-white md:hidden"
        aria-haspopup="dialog"
        aria-expanded="false"
        aria-controls="navbarMenu"
        data-hs-overlay="#navbarMenu"
      >
        <LuMenu />
      </button>
      <div
        className="hs-overlay hs-overlay-open:translate-y-0 -translate-y-full fixed top-0 inset-x-0 transition-all duration-300 transform max-h-64 p-5 size-full  card border-b border-default-200 hidden"
        role="dialog"
        tabIndex={-1}
        aria-labelledby="navbarMenu-label"
        id="navbarMenu"
      >
        <div className="flex items-center justify-between">
          <Link to="#">
            <img src={logoDark} alt="logo dark" className="h-6 block dark:hidden" width={111} />
            <img src={logoLight} alt="logo light" className="h-6 hidden dark:block" width={111} />
          </Link>

          <button
            aria-label="Close"
            data-hs-overlay="#navbarMenu"
            className="inline-flex justify-end items-center gap-x-2 rounded-full"
          >
            <LuX className="size-4" />
          </button>
        </div>

        <div className="pt-8">
          <ul className="flex flex-col gap-y-4 lg:gap-8 md:gap-6 font-semibold  text-sm">
            <li>
              <a
                href="#home"
                className="text-secondary-default-400 hover:text-primary transition duration-300"
              >
                Home
              </a>
            </li>

            <li>
              <a
                href="#features"
                className="text-secondary-default-400 hover:text-primary transition duration-300"
              >
                Our Features
              </a>
            </li>

            <li>
              <a
                href="#about"
                className="text-secondary-default-400 hover:text-primary transition duration-300"
              >
                About Us
              </a>
            </li>

            <li>
              <a
                href="#pricing"
                className="text-secondary-default-400 hover:text-primary transition duration-300"
              >
                Pricing
              </a>
            </li>

            <li>
              <a
                href="#contact"
                className="text-secondary-default-400 hover:text-primary transition duration-300"
              >
                Contact
              </a>
            </li>
          </ul>
        </div>
      </div>
    </>
  );
};

export default MobileMenu;
