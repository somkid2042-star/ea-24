import React from 'react';
import { LuClock, LuOctagonX, LuRefreshCw } from 'react-icons/lu';

type WorkDetail = {
  id: number;
  value: number;
  label: string;
  icon: React.ElementType;
  textColor: string;
  bgColor: string;
};

const workDetails: WorkDetail[] = [
  {
    id: 1,
    value: 187,
    label: 'Approved Hours',
    icon: LuClock,
    textColor: 'text-info',
    bgColor: 'bg-info/10',
  },
  {
    id: 2,
    value: 19,
    label: 'Rejected Hours',
    icon: LuOctagonX,
    textColor: 'text-danger',
    bgColor: 'bg-danger/10',
  },
  {
    id: 3,
    value: 32,
    label: 'Pending Hours',
    icon: LuRefreshCw,
    textColor: 'text-warning',
    bgColor: 'bg-warning/10',
  },
];

const EmployeeWorkDetails = () => {
  return (
    <div className="grid lg:grid-cols-3 grid-cols-1 gap-5 mb-5">
      {workDetails.map(detail => {
        const Icon = detail.icon;
        return (
          <div className="card" key={detail.id}>
            <div className="card-body">
              <div className="flex items-center gap-3">
                <div className={`btn ${detail.textColor} ${detail.bgColor} size-12`}>
                  <Icon className="size-6" />
                </div>
                <div>
                  <h5 className="mb-1 text-base text-heading font-semibold">
                    <span className="counter-value">{detail.value}</span>
                  </h5>
                  <p className="text-default-500">{detail.label}</p>
                </div>
              </div>
            </div>
          </div>
        );
      })}
    </div>
  );
};

export default EmployeeWorkDetails;
