import ApexChartClient from '@/components/client-wrapper/ApexChartClient';
import { getPresPectiveChart } from './data';

const PerspectiveChart = () => {
  return (
    <div className="lg:col-span-2 col-span-1">
      <div className="card">
        <div className="card-header">
          <h6 className="card-title">Platform Perspective</h6>

          <div className="flex">
            <select className="form-input form-input-sm border-default-400 bg-transparent border-dashed">
              <option>This Yearly</option>
              <option>1 Weekly</option>
              <option>1 Monthly</option>
              <option>3 Monthly</option>
              <option>6 Monthly</option>
              <option>This Yearly</option>
            </select>
          </div>
        </div>

        <div className="card-body">
          <ApexChartClient
            getOptions={getPresPectiveChart}
            series={getPresPectiveChart().series}
            type="treemap"
            height={252}
          />
        </div>
      </div>
    </div>
  );
};

export default PerspectiveChart;
