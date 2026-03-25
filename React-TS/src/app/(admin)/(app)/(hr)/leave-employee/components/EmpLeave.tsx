import { Link } from 'react-router';
import {
  LuChevronLeft,
  LuChevronRight,
  LuDownload,
  LuInfo,
  LuPencil,
  LuSearch,
} from 'react-icons/lu';

type Leave = {
  id: number;
  leaveType: string;
  reason: string;
  days: number;
  from: string;
  to: string;
  approvedBy: string;
  status: 'Approved' | 'Pending' | 'Declined';
};

const leavesData: Leave[] = [
  {
    id: 1,
    leaveType: 'Medical Leave',
    reason: 'Going to Hospital',
    days: 2,
    from: '11 Oct, 2023',
    to: '12 Oct, 2023',
    approvedBy: 'Paula Keenan',
    status: 'Approved',
  },
  {
    id: 2,
    leaveType: 'Casual Leave',
    reason: 'Going to Family Function',
    days: 1,
    from: '07 Sept, 2023',
    to: '07 Sept, 2023',
    approvedBy: 'Admin',
    status: 'Pending',
  },
  {
    id: 3,
    leaveType: 'Casual Leave',
    reason: 'Going to Holiday',
    days: 6,
    from: '11 Jun, 2023',
    to: '16 Jun, 2023',
    approvedBy: 'Admin',
    status: 'Declined',
  },
  {
    id: 4,
    leaveType: 'Sick Leave',
    reason: 'Attend Birthday party',
    days: 1,
    from: '15 July, 2023',
    to: '15 July, 2023',
    approvedBy: 'Paula Keenan',
    status: 'Approved',
  },
  {
    id: 5,
    leaveType: 'Sick Leave',
    reason: 'Personal',
    days: 2,
    from: '19 Aug, 2023',
    to: '20 Aug, 2023',
    approvedBy: 'Paula Keenan',
    status: 'Declined',
  },
  {
    id: 6,
    leaveType: 'Casual Leave',
    reason: 'Going to Family Function',
    days: 1,
    from: '14 Feb, 2022',
    to: '14 Feb, 2022',
    approvedBy: 'Admin',
    status: 'Approved',
  },
  {
    id: 7,
    leaveType: 'Medical Leave',
    reason: 'Medical Emergency',
    days: 4,
    from: '23 Jan, 2023',
    to: '26 Jan, 2023',
    approvedBy: 'Paula Keenan',
    status: 'Pending',
  },
  {
    id: 8,
    leaveType: 'Casual Leave',
    reason: 'Personal',
    days: 2,
    from: '16 Dec, 2023',
    to: '17 Dec, 2023',
    approvedBy: 'Paula Keenan',
    status: 'Declined',
  },
  {
    id: 9,
    leaveType: 'Casual Leave',
    reason: 'Going to Holiday',
    days: 5,
    from: '29 Nov, 2023',
    to: '03 Dec, 2023',
    approvedBy: 'Admin',
    status: 'Approved',
  },
  {
    id: 10,
    leaveType: 'Sick Leave',
    reason: 'Going to Hospital',
    days: 1,
    from: '15 Oct, 2023',
    to: '15 Oct, 2023',
    approvedBy: 'Paula Keenan',
    status: 'Approved',
  },
];

const statusClass = {
  Approved:
    'inline-flex items-center gap-x-1.5 py-0.5 px-2.5 rounded text-xs font-medium bg-success/15 text-success',
  Pending:
    'inline-flex items-center gap-x-1.5 py-0.5 px-2.5 rounded text-xs font-medium bg-warning/15 text-warning',
  Declined:
    'inline-flex items-center gap-x-1.5 py-0.5 px-2.5 rounded text-xs font-medium bg-danger/10 text-danger',
};

