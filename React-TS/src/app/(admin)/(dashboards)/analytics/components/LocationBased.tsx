import ApexChartClient from '@/components/client-wrapper/ApexChartClient';
import { LuMoveRight } from 'react-icons/lu';
import { getLocationChart } from './data';

const LocationBased = () => {
  return (
    <div className="lg:col-span-5 col-span-1">
      <div className="card">
        <div className="card-header">
          <h6 className="card-title">Location-Based Response Times</h6>
          <button
            type="button"
            className="btn btn-sm bg-primary/20 text-primary text-nowrap hover:bg-primary hover:text-white"
          >
            View More
            <LuMoveRight className="size-4" />
          </button>
        </div>

        <div className="card-body">
          <ApexChartClient
            getOptions={getLocationChart}
            series={getLocationChart().series}
            type="line"
            height={350}
          />
        </div>
      </div>
    </div>
  );
};

export default LocationBased;
