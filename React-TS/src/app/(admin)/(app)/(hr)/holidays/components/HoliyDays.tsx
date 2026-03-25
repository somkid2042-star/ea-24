import { Link } from 'react-router';
import { LuChevronLeft, LuChevronRight, LuPencil, LuPlus, LuTrash2 } from 'react-icons/lu';

type Holiday = {
  id: number;
  day: string;
  date: string;
  name: string;
  type: string;
};

const holidays: Holiday[] = [
  { id: 1, day: 'Monday', date: '15 Jan', name: 'Makara Sankranti', type: 'Gazetted Holiday' },
  { id: 2, day: 'Friday', date: '26 Jan', name: 'Republic Day', type: 'Gazetted Holiday' },
  { id: 3, day: 'Monday', date: '25 Mar', name: 'Holi', type: 'Gazetted Holiday' },
  { id: 4, day: 'Friday', date: '29 Mar', name: 'Good Friday', type: 'Gazetted Holiday' },
  { id: 5, day: 'Sunday', date: '4 Aug', name: 'Friendship Day', type: 'Observance' },
  { id: 6, day: 'Thursday', date: '15 Aug', name: 'Independence Day', type: 'Gazetted Holiday' },
  { id: 7, day: 'Sunday', date: '15 Sep', name: 'Onam', type: 'Restricted Holiday' },
  { id: 8, day: 'Thursday', date: '31 Oct', name: 'Halloween', type: 'Observance' },
  { id: 9, day: 'Wednesday', date: '25 Dec', name: 'Christmas', type: 'Gazetted Holiday' },
  { id: 10, day: 'Tuesday', date: '31 Dec', name: 'New Year', type: 'Observance' },
];

const HoliyDays = () => {
  return (
    <div className="card">
      <div className="card-header flex justify-between items-center">
        <h6 className="text-default-800 text-base font-semibold">Holidays 2024</h6>
        <button className="btn btn-sm bg-primary text-white flex items-center gap-1">
          <LuPlus size={16} /> Add Holiday
        </button>
      </div>

      <div className="flex flex-col">
        <div className="overflow-x-auto">
          <div className="min-w-full inline-block align-middle">
            <div className="overflow-hidden">
              <table className="min-w-full divide-y divide-default-200">
                <thead className="font-normal whitespace-nowrap">
                  <tr className="text-sm text-default-800 divide-x divide-default-200">
                    <th className="px-3.5 py-3 font-medium text-start">#</th>
                    <th className="px-3.5 py-3 font-medium text-start">Day</th>
                    <th className="px-3.5 py-3 font-medium text-start">Date</th>
                    <th className="px-3.5 py-3 font-medium text-start">Holiday Name</th>
                    <th className="px-3.5 py-3 font-medium text-start">Type</th>
                    <th className="px-3.5 py-3 font-medium text-start">Action</th>
                  </tr>
                </thead>

                <tbody className="divide-y divide-default-200">
                  {holidays.map(holiday => (
                    <tr
                      key={holiday.id}
                      className="text-default-800 font-normal whitespace-nowrap divide-x divide-default-200"
                    >
                      <td className="px-3.5 py-3 text-sm">{holiday.id}</td>
                      <td className="px-3.5 py-3 text-sm">{holiday.day}</td>
                      <td className="px-3.5 py-3 text-sm">{holiday.date}</td>
                      <td className="px-3.5 py-3 text-sm">{holiday.name}</td>
                      <td className="px-3.5 py-3 text-sm">{holiday.type}</td>
                      <td className="px-3.5 py-3">
                        <div className="flex items-center gap-2">
                          <Link
                            to="#"
                            className="flex size-8  bg-default-200 rounded-md items-center justify-center hover:bg-primary/10 hover:text-primary transition-all text-default-600"
                            aria-haspopup="dialog"
                            aria-expanded="false"
                            aria-controls="holidaysLeaveDeleteModal2"
                            data-hs-overlay="#holidaysLeaveDeleteModal2"
                          >
                            <LuPencil className="size-4" />
                          </Link>

                          <Link
                            to="#"
                            className="flex size-8  bg-default-200 rounded-md items-center justify-center hover:bg-primary/10 hover:text-primary transition-all text-default-600"
                            aria-haspopup="dialog"
                            aria-expanded="false"
                            aria-controls="holidaysLeaveDeleteModal"
                            data-hs-overlay="#holidaysLeaveDeleteModal"
                          >
                            <LuTrash2 className="size-4" />
                          </Link>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </div>

        <div className="card-footer flex justify-between items-center mt-4">
          <p className="text-default-500 text-sm">
            Showing <b>1</b> of <b>{holidays.length}</b> Results
          </p>
          <nav className="flex items-center gap-2" aria-label="Pagination">
            <button
              className="btn btn-sm border bg-transparent border-default-200 text-default-600 hover:bg-primary/10 hover:text-primary hover:border-primary/10 flex items-center gap-1"
              aria-haspopup="dialog"
              aria-expanded="false"
              aria-controls="holidaysLeaveDeleteModal2"
              data-hs-overlay="#holidaysLeaveDeleteModal2"
            >
              <LuChevronLeft size={16} /> Prev
            </button>
            <button className="btn size-7.5 bg-primary text-white">1</button>
            <button
              className="btn btn-sm border bg-transparent border-default-200 text-default-600 hover:bg-primary/10 hover:text-primary hover:border-primary/10 flex items-center gap-1"
              aria-haspopup="dialog"
              aria-expanded="false"
              aria-controls="holidaysLeaveDeleteModal"
              data-hs-overlay="#holidaysLeaveDeleteModal"
            >
              Next <LuChevronRight size={16} />
            </button>
          </nav>
        </div>
      </div>
    </div>
  );
};

export default HoliyDays;
