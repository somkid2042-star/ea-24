import support from '@/assets/images/support.png';

type EventItem = {
  id: number;
  day: string;
  month: string;
  title: string;
  time?: string;
  createdBy: string;
};

const events: EventItem[] = [
  {
    id: 1,
    day: '28',
    month: 'July',
    title: 'Meeting with Designer',
    time: '09:57 AM',
    createdBy: 'Admin',
  },
  {
    id: 2,
    day: '08',
    month: 'June',
    title: 'Developing Line Managers Conference',
    time: '10:54 AM',
    createdBy: 'HR',
  },
  {
    id: 3,
    day: '17',
    month: 'July',
    title: 'Airplane in Las Vegas',
    time: '12:00 PM',
    createdBy: 'HR',
  },
  { id: 4, day: '11', month: 'Nov', title: 'Hospitality Project Discuses', createdBy: 'Admin' },
  {
    id: 5,
    day: '20',
    month: 'Nov',
    title: 'Gartner Digital Workplace',
    time: '03:49 PM',
    createdBy: 'HR',
  },
  {
    id: 6,
    day: '04',
    month: 'Dec',
    title: 'Nordic People Analytics',
    time: '11:00 AM',
    createdBy: 'Admin',
  },
  {
    id: 7,
    day: '17',
    month: 'Jan',
    title: 'CIPD Festival of Work',
    time: '01:29 PM',
    createdBy: 'HR',
  },
  {
    id: 8,
    day: '03',
    month: 'Feb',
    title: 'HRO Today Forum',
    time: '02:15 PM',
    createdBy: 'Admin',
  },
  {
    id: 9,
    day: '15',
    month: 'Mar',
    title: 'HR Training Workshop',
    time: '09:00 AM',
    createdBy: 'HR',
  },
  {
    id: 10,
    day: '29',
    month: 'Apr',
    title: 'Marketing Strategy Review',
    time: '04:45 PM',
    createdBy: 'Marketing',
  },
  {
    id: 11,
    day: '10',
    month: 'May',
    title: 'Client Demo Presentation',
    time: '11:30 AM',
    createdBy: 'Admin',
  },
];

const UpcomingScheduled = () => {
  return (
    <div className="card">
      <div className="card-header">
        <h6 className="card-title">Upcoming Scheduled</h6>
      </div>

      <div className="card-body">
        <div className="flex flex-col gap-4">
          {events.map(event => (
            <div key={event.id} className="flex gap-3">
              <div className="flex flex-col items-center justify-center border rounded-sm size-12 border-default-200">
                <h6 className="text-default-800 font-semibold">{event.day}</h6>
                <span className="text-default-500">{event.month}</span>
              </div>

              <div>
                <h6 className="mb-1 text-default-900 text-sm font-medium">
                  {event.title}{' '}
                  {event.time && (
                    <small className="px-2 font-medium rounded text-xs py-0.5 bg-default-100 text-default-500">
                      {event.time}
                    </small>
                  )}
                </h6>
                <p className="text-default-500">Created by {event.createdBy}</p>
              </div>
            </div>
          ))}
        </div>

        <div className="flex gap-3 p-2 mt-4 rounded-md bg-primary">
          <img src={support} alt="Support" className="h-24 w-auto" />
          <div>
            <h6 className="mb-1 text-base text-white">Need Help ?</h6>
            <p className="text-white">
              If you would like to learn more about transferring the license to a customer
            </p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default UpcomingScheduled;
