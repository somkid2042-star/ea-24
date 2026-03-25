import user5 from '@/assets/images/user/avatar-5.png';
import user1 from '@/assets/images/user/user-1.jpg';
import user2 from '@/assets/images/user/user-2.jpg';
import user3 from '@/assets/images/user/user-3.jpg';
import SimplebarClient from '@/components/client-wrapper/SimplebarClient';

import { Link } from 'react-router';
import { LuCalendar, LuClock, LuEllipsisVertical } from 'react-icons/lu';

type Interview = {
  id: number;
  name: string;
  email: string;
  image: string;
  date: string;
  time: string;
  status: 'Confirm' | 'Re-scheduled' | 'Scheduled' | 'Cancelled';
  statusColor: string;
};

const interviews: Interview[] = [
  {
    id: 1,
    name: 'James Krogman',
    email: 'james@tailwick.com',
    image: user1,
    date: '25 Nov',
    time: '02:41 pm',
    status: 'Confirm',
    statusColor: 'border-success/40 text-success',
  },
  {
    id: 2,
    name: 'Michael Scott',
    email: 'michaelScott@tailwick.com',
    image: user2,
    date: '05 Dec',
    time: '01:23 pm',
    status: 'Re-scheduled',
    statusColor: 'border-primary/40 text-primary',
  },
  {
    id: 3,
    name: 'Denise Ledford',
    email: 'ledford@tailwick.com',
    image: user3,
    date: '27 Nov',
    time: '11:59 pm',
    status: 'Scheduled',
    statusColor: 'border-secondary/40 text-secondary',
  },
  {
    id: 4,
    name: 'Gladys Smith',
    email: 'gap-4@tailwick.com',
    image: user5,
    date: '07 Dec',
    time: '05:19 pm',
    status: 'Cancelled',
    statusColor: 'border-danger/40 text-danger',
  },
];

const UpcomingInterview = () => {
  return (
    <div className="col-span-1">
      <div className="card z-10">
        <div className="card-header">
          <h6 className="card-title">Upcoming Interview</h6>
        </div>

        <SimplebarClient className="h-98">
          <div className="card-body">
            <div className="flex flex-col gap-3">
              {interviews.map(interview => (
                <div key={interview.id} className="border rounded-md border-default-200">
                  <div className="flex justify-between items-center p-2 border-b border-default-200">
                    <div className="flex flex-wrap items-center gap-3">
                      <div className="rounded-full size-10">
                        <img src={interview.image} alt={interview.name} className="rounded-full" />
                      </div>
                      <div className="text-sm">
                        <h6 className="mb-1 text-default-800 font-semibold">
                          <Link to="#">{interview.name}</Link>
                        </h6>
                        <p className="text-default-500">{interview.email}</p>
                      </div>
                    </div>

                    <div className="hs-dropdown relative inline-flex">
                      <button
                        type="button"
                        className="hs-dropdown-toggle btn size-7.5 hover:bg-default-150 text-default-500"
                        aria-haspopup="menu"
                        aria-expanded="false"
                        aria-label="Dropdown"
                        hs-dropdown-placement="bottom-end"
                      >
                        <LuEllipsisVertical className="size-4" />
                      </button>

                      <div
                        className="hs-dropdown-menu transition-[opacity,margin] duration hs-dropdown-open:opacity-100 opacity-0 hidden min-w-40 card z-60 mt-2 p-2"
                        role="menu"
                      >
                        <div className="flex flex-col gap-y-1 text-sm">
                          <Link
                            className="py-1.5 font-medium px-3 text-default-500 hover:bg-default-150 rounded"
                            to="#"
                          >
                            Overview
                          </Link>
                          <Link
                            className="py-1.5 font-medium px-3 text-default-500 hover:bg-default-150 rounded"
                            to="#"
                          >
                            Edit
                          </Link>
                          <Link
                            className="py-1.5 font-medium px-3 text-default-500 hover:bg-default-150 rounded"
                            to="#"
                          >
                            Delete
                          </Link>
                        </div>
                      </div>
                    </div>
                  </div>

                  <div className="p-2">
                    <div className="flex justify-between items-center gap-3 text-sm">
                      <div className="flex gap-3 items-center text-default-500">
                        <div className="flex items-center">
                          <LuCalendar className="size-4 me-1.5" />
                          <span>{interview.date}</span>
                        </div>
                        <div className="flex items-center">
                          <LuClock className="size-4 me-1.5" />
                          <span className="uppercase">{interview.time}</span>
                        </div>
                      </div>
                      <div>
                        <span
                          className={`inline-flex items-center gap-x-1.5 py-0.5 px-2 rounded text-xs font-normal border ${interview.statusColor}`}
                        >
                          {interview.status}
                        </span>
                      </div>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </SimplebarClient>
      </div>
    </div>
  );
};

export default UpcomingInterview;
