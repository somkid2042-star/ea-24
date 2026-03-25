import { LuEllipsis, LuEye, LuSquarePen, LuStar, LuTrash2 } from 'react-icons/lu';
import { Link } from 'react-router';

type Note = {
  id: number;
  title: string;
  description: string;
  category: string;
  categoryColor: string;
  date: string;
  isStarred?: boolean;
  details?: string[];
};

const notesData: Note[] = [
  {
    id: 1,
    title: 'Show Then Our Research',
    description:
      'You should identify and anticipate any ethical issues or dilemmas that may arise during or after your research, and how you will resolve them.You should identify and anticipate any ethical issues or dilemmas that may arise during...',
    date: '16 May, 2023',
    category: 'Personal',
    categoryColor: 'bg-primary/15 border-primary',
    isStarred: true,
  },
  {
    id: 2,
    title: 'New People Hiring',
    description: 'Steps to recruiting employees',
    details: [
      'Consider your actual needs',
      'Conduct interviews with top applicants',
      'Don’t take too long to hire',
      'Making the offer',
    ],
    date: '24 Mar, 2023',
    category: 'Business',
    categoryColor: 'bg-danger/15 border-danger',
    isStarred: false,
  },
  {
    id: 3,
    title: 'Design Tools',
    description:
      'Visual design tools are, for example, gesture, sketch, drawing, scale model, perspective drawing, photograph, film, video. These include flowcharts, pseudocode, and Nassi-Shneiderman diagrams.',
    date: '29 Feb, 2023',
    category: 'Social',
    categoryColor: 'bg-secondary/10 border-secondary',
    isStarred: true,
  },
  {
    id: 4,
    title: 'Create Chat Apps',
    description:
      'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
    date: '01 Jan, 2023',
    category: 'Home',
    categoryColor: 'bg-success/10 border-success',
    isStarred: false,
  },
  {
    id: 5,
    title: 'Show Then Our Research',
    description:
      'You should identify and anticipate any ethical issues or dilemmas that may arise during or after your research, and how you will resolve them.You should identify and anticipate any ethical issues or dilemmas that may arise during...',
    date: '16 May, 2023',
    category: 'Personal',
    categoryColor: 'bg-primary/15 border-primary',
    isStarred: true,
  },
  {
    id: 6,
    title: 'New People Hiring',
    description: 'Steps to recruiting employees',
    details: [
      'Consider your actual needs',
      'Conduct interviews with top applicants',
      'Don’t take too long to hire',
      'Making the offer',
    ],
    date: '24 Mar, 2023',
    category: 'Business',
    categoryColor: 'bg-danger/15 border-danger',
    isStarred: false,
  },
  {
    id: 7,
    title: 'Boarding is Important Thing',
    description:
      'Living away from home and residing on campus in a dorm setting provides invaluable opportunities for personal growth. Boarding school students tend to develop life Business such as time management, work ethic',
    date: '29 Mar, 2023',
    category: 'Personal',
    categoryColor: 'bg-primary/10 border-primary',
    isStarred: false,
  },
  {
    id: 8,
    title: 'Company Improvements',
    description:
      "Improving a business's performance requires a strategic and holistic approach that focuses on key areas such as setting and tracking KPIs, improving operational efficiency.",
    date: '10 Apr, 2023',
    category: 'Business',
    categoryColor: 'bg-secondary/10 border-secondary',
    isStarred: true,
  },
];

const Notes = () => {
  return (
    <div className="grid lg:grid-cols-4 md:grid-cols-2 grid-cols-1 gap-5">
      {notesData.map(note => (
        <div key={note.id} className="card">
          <div className="card-body">
            <div className="flex flex-col justify-between h-full">
              <div className="mb-5 flex justify-between items-center gap-2">
                <div className="flex gap-2 items-center">
                  <div className="hs-dropdown relative inline-flex">
                    <button
                      type="button"
                      className={`hs-dropdown-toggle size-4 border border-dashed rounded-full shrink-0 ${note.categoryColor}`}
                      aria-haspopup="menu"
                      aria-expanded="false"
                    />
                    <div className="hs-dropdown-menu" role="menu">
                      {['Personal', 'Business', 'Social', 'Home'].map(cat => (
                        <Link
                          key={cat}
                          to="#"
                          className="flex items-center gap-x-3.5 py-1.5 font-medium px-3 text-sm text-default-600 hover:bg-default-150 rounded"
                        >
                          {cat}
                        </Link>
                      ))}
                    </div>
                  </div>
                  <h5 className="card-title">{note.title}</h5>
                </div>
                <div className="hs-dropdown relative inline-flex">
                  <button
                    type="button"
                    className="hs-dropdown-toggle btn size-7.5 bg-default-200 hover:bg-default-600 text-default-500 hover:text-white"
                  >
                    <LuEllipsis className="size-4" />
                  </button>
                  <div className="hs-dropdown-menu" role="menu">
                    <Link
                      to="#"
                      className="flex items-center gap-1.5 py-1.5 font-medium px-3 text-default-500 hover:bg-default-150 rounded"
                    >
                      <LuEye className="size-3" /> Overview
                    </Link>
                    <Link
                      to="#"
                      className="flex items-center gap-1.5 py-1.5 font-medium px-3 text-default-500 hover:bg-default-150 rounded"
                    >
                      <LuSquarePen className="size-3" /> Edit
                    </Link>
                    <Link
                      to="#"
                      className="flex items-center gap-1.5 py-1.5 font-medium px-3 text-default-500 hover:bg-default-150 rounded"
                    >
                      <LuTrash2 className="size-3" /> Delete
                    </Link>
                  </div>
                </div>
              </div>

              {note.details ? (
                <div>
                  <p className="text-default-800 font-semibold text-sm">{note.description}</p>
                  <ol className="flex flex-col text-default-600 gap-1 text-sm mt-1">
                    {note.details.map((d, i) => (
                      <li key={i}>{d}</li>
                    ))}
                  </ol>
                </div>
              ) : (
                <p className="text-default-700 text-sm">{note.description}</p>
              )}

              <div className="mt-4 flex justify-between gap-3 items-center">
                <LuStar
                  className={`${note.isStarred ? 'text-warning fill-warning/20' : 'text-default-500 fill-default-200'} size-5`}
                />
                <p className="text-default-500 text-sm">{note.date}</p>
              </div>
            </div>
          </div>
        </div>
      ))}
    </div>
  );
};

export default Notes;
