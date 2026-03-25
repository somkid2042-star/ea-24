import { Link } from 'react-router';
import { LuEllipsisVertical, LuMoveDownLeft, LuMoveUpLeft, LuMoveUpRight } from 'react-icons/lu';
import SimpleBar from 'simplebar-react';

type PayrollStatus = 'Paid' | 'Pending' | 'Cancelled';

type PayrollItem = {
  id: number;
  name: string;
  amount: string;
  status: PayrollStatus;
  icon: 'upRight' | 'upLeft' | 'downLeft';
};

const payrollData: PayrollItem[] = [
  { id: 1, name: 'Christopher Horn', amount: '$145.32', status: 'Paid', icon: 'upRight' },
  { id: 2, name: 'Richard Peters', amount: '$4512.99', status: 'Pending', icon: 'upLeft' },
  { id: 3, name: 'James Perez', amount: '$879.99', status: 'Paid', icon: 'upLeft' },
  { id: 4, name: 'Myrtle Velez', amount: '$978.14', status: 'Cancelled', icon: 'upRight' },
  { id: 5, name: 'Brad Castillo', amount: '$412.59', status: 'Pending', icon: 'upLeft' },
  { id: 6, name: 'Robert Jump', amount: '$666.99', status: 'Paid', icon: 'upLeft' },
  { id: 7, name: 'Myrtle Velez', amount: '$978.14', status: 'Cancelled', icon: 'upRight' },
  { id: 8, name: 'Christopher Horn', amount: '$145.32', status: 'Paid', icon: 'upRight' },
  { id: 9, name: 'Richard Peters', amount: '$4512.99', status: 'Pending', icon: 'downLeft' },
  { id: 10, name: 'James Perez', amount: '$879.99', status: 'Paid', icon: 'downLeft' },
];

const statusColors: Record<PayrollStatus, string> = {
  Paid: 'bg-success/15 text-success',
  Pending: 'bg-warning/15 text-warning',
  Cancelled: 'bg-danger/15 text-danger',
};

const iconMap = {
  upRight: <LuMoveUpRight className="size-4 text-danger" />,
  upLeft: <LuMoveUpLeft className="size-4 text-success" />,
  downLeft: <LuMoveDownLeft className="size-4 text-success" />,
};

const RecentPayroll = () => {
  return (
    <div className="card">
      <div className="card-header flex justify-between items-center">
        <h6 className="card-title">Recent Payroll</h6>

        <div className="hs-dropdown relative inline-flex">
          <button
            type="button"
            className="hs-dropdown-toggle btn size-7.5 hover:bg-default-150"
            aria-haspopup="menu"
            aria-expanded="false"
            aria-label="Dropdown"
          >
            <LuEllipsisVertical className="size-4 text-default-500" />
          </button>

          <div
            className="hs-dropdown-menu transition-[opacity,margin] duration hs-dropdown-open:opacity-100 opacity-0 hidden min-w-40 bg-card shadow-md rounded-lg z-30 mt-2 p-2"
            role="menu"
          >
            <div className="text-sm">
              <Link
                to=""
                className="flex items-center gap-x-3.5 py-1.5 font-medium px-3 text-default-600 hover:bg-default-150 rounded"
              >
                Today
              </Link>
              <Link
                to=""
                className="flex items-center gap-x-3.5 py-1.5 font-medium px-3 text-default-600 hover:bg-default-150 rounded"
              >
                Yesterday
              </Link>
              <Link
                to=""
                className="flex items-center gap-x-3.5 py-1.5 font-medium px-3 text-default-600 hover:bg-default-150 rounded"
              >
                Thursday
              </Link>
            </div>
          </div>
        </div>
      </div>

      <SimpleBar className="h-60">
        <div className="card-body">
          <div className="flex flex-col gap-3.5">
            {payrollData.map(item => (
              <div key={item.id} className="flex flex-wrap items-center gap-3 text-sm">
                {iconMap[item.icon]}
                <h6 className="text-default-800 font-semibold grow">{item.name}</h6>
                <h6 className="text-default-900">{item.amount}</h6>
                <div>
                  <span
                    className={`py-0.5 px-2.5 rounded text-xs font-medium ${statusColors[item.status]}`}
                  >
                    {item.status}
                  </span>
                </div>
              </div>
            ))}
          </div>
        </div>
      </SimpleBar>
    </div>
  );
};

export default RecentPayroll;
