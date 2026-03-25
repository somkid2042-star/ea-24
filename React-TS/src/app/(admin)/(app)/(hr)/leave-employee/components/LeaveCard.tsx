import React from 'react';
import { LuAnchor, LuCalendarDays, LuFileChartColumn, LuStethoscope } from 'react-icons/lu';

type LeaveType = {
  id: number;
  icon: React.ReactNode;
  count: number;
  label: string;
  colorClass: string;
};

const leaveData: LeaveType[] = [
  {
    id: 1,
    icon: <LuFileChartColumn size={24} />,
    count: 23,
    label: 'Total Leave Balance',
    colorClass: 'text-danger bg-danger/10',
  },
  {
    id: 2,
    icon: <LuStethoscope size={24} />,
    count: 4,
    label: 'Medical Leave',
    colorClass: 'text-secondary bg-secondary/10',
  },
  {
    id: 3,
    icon: <LuCalendarDays size={24} />,
    count: 12,
    label: 'Annual Leave',
    colorClass: 'text-success bg-success/10',
  },
  {
    id: 4,
    icon: <LuAnchor size={24} />,
    count: 11,
    label: 'Remaining Leave',
    colorClass: 'text-info bg-info/10',
  },
];

const LeaveCard = () => {
  return (
    <div className="grid lg:grid-cols-4 md:grid-cols-2 grid-cols-1 gap-5 mb-5">
      {leaveData.map(leave => (
        <div key={leave.id} className="card">
          <div className="card-body">
            <div className="flex items-center gap-3">
              <div className={`btn ${leave.colorClass} size-12 flex items-center justify-center`}>
                {leave.icon}
              </div>
              <div>
                <h5 className="mb-1 text-base text-heading font-semibold">
                  <span className="counter-value">{leave.count}</span>
                </h5>
                <p className="text-default-500">{leave.label}</p>
              </div>
            </div>
          </div>
        </div>
      ))}
    </div>
  );
};

export default LeaveCard;
