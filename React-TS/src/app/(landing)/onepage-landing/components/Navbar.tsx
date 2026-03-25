import darkLogo from '@/assets/images/logo-dark.png';
import logoLight from '@/assets/images/logo-light.png';
import { LuLogIn } from 'react-icons/lu';
import { Link } from 'react-router';
import MobileMenu from './MobileMenu';

const Navbar = () => {
  return (
    <header>
      <nav className="fixed inset-x-0 top-0 z-50 bg-card py-6  shadow flex justify-between items-center">
        <div className="container">
          <div className="grid lg:grid-cols-12 md:grid-cols-10 grid-cols-2 items-center">
            <div className="lg:col-span-2 md:col-span-2">
              <Link to="/index">
                <img src={darkLogo} alt="logo dark" className="h-6 block dark:hidden" width={111} />
                <img
                  src={logoLight}
                  alt="logo light"
                  className="h-6 hidden dark:block"
                  width={111}
                />
              </Link>
            </div>

            <div className="lg:col-span-8 md:col-span-6 md:block hidden">
              <ul className="flex items-center justify-center lg:gap-8 md:gap-6 font-medium text-sm">
                <li>
                  <a
                    href="#home"
                    className="text-default-800  hover:text-primary transition duration-300"
                  >
                    Home
                  </a>
                </li>

                <li>
                  <a
                    href="#features"
                    className="text-default-800  hover:text-primary transition duration-300"
                  >
                    Our Features
                  </a>
                </li>

                <li>
                  <a
                    href="#about"
                    className="text-default-800  hover:text-primary transition duration-300"
                  >
                    About Us
                  </a>
                </li>

                <li>
                  <a
                    href="#pricing"
                    className="text-default-800  hover:text-primary transition duration-300"
                  >
                    Pricing
                  </a>
                </li>

                <li>
                  <a
                    href="#contact"
                    className="text-default-800  hover:text-primary transition duration-300"
                  >
                    Contact
                  </a>
                </li>
              </ul>
            </div>

            <div className="lg:col-span-2 md:col-span-2 flex items-center justify-end gap-2">
              <MobileMenu />

              <Link to="#" className="flex justify-end">
                <button type="button" className="btn bg-primary text-white">
                  Sign In
                  <LuLogIn className="size-4" />
                </button>
              </Link>
            </div>
          </div>
        </div>
      </nav>
    </header>
  );
};

export default Navbar;
