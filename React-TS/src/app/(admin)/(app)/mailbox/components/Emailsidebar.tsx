import { Link } from 'react-router';
import React from 'react';
import {
  LuCircleDot,
  LuCircleUser,
  LuFileText,
  LuInbox,
  LuOctagonAlert,
  LuPlus,
  LuRadioTower,
  LuSquarePen,
  LuSquirrel,
  LuStar,
  LuStepForward,
  LuTag,
  LuTrash2,
} from 'react-icons/lu';

type MenuItem = {
  label: string;
  icon: React.ElementType;
  href?: string;
  color?: string;
};

type MenuSection = {
  title?: string;
  items: MenuItem[];
};
const Emailsidebar = () => {
  const emailMenuData: MenuSection[] = [
    {
      items: [
        { label: 'Inbox', icon: LuInbox },
        { label: 'Starred', icon: LuStar },
        { label: 'Draft', icon: LuSquarePen },
        { label: 'Important', icon: LuStepForward },
        { label: 'Spam', icon: LuOctagonAlert },
        { label: 'Contacts', icon: LuCircleUser },
        { label: 'Trash', icon: LuTrash2 },
      ],
    },
    {
      title: 'Category',
      items: [
        { label: 'Social', icon: LuRadioTower },
        { label: 'Update', icon: LuSquirrel },
        { label: 'Forums', icon: LuFileText },
        { label: 'Promotions', icon: LuTag },
      ],
    },
    {
      title: 'Label',
      items: [
        { label: 'Support', icon: LuCircleDot, color: 'text-danger' },
        { label: 'Freelance', icon: LuCircleDot, color: 'text-primary' },
        { label: 'Personal', icon: LuCircleDot, color: 'text-sky-500' },
      ],
    },
  ];
  return (
    <div className="lg:border-e border-default-200">
      <div
        id="mailBoxSidebar"
        className="hs-overlay [--auto-close:lg] lg:block lg:translate-x-0 lg:static lg:end-auto lg:bottom-0 w-64 hs-overlay-open:translate-x-0 -translate-x-full transition-all duration-300 transform h-full hidden fixed top-0 start-0 bottom-0 overflow-hidden z-60"
        role="dialog"
        tabIndex={-1}
        aria-label="Sidebar"
      >
        <div className="card shadow-none relative flex flex-col h-full max-h-full overflow-hidden">
          <div className="card-body">
            <button className="btn bg-danger text-white w-full" data-hs-overlay="#addEmailModal">
              <LuPlus className="size-4" />
              Compose Email
            </button>

            <div className="mt-4 text-sm">
              {emailMenuData.map((section, i) => (
                <div key={i}>
                  {section.title && (
                    <p className="py-3 uppercase text-sm text-default-700">{section.title}</p>
                  )}

                  {section.items.map((item, idx) => {
                    const Icon = item.icon;
                    return (
                      <Link
                        key={idx}
                        to={item.href || '#'}
                        className="py-2 flex gap-3 items-center hover:text-primary text-default-500 transition-all"
                      >
                        <Icon className={`size-4 ${item.color || ''}`} />
                        <span>{item.label}</span>
                      </Link>
                    );
                  })}
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Emailsidebar;
