import { Link } from 'react-router';
import {
  LuCheck,
  LuChevronLeft,
  LuChevronRight,
  LuDownload,
  LuPencil,
  LuSearch,
  LuTrash2,
} from 'react-icons/lu';

type LeaveStatus = 'Approved' | 'Pending' | 'Declined' | 'New';

interface LeaveData {
  id: number;
  employeeName: string;
  leaveType: string;
  reason: string;
  noOfDays: number;
  from: string;
  to: string;
  status: LeaveStatus;
}

const leaveData: LeaveData[] = [
  {
    id: 1,
    employeeName: 'Willie Torres',
    leaveType: 'Medical Leave',
    reason: 'Going to Hospital',
    noOfDays: 2,
    from: '11 Oct, 2023',
    to: '12 Oct, 2023',
    status: 'Approved',
  },
  {
    id: 2,
    employeeName: 'Patricia Garcia',
    leaveType: 'Casual Leave',
    reason: 'Going to Family Function',
    noOfDays: 1,
    from: '07 Sept, 2023',
    to: '07 Sept, 2023',
    status: 'Pending',
  },
  {
    id: 3,
    employeeName: 'Juliette Fecteau',
    leaveType: 'Casual Leave',
    reason: 'Going to Holiday',
    noOfDays: 6,
    from: '11 Jun, 2023',
    to: '16 Jun, 2023',
    status: 'New',
  },
  {
    id: 4,
    employeeName: 'Thomas Hatfield',
    leaveType: 'Sick Leave',
    reason: 'Attend Birthday party',
    noOfDays: 1,
    from: '15 July, 2023',
    to: '15 July, 2023',
    status: 'Approved',
  },
  {
    id: 5,
    employeeName: 'Sophie Turner',
    leaveType: 'Casual Leave',
    reason: 'Attending Wedding',
    noOfDays: 2,
    from: '05 Jun, 2023',
    to: '06 Jun, 2023',
    status: 'Declined',
  },
  {
    id: 6,
    employeeName: 'Willie Torres',
    leaveType: 'Medical Leave',
    reason: 'Going to Hospital',
    noOfDays: 2,
    from: '11 Oct, 2023',
    to: '12 Oct, 2023',
    status: 'Approved',
  },
  {
    id: 7,
    employeeName: 'Patricia Garcia',
    leaveType: 'Casual Leave',
    reason: 'Going to Family Function',
    noOfDays: 1,
    from: '07 Sept, 2023',
    to: '07 Sept, 2023',
    status: 'Pending',
  },
  {
    id: 8,
    employeeName: 'Juliette Fecteau',
    leaveType: 'Casual Leave',
    reason: 'Going to Holiday',
    noOfDays: 6,
    from: '11 Jun, 2023',
    to: '16 Jun, 2023',
    status: 'New',
  },
  {
    id: 9,
    employeeName: 'Thomas Hatfield',
    leaveType: 'Sick Leave',
    reason: 'Attend Birthday party',
    noOfDays: 1,
    from: '15 July, 2023',
    to: '15 July, 2023',
    status: 'Approved',
  },
  {
    id: 10,
    employeeName: 'Sophie Turner',
    leaveType: 'Casual Leave',
    reason: 'Attending Wedding',
    noOfDays: 2,
    from: '05 Jun, 2023',
    to: '06 Jun, 2023',
    status: 'Declined',
  },
];

const statusClasses: Record<LeaveStatus, string> = {
  Approved: 'bg-success/15 text-success',
  Pending: 'bg-warning/15 text-warning',
  Declined: 'bg-danger/10 text-danger',
  New: 'bg-secondary/10 text-secondary',
};

