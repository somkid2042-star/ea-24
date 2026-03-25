export interface CalendarEvent {
  id?: number;
  title: string;
  start: Date;
  end?: Date;
  allDay?: boolean;
  className?: string;
  url?: string;
}

export const getDefaultEvents = (): CalendarEvent[] => {
  const date = new Date();
  const d = date.getDate();
  const m = date.getMonth();
  const y = date.getFullYear();

  return [
    {
      id: 999,
      title: 'Repeating Event',
      start: new Date(y, m, d - 3, 16, 0),
      allDay: false,
      className: '!text-warning',
    },
    {
      id: 999,
      title: 'Repeating Event',
      start: new Date(y, m, d + 4, 16, 0),
      allDay: false,
      className: '!text-primary',
    },
    {
      title: 'All Day Event',
      start: new Date(y, m, 1),
      className: '!text-success',
    },
    {
      title: 'Long Event',
      start: new Date(y, m, d - 5),
      end: new Date(y, m, d - 2),
      className: '!text-info',
    },
    {
      title: 'Meeting',
      start: new Date(y, m, d, 10, 30),
      allDay: false,
      className: '!text-danger',
    },
    {
      title: 'Lunch',
      start: new Date(y, m, d, 12, 0),
      end: new Date(y, m, d, 14, 0),
      allDay: false,
      className: '!text-success',
    },
    {
      title: 'Birthday Party',
      start: new Date(y, m, d + 1, 19, 0),
      end: new Date(y, m, d + 1, 22, 30),
      allDay: false,
      className: '!text-info',
    },
    {
      title: 'Click for Google',
      start: new Date(y, m, 28),
      end: new Date(y, m, 29),
      url: 'http://google.com/',
      className: '!text-primary',
    },
  ];
};

export const externalEvents = [
  { title: 'New Event Planning', className: 'text-success', dataClass: '!text-success' },
  { title: 'Meeting', className: 'text-info', dataClass: '!text-info' },
  { title: 'Generating Reports', className: 'text-warning', dataClass: '!text-warning' },
  { title: 'Create New theme', className: 'text-danger', dataClass: '!text-danger' },
];
