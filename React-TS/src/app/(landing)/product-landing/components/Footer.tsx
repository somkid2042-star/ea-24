import logoDark from '@/assets/images/logo-dark.png';
import logoLight from '@/assets/images/logo-light.png';
import React from 'react';
import { LuFacebook, LuInstagram, LuLinkedin, LuTwitter, LuYoutube } from 'react-icons/lu';
import { Link } from 'react-router';
import { currentYear, developedBy } from '../../../../helpers/constants';

type LinkItem = {
  label: string;
  href: string;
};

type Section = {
  title: string;
  links: LinkItem[];
};

type SocialLink = {
  id: number;
  icon: React.ElementType;
  href: string;
};

const socialLinks: SocialLink[] = [
  { id: 1, icon: LuFacebook, href: '#' },
  { id: 2, icon: LuLinkedin, href: '#' },
  { id: 3, icon: LuInstagram, href: '#' },
  { id: 4, icon: LuTwitter, href: '#' },
  { id: 5, icon: LuYoutube, href: '#' },
];

const footerSections: Section[] = [
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
    title: 'About Us',
    links: [
      { label: 'News', href: '#' },
      { label: 'Service', href: '#' },
      { label: 'Our Policy', href: '#' },
      { label: 'Support 24/7', href: '#' },
      { label: "FAQ's", href: '#' },
    ],
  },
  {
    title: 'Get Help',
    links: [
      { label: 'About Us', href: '#' },
      { label: 'Contact Us', href: '#' },
      { label: 'Payment Policy', href: '#' },
      { label: 'Return Policy', href: '#' },
    ],
  },
];

const Footer = () => {
  return (
    <footer className="relative md:pt-20 pt-12 md:pb-0 border-t border-default-200">
      <div className="absolute -top-16 start-0 size-64 bg-purple-500/10 blur-3xl"></div>
      <div className="container">
        <div className="grid grid-cols-12 md:gap-12 gap-6">
          <div className="lg:col-span-4 col-span-12">
            <div className="mb-5">
              <Link to="#">
                <img src={logoDark} alt="logo dark" className="h-7 block dark:hidden" width={111} />
                <img
                  src={logoLight}
                  alt="logo light"
                  className="h-7 hidden dark:block"
                  width={111}
                />
              </Link>
            </div>

            <p className="mb-5 text-sm text-default-500">
              Premium Multipurpose Admin & Dashboard Template You can build any type of web
              application like eCommerce, CRM, CMS, Project management apps, Admin Panels, etc using
              Tailwick.
            </p>

            <div className="flex flex-wrap gap-3 md:mt-0 mt-5">
              {socialLinks.map(({ id, icon: Icon, href }) => (
                <Link
                  key={id}
                  to={href}
                  className="size-10 flex items-center justify-center border border-default-200 bg-transparent rounded-full text-default-500 hover:text-primary transition"
                >
                  <Icon className="size-4" />
                </Link>
              ))}
            </div>
          </div>

          {footerSections.map((section, index) => (
            <div
              key={index}
              className={`${
                index === 0
                  ? 'lg:col-span-3 md:col-span-4 col-span-12'
                  : index === 1
                    ? 'lg:col-span-3 md:col-span-4 col-span-12'
                    : 'lg:col-span-2 md:col-span-4 col-span-12'
              }`}
            >
              <h5 className="mb-4 font-medium text-lg text-default-700">{section.title}</h5>
              <ul className="flex flex-col gap-y-3 text-sm">
                {section.links.map((link, i) => (
                  <li key={i}>
                    <Link
                      to={link.href}
                      className="relative inline-block transition-all duration-200 ease-linear hover:text-default-900 text-default-600 before:absolute before:border-b before:border-default-200 before:inset-x-0 before:bottom-0 before:w-0 hover:before:w-full before:transition-all before:duration-300 before:ease-linear"
                    >
                      {link.label}
                    </Link>
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>
      </div>

      <div className="lg:py-10 py-6 mt-12 text-center text-default-500 text-base border-t border-default-200">
        <p>
          {currentYear} © Tailwick. Design & Develop by{' '}
          <Link
            to="https://themesdesign.in/"
            target="_blank"
            rel="noopener noreferrer"
            className="underline text-default-800 font-bold transition-all hover:text-primary"
          >
            {developedBy}
          </Link>
        </p>
      </div>
    </footer>
  );
};

export default Footer;