const EmpLeave = () => {
  return (
    <div className="grid grid-cols-1 gap-5 mb-5">
      <div className="card">
        <div className="card-header">
          <div className="relative">
            <input
              type="email"
              className="ps-11 form-input form-input-sm"
              placeholder="Search for...."
            />
            <div className="absolute inset-y-0 start-0 flex items-center ps-3">
              <LuSearch className="size-4 flex items-center text-default-500" />
            </div>
          </div>

          <button className="btn btn-sm bg-primary text-white">
            <LuDownload className="size-3.5 me-1" /> Export
          </button>
        </div>

        <div className="flex flex-col">
          <div className="overflow-x-auto">
            <div className="min-w-full inline-block align-middle">
              <div className="overflow-hidden">
                <table className="min-w-full divide-y divide-default-200">
                  <thead className="bg-default-150">
                    <tr className="text-sm font-normal whitespace-nowrap text-default-500">
                      <th className="px-3.5 py-3 text-start">#</th>
                      <th className="px-3.5 py-3 text-start">Leave Type</th>
                      <th className="px-3.5 py-3 text-start">Reason</th>
                      <th className="px-3.5 py-3 text-start">No Of Days</th>
                      <th className="px-3.5 py-3 text-start">From</th>
                      <th className="px-3.5 py-3 text-start">To</th>
                      <th className="px-3.5 py-3 text-start">Approved By</th>
                      <th className="px-3.5 py-3 text-start">Status</th>
                      <th className="px-3.5 py-3 text-end">Action</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-default-200">
                    {leavesData.map(leave => (
                      <tr key={leave.id} className="text-default-800 font-normal whitespace-nowrap">
                        <td className="px-3.5 py-2.5 text-sm">
                          {String(leave.id).padStart(2, '0')}
                        </td>
                        <td className="px-3.5 py-2.5 text-sm">{leave.leaveType}</td>
                        <td className="px-3.5 py-2.5 text-sm">{leave.reason}</td>
                        <td className="px-3.5 py-2.5 text-sm">{leave.days}</td>
                        <td className="px-3.5 py-2.5 text-sm">{leave.from}</td>
                        <td className="px-3.5 py-2.5 text-sm">{leave.to}</td>
                        <td className="px-3.5 py-2.5 text-sm">{leave.approvedBy}</td>
                        <td className="px-3.5 py-2.5">
                          <span className={statusClass[leave.status]}>{leave.status}</span>
                        </td>
                        <td className="px-3.5 py-2.5 flex items-center justify-end gap-2">
                          {leave.status === 'Pending' && (
                            <Link
                              to="#"
                              className="btn size-8 bg-default-200 hover:bg-default-600 hover:text-white transition-all text-default-600"
                            >
                              <LuPencil className="size-4" />
                            </Link>
                          )}
                          <Link
                            to="#"
                            className="btn size-8 bg-primary/20 hover:bg-primary text-primary hover:text-white"
                          >
                            <LuInfo className="size-4" />
                          </Link>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          </div>

          <div className="card-footer">
            <p className="text-default-500 text-sm">
              Showing <b>{leavesData.length}</b> of <b>17</b> Results
            </p>
            <nav className="flex items-center gap-2" aria-label="Pagination">
              <button
                type="button"
                className="btn btn-sm border bg-transparent border-default-200 text-default-600 hover:bg-primary/10 hover:text-primary hover:border-primary/10"
              >
                <LuChevronLeft className="size-4 me-1" /> Prev
              </button>
              <button
                type="button"
                className="btn size-7.5 bg-transparent border border-default-200 text-default-600 hover:bg-primary/10 hover:text-primary hover:border-primary/10"
              >
                1
              </button>
              <button type="button" className="btn size-7.5 bg-primary text-white">
                2
              </button>
              <button
                type="button"
                className="btn size-7.5 bg-transparent border border-default-200 text-default-600 hover:bg-primary/10 hover:text-primary hover:border-primary/10"
              >
                3
              </button>
              <button
                type="button"
                className="btn btn-sm border bg-transparent border-default-200 text-default-600 hover:bg-primary/10 hover:text-primary hover:border-primary/10"
              >
                Next <LuChevronRight className="size-4 ms-1" />
              </button>
            </nav>
          </div>
        </div>
      </div>
    </div>
  );
};

export default EmpLeave;
