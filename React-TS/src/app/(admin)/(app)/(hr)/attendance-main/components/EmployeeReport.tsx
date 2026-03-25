import React from 'react';
import { LuBriefcase, LuUserCheck, LuUsers, LuUserX } from 'react-icons/lu';

type ReportCard = {
  id: number;
  title: string;
  value: number;
  icon: React.ElementType;
  color: 'info' | 'danger' | 'success' | 'primary';
};

const reports: ReportCard[] = [
  {
    id: 1,
    title: 'Total Employee',
    value: 43,
    icon: LuUsers,
    color: 'info',
  },
  {
    id: 2,
    title: 'Absent Employee (Today)',
    value: 6,
    icon: LuUserX,
    color: 'danger',
  },
  {
    id: 3,
    title: 'Present Employee (Today)',
    value: 32,
    icon: LuUserCheck,
    color: 'success',
  },
  {
    id: 4,
    title: 'Working Days (Current Month)',
    value: 22,
    icon: LuBriefcase,
    color: 'primary',
  },
];

const EmployeeReport = () => {
  return (
    <div className="grid lg:grid-cols-4 md:grid-cols-2 grid-cols-1 gap-5 mb-5">
      {reports.map(({ id, title, value, icon: Icon, color }) => (
        <div key={id} className="card">
          <div className="card-body">
            <div className="flex items-center gap-3">
              <div className={`btn text-${color} bg-${color}/10 size-12`}>
                <Icon className="size-6" />
              </div>
              <div>
                <h5 className="mb-1 text-base text-heading font-semibold">
                  <span className="counter-value">{value}</span>
                </h5>
                <p className="text-default-500">{title}</p>
              </div>
            </div>
          </div>
        </div>
      ))}
    </div>
  );
};

export default EmployeeReport;
