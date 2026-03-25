import React from 'react';
import arebian from '@/assets/images/flags/arebian.svg';
import french from '@/assets/images/flags/french.jpg';
import germany from '@/assets/images/flags/germany.jpg';
import italy from '@/assets/images/flags/italy.jpg';
import japanese from '@/assets/images/flags/japanese.svg';
import russia from '@/assets/images/flags/russia.jpg';
import spain from '@/assets/images/flags/spain.jpg';
import us from '@/assets/images/flags/us.jpg';
import { LuFacebook, LuInstagram, LuLinkedin, LuTwitter, LuYoutube } from 'react-icons/lu';
import { Link } from 'react-router';
import { currentYear, developedBy } from '../../../../helpers/constants';

type FooterLink = {
  label: string;
  href: string;
};

type FooterSection = {
  title: string;
  links: FooterLink[];
};

type Language = {
  name: string;
  flag: string;
};

type SocialLink = {
  name: string;
  icon: React.ElementType;
  href: string;
};

const footerSections: FooterSection[] = [
  {
    title: 'Dashboards',
    links: [
      { label: 'Analytics', href: '#' },
      { label: 'CRM', href: '#' },
      { label: 'Ecommerce', href: '#' },
      { label: 'Email', href: '#' },
      { label: 'HR', href: '#' },
      { label: 'Social Media', href: '#' },
    ],
  },
  {
    title: 'Apps Pages',
    links: [
      { label: 'Ecommerce Apps', href: '#' },
      { label: 'Invoices', href: '#' },
      { label: 'Email App', href: '#' },
      { label: 'Chat App', href: '#' },
      { label: 'Users Apps', href: '#' },
      { label: 'HR Management', href: '#' },
      { label: 'Social Media', href: '#' },
    ],
  },
  {
    title: 'Resources',
    links: [
      { label: 'All Resources', href: '#' },
      { label: 'Blog', href: '#' },
      { label: "FAQ's", href: '#' },
      { label: 'Help Center', href: '#' },
    ],
  },
];

const languages: Language[] = [
  { name: 'English', flag: us },
  { name: 'Spanish', flag: spain },
  { name: 'German', flag: germany },
  { name: 'French', flag: french },
  { name: 'Japanese', flag: japanese },
  { name: 'Italian', flag: italy },
  { name: 'Russian', flag: russia },
  { name: 'Arabic', flag: arebian },
];

const socialLinks: SocialLink[] = [
  { name: 'Facebook', icon: LuFacebook, href: '#' },
  { name: 'Linkedin', icon: LuLinkedin, href: '#' },
  { name: 'Instagram', icon: LuInstagram, href: '#' },
  { name: 'Twitter', icon: LuTwitter, href: '#' },
  { name: 'Youtube', icon: LuYoutube, href: '#' },
];

const Footer = () => {
  return (
    <footer className="relative pt-20 pb-12 bg-default-800 dark:bg-default-900">
      <div className="container">
        <div className="relative z-10 grid lg:grid-cols-12 md:grid-cols-2 gap-5">
          {footerSections.map((section, idx) => (
            <div key={idx} className="lg:col-span-3">
              <h5 className="mb-4 font-medium text-white text-lg">{section.title}</h5>
              <ul className="flex flex-col gap-y-3 text-sm">
                {section.links.map((link, i) => (
                  <li key={i}>
                    <Link
                      to={link.href}
                      className="relative inline-block transition-all duration-200 ease-linear text-default-400 before:absolute before:border-b before:border-default-400 before:inset-x-0 before:bottom-0 before:w-0 hover:before:w-full before:transition-all before:duration-300 before:ease-linear"
                    >
                      {link.label}
                    </Link>
                  </li>
                ))}
              </ul>
            </div>
          ))}

          <div className="lg:col-span-3">
            <div className="flex p-1 lg:w-96 md:w-90 w-86 rounded-md border border-white/14 bg-card/4 relative mb-6">
              <input
                type="email"
                placeholder="tailwick@themesdesign.in"
                className="px-3 text-sm text-white border-none bg-transparent focus:outline-none focus:ring-0"
              />
              <button
                type="button"
                className="absolute right-2 btn text-white bg-primary hover:bg-primary/90"
              >
                Subscribe Now
              </button>
            </div>

            <div>
              <p className="mb-1 text-sm text-default-400">Support Email</p>
              <h5 className="text-lg text-white">support@themesdesign.in</h5>
            </div>

            <div className="mt-6">
              <p className="mb-1 text-sm text-default-400">Contact Us</p>
              <h5 className="text-lg text-white">+(012) 1202 012 4567</h5>
            </div>
          </div>
        </div>

        <div className="py-5 mt-20 border-y border-default-400/40">
          <div className="md:flex justify-between items-center">
            <div className="hs-dropdown relative inline-flex">
              <button
                id="hs-dropdown-with-icons"
                type="button"
                className="hs-dropdown-toggle py-2 px-4 bg-transparent border border-default-400/40 text-white hover:border-primary rounded hover:text-primary font-semibold gap-2 flex items-center"
                aria-haspopup="menu"
                aria-expanded="false"
                aria-label="Dropdown"
              >
                <img src={us} alt="English" className="size-5 rounded-full" />
                English
              </button>

              <div
                className="hs-dropdown-menu p-2 transition-[opacity,margin] duration hs-dropdown-open:opacity-100 opacity-0 hidden min-w-38 card z-40 mt-2 divide-y divide-default-200"
                role="menu"
                aria-orientation="vertical"
                aria-labelledby="hs-dropdown-with-icons"
              >
                <div className="p-1 space-y-3 text-sm font-normal">
                  {languages.map((lang, i) => (
                    <Link
                      key={i}
                      to="#"
                      className="flex items-center gap-x-3.5 px-3 text-default-600 hover:text-primary"
                    >
                      <img src={lang.flag} alt={lang.name} className="size-4 rounded-full" />
                      {lang.name}
                    </Link>
                  ))}
                </div>
              </div>
            </div>

            <div className="flex flex-wrap gap-3 md:mt-0 mt-5">
              {socialLinks.map((social, i) => {
                const Icon = social.icon;
                return (
                  <Link
                    key={i}
                    to={social.href}
                    className="size-10 btn border border-default-400/40 bg-transparent rounded-full text-default-400 hover:text-primary flex items-center justify-center"
                  >
                    <Icon className="size-4" />
                  </Link>
                );
              })}
            </div>
          </div>
        </div>

        <div className="text-base mt-12 text-center text-default-400">
          <p>
            {currentYear} © Tailwick. Design & Develop by{' '}
            <Link to="#" className="underline text-white hover:text-primary">
              {developedBy}
            </Link>
          </p>
        </div>
      </div>
    </footer>
  );
};

export default Footer;
