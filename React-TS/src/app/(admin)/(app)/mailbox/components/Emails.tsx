import SimplebarClient from '@/components/client-wrapper/SimplebarClient';
import { Link } from 'react-router';
import {
  LuAlignLeft,
  LuArchiveRestore,
  LuClock,
  LuEllipsis,
  LuMail,
  LuOctagonAlert,
  LuRefreshCw,
  LuSearch,
  LuStar,
  LuStepForward,
  LuTag,
  LuTrash2,
} from 'react-icons/lu';

type EmailItem = {
  id: number;
  sender: string;
  subject: string;
  time: string;
  read: boolean;
};

const Emails = () => {
  const emailData: EmailItem[] = [
    {
      id: 1,
      sender: 'Tonya Johnson',
      subject: 'Maintain the overall pristine status...',
      time: '10:59 AM',
      read: false,
    },
    {
      id: 2,
      sender: 'Infra Teach',
      subject: 'How Custom Software Can Solve Your Business Challenges.',
      time: '04:15 PM',
      read: true,
    },
    {
      id: 3,
      sender: 'Facebook',
      subject:
        'Post Basic High School, Ratanpur(GA) and 7 others are new Group suggestions for you',
      time: '12:29 PM',
      read: true,
    },
    {
      id: 4,
      sender: 'Linkedin',
      subject: 'Front End Developer-HTML/CSS role at Gainserv: 1 connection',
      time: '08:44 PM',
      read: true,
    },
    {
      id: 5,
      sender: 'Jobcy - Job Board & Landing',
      subject: 'You’re invited: Job Search Tactics for Entry-Level Candidates',
      time: '08:10 PM',
      read: true,
    },
    {
      id: 6,
      sender: 'Holly Kavanaugh',
      subject: 'Information Technology Rules Annual Reminder',
      time: '04:33 PM',
      read: false,
    },
    {
      id: 7,
      sender: 'Jose White',
      subject: 'I just requested to connect -Paula Keenan, respond to Meet’s now.',
      time: '01:19 PM',
      read: true,
    },
    {
      id: 8,
      sender: 'Patricia Garcia',
      subject: 'List all mail-enabled users who have specific permissions...',
      time: '01:20 AM',
      read: false,
    },
    {
      id: 9,
      sender: 'Themesdesign',
      subject: 'Your License expired',
      time: '11:54 PM',
      read: true,
    },
    {
      id: 10,
      sender: 'Tonya Johnson',
      subject: 'Maintain the overall pristine status...',
      time: '10:59 AM',
      read: false,
    },
    {
      id: 11,
      sender: 'Infra Teach',
      subject: 'How Custom Software Can Solve Your Business Challenges.',
      time: '04:15 PM',
      read: true,
    },
    {
      id: 12,
      sender: 'Facebook',
      subject:
        'Post Basic High School, Ratanpur(GA) and 7 others are new Group suggestions for you',
      time: '12:29 PM',
      read: true,
    },
    {
      id: 13,
      sender: 'Linkedin',
      subject: 'Front End Developer-HTML/CSS role at Gainserv: 1 connection',
      time: '08:44 PM',
      read: true,
    },
    {
      id: 14,
      sender: 'Jobcy - Job Board & Landing',
      subject: 'You’re invited: Job Search Tactics for Entry-Level Candidates',
      time: '08:10 PM',
      read: true,
    },
    {
      id: 15,
      sender: 'Holly Kavanaugh',
      subject: 'Information Technology Rules Annual Reminder',
      time: '04:33 PM',
      read: false,
    },
    {
      id: 16,
      sender: 'Jose White',
      subject: 'I just requested to connect -Paula Keenan, respond to Meet’s now.',
      time: '01:19 PM',
      read: true,
    },
    {
      id: 17,
      sender: 'Patricia Garcia',
      subject: 'List all mail-enabled users who have specific permissions...',
      time: '01:20 AM',
      read: false,
    },
    {
      id: 18,
      sender: 'Themesdesign',
      subject: 'Your License expired',
      time: '11:54 PM',
      read: true,
    },
  ];
  return (
    <>
      <div className="card-header">
        <div className="flex items-center gap-4.5">
          <button
            className="lg:hidden"
            aria-haspopup="dialog"
            aria-expanded="false"
            aria-controls="mailBoxSidebar"
            aria-label="Toggle navigation"
            data-hs-overlay="#mailBoxSidebar"
          >
            <LuAlignLeft className="size-6" />
          </button>

          <input id="checkAll" type="checkbox" className="form-checkbox checked:bg-primary" />
          <button>
            <LuRefreshCw className="size-4 text-default-500 hover:text-primary" />
          </button>

          <div className="w-px h-5 bg-default-200"></div>

          <button>
            <LuArchiveRestore className="size-4 text-default-500 hover:text-primary" />
          </button>
          <button>
            <LuOctagonAlert
              data-lucide="alert-octagon"
              className="size-4 text-default-500 hover:text-primary"
            />
          </button>
          <button>
            <LuTrash2
              data-lucide="trash-2"
              className="size-4 text-default-500 hover:text-primary"
            />
          </button>

          <div className="w-px h-5 bg-default-200"></div>

          <button>
            <LuMail className="size-4 text-default-500 hover:text-primary" />
          </button>
          <button>
            <LuTag className="size-4 text-default-500 hover:text-primary" />
          </button>
          <button>
            <LuClock className="size-4 text-default-500 hover:text-primary" />
          </button>
        </div>

        <div className="flex items-center gap-2">
          <div className="relative flex-1">
            <input
              type="email"
              className="form-input form-input-sm ps-11"
              placeholder="Search for...."
            />
            <div className="absolute inset-y-0 start-0 flex items-center pointer-events-none ps-4">
              <LuSearch className="size-4 flex items-center text-default-500" />
            </div>
          </div>

          <div className="hs-dropdown relative inline-flex">
            <button
              type="button"
              className="hs-dropdown-toggle btn size-7.5 bg-default-200 text-default-700"
              aria-haspopup="menu"
              aria-expanded="false"
              aria-label="Dropdown"
              hs-dropdown-placement="bottom-end"
            >
              <LuEllipsis className="size-4" />
            </button>

            <div className="hs-dropdown-menu" role="menu">
              <Link
                className="flex items-center gap-x-3.5 py-1.5 px-3 text-default-600 hover:bg-default-150 rounded"
                to="#"
              >
                Show more message
              </Link>
              <Link
                className="flex items-center gap-x-3.5 py-1.5 px-3  text-default-600 hover:bg-default-150 rounded"
                to="#"
              >
                Important & Unread
              </Link>
              <Link
                className="flex items-center gap-x-3.5 py-1.5 px-3  text-default-600 hover:bg-default-150 rounded"
                to="#"
              >
                Hide section when empty
              </Link>
              <Link
                className="flex items-center gap-x-3.5 py-1.5 px-3  text-default-600 hover:bg-default-150 rounded"
                to="#"
              >
                All Delete
              </Link>
            </div>
          </div>
        </div>
      </div>

      <SimplebarClient className="h-166">
        <div className="overflow-x-auto">
          <div className="min-w-full inline-block align-middle">
            <div className="overflow-hidden">
              <table className="w-full mail-list">
                <tbody className="divide-y divide-default-200">
                  {emailData.map(email => (
                    <tr
                      key={email.id}
                      className={`${email.read ? 'text-default-500' : 'text-default-800'} text-sm`}
                      data-hs-overlay="#emailOverview"
                    >
                      <td className="py-2.5 ps-5">
                        <div className="flex items-center gap-3 h-5">
                          <input type="checkbox" className="form-checkbox checked:bg-primary" />
                          <LuStar className="size-4 text-default-500 hover:text-yellow-500" />
                          <LuStepForward className="size-4 text-default-500 hover:text-yellow-500" />
                        </div>
                      </td>
                      <td className="px-3.5 py-2.5 whitespace-nowrap">{email.sender}</td>
                      <td className="px-3.5 py-2.5 whitespace-nowrap">{email.subject}</td>
                      <td className="px-3.5 py-2.5 whitespace-nowrap">{email.time}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </SimplebarClient>
    </>
  );
};

export default Emails;