const LeaveTabel = () => {
  return (
    <div className="grid grid-cols-1 gap-5 mb-5">
      <div className="card">
        <div className="card-header flex justify-between items-center">
          <div className="relative">
            <input
              type="text"
              className="form-input form-input-sm ps-9"
              placeholder="Search for..."
            />
            <div className="absolute inset-y-0 start-0 flex items-center ps-3">
              <LuSearch className="size-4 text-default-500" />
            </div>
          </div>

          <button className="btn btn-sm bg-primary text-white flex items-center">
            <LuDownload className="size-4 me-1" /> Export
          </button>
        </div>
        <div className="flex flex-col">
          <div className="overflow-x-auto">
            <div className="min-w-full inline-block align-middle">
              <div className="overflow-hidden">
                <table className="min-w-full divide-y divide-default-200">
                  <thead className="bg-default-150">
                    <tr className="text-sm font-normal text-default-500 whitespace-nowrap">
                      <th className="px-3.5 py-3 text-start">#</th>
                      <th className="px-3.5 py-3 text-start">Employee Name</th>
                      <th className="px-3.5 py-3 text-start">Leave Type</th>
                      <th className="px-3.5 py-3 text-start">Reason</th>
                      <th className="px-3.5 py-3 text-start">No Of Days</th>
                      <th className="px-3.5 py-3 text-start">From</th>
                      <th className="px-3.5 py-3 text-start">To</th>
                      <th className="px-3.5 py-3 text-start">Status</th>
                      <th className="px-3.5 py-3 text-start">Action</th>
                    </tr>
                  </thead>

                  <tbody className="divide-y divide-default-200">
                    {leaveData.map(leave => (
                      <tr key={leave.id} className="text-default-800 font-normal">
                        <td className="px-3.5 py-2.5 whitespace-nowrap text-sm">
                          {leave.id.toString().padStart(2, '0')}
                        </td>
                        <td className="px-3.5 py-2.5 whitespace-nowrap text-sm">
                          {leave.employeeName}
                        </td>
                        <td className="px-3.5 py-2.5 whitespace-nowrap text-sm">
                          {leave.leaveType}
                        </td>
                        <td className="px-3.5 py-2.5 whitespace-nowrap text-sm">{leave.reason}</td>
                        <td className="px-3.5 py-2.5 whitespace-nowrap text-sm">
                          {leave.noOfDays}
                        </td>
                        <td className="px-3.5 py-2.5 whitespace-nowrap text-sm">{leave.from}</td>
                        <td className="px-3.5 py-2.5 whitespace-nowrap text-sm">{leave.to}</td>
                        <td className="px-3.5 py-2.5 whitespace-nowrap">
                          <span
                            className={`inline-flex items-center gap-x-1.5 py-0.5 px-2.5 rounded text-xs font-medium ${statusClasses[leave.status]}`}
                          >
                            {leave.status}
                          </span>
                        </td>
                        <td className="px-3.5 py-2.5 whitespace-nowrap">
                          <div className="flex items-center gap-2">
                            <Link
                              to="#"
                              className="btn size-8 bg-default-200 hover:bg-default-600 hover:text-white text-default-600"
                            >
                              <LuPencil className="size-4" />
                            </Link>

                            <Link
                              to="#"
                              className="btn size-8 bg-success/15 hover:bg-success hover:text-white text-success"
                            >
                              <LuCheck className="size-4" />
                            </Link>

                            <Link
                              to="#"
                              className="btn size-8 bg-danger/10 hover:bg-danger hover:text-white text-danger"
                              aria-haspopup="dialog"
                              aria-expanded="false"
                              aria-controls="hr-leave-delete-modal"
                              data-hs-overlay="#hr-leave-delete-modal"
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

          <div className="card-footer flex justify-between items-center">
            <p className="text-default-500 text-sm">
              Showing <b>{leaveData.length}</b> of <b>17</b> Results
            </p>
            <nav className="flex items-center gap-2" aria-label="Pagination">
              <button className="btn btn-sm border bg-transparent border-default-200 text-default-600 hover:bg-primary/10 hover:text-primary">
                <LuChevronLeft className="size-4 me-1" /> Prev
              </button>
              <button className="btn size-7.5 bg-primary text-white">1</button>
              <button className="btn size-7.5 bg-transparent border border-default-200 text-default-600 hover:bg-primary/10 hover:text-primary">
                2
              </button>
              <button className="btn btn-sm border bg-transparent border-default-200 text-default-600 hover:bg-primary/10 hover:text-primary">
                Next <LuChevronRight className="size-4 ms-1" />
              </button>
            </nav>
          </div>
        </div>
      </div>
    </div>
  );
};

export default LeaveTabel;
