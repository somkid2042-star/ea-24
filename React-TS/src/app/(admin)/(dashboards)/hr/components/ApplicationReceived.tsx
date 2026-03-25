import ApexChartClient from '@/components/client-wrapper/ApexChartClient';
import { getApplicationReceivedChart } from './data';

const ApplicationReceived = () => {
  return (
    <div className="col-span-1">
      <div className="card">
        <div className="card-body">
          <div className="flex justify-between">
            <h6 className="card-title">Application Received</h6>

            <div className="flex gap-2">
              <div className="btn size-7.5 bg-primary rounded text-white text-xs">All</div>
              <div className="btn size-7.5 bg-primary/20 hover:bg-primary hover:text-white rounded text-primary text-xs">
                1M
              </div>
              <div className="btn size-7.5 bg-primary/20 hover:bg-primary hover:text-white rounded text-primary text-xs">
                6M
              </div>
              <div className="btn size-7.5 bg-primary/20 hover:bg-primary hover:text-white rounded text-primary text-xs">
                1Y
              </div>
            </div>
          </div>
          <ApexChartClient
            getOptions={getApplicationReceivedChart}
            series={getApplicationReceivedChart().series}
            type="line"
            height={312}
          />
        </div>
      </div>
    </div>
  );
};

export default ApplicationReceived;
