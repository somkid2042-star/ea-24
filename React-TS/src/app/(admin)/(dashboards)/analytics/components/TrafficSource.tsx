import { Link } from 'react-router';
import React from 'react';

type TrafficItem = {
  id: number;
  label: string;
  value: string;
  percentage: number;
  color: string;
};

const trafficData: TrafficItem[] = [
  { id: 1, label: 'Google', value: '54,963', percentage: 89, color: 'bg-primary' },
  { id: 2, label: 'Meta', value: '30,478', percentage: 55, color: 'bg-sky-500' },
  { id: 3, label: 'Social Media', value: '54,963', percentage: 81, color: 'bg-warning' },
  { id: 4, label: 'Direct Message', value: '54,963', percentage: 63, color: 'bg-success' },
  { id: 5, label: 'Others', value: '54,963', percentage: 25, color: 'bg-default-600' },
];

const TrafficSource: React.FC = () => {
  return (
    <div className="card">
      <div className="card-header flex justify-between items-center">
        <h6 className="card-title">Traffic Source</h6>
        <Link to="#" className="text-primary underline">
          See More
        </Link>
      </div>

      <div className="card-body">
        <div className="flex flex-col gap-5">
          {trafficData.map(item => (
            <div key={item.id}>
              <div className="flex items-center justify-between gap-4 mb-2 text-sm">
                <h6 className="text-default-900">{item.label}</h6>
                <span className="text-default-500">{item.value}</span>
              </div>
              <div className="w-full h-3.5 rounded bg-default-200">
                <div
                  className={`h-3.5 rounded ${item.color}`}
                  style={{ width: `${item.percentage}%` }}
                ></div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

export default TrafficSource;
