import React from 'react';
import { LuCalendarCheck, LuCodepen, LuFileChartColumn, LuLoader } from 'react-icons/lu';

type LeaveCardItem = {
  id: number;
  title: string;
  value: string;
  description: string;
  icon: React.ElementType;
  textColor: string;
  bgColor: string;
};

const leaveData: LeaveCardItem[] = [
  {
    id: 1,
    title: 'Today/Presents Leave',
    value: '18/60',
    description: 'Today/Presents Leave',
    icon: LuFileChartColumn,
    textColor: 'text-primary',
    bgColor: 'bg-primary/10',
  },
  {
    id: 2,
    title: 'Today Leaves',
    value: '5',
    description: 'Today Leaves',
    icon: LuCalendarCheck,
    textColor: 'text-success',
    bgColor: 'bg-success/10',
  },
  {
    id: 3,
    title: 'Unplanned Leaves',
    value: '0',
    description: 'Unplanned Leaves',
    icon: LuCodepen,
    textColor: 'text-secondary',
    bgColor: 'bg-secondary/10',
  },
  {
    id: 4,
    title: 'Remaining Leave',
    value: '11',
    description: 'Remaining Leave',
    icon: LuLoader,
    textColor: 'text-warning',
    bgColor: 'bg-warning/10',
  },
];

const LeaveCard = () => {
  return (
    <div className="grid lg:grid-cols-4 md:grid-cols-2 grid-cols-1 gap-5 mb-5">
      {leaveData.map(({ id, value, description, icon: Icon, textColor, bgColor }) => (
        <div key={id} className="card">
          <div className="card-body">
            <div className="flex items-center gap-3">
              <div className={`btn ${textColor} ${bgColor} size-12`}>
                <Icon className="size-6" />
              </div>
              <div>
                <h5 className="mb-1 text-base text-heading font-semibold">{value}</h5>
                <p className="text-default-500">{description}</p>
              </div>
            </div>
          </div>
        </div>
      ))}
    </div>
  );
};

export default LeaveCard;
