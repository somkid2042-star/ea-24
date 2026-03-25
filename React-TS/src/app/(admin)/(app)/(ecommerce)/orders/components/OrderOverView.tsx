import ApexChartClient from '@/components/client-wrapper/ApexChartClient';
import { getOrderOverViewChart } from './data';

const OrderOverView = () => {
  return (
    <div className="lg:col-span-2 col-span-1">
      <div className="card">
        <div className="card-header">
          <h6 className="car-title">Orders Overview</h6>
        </div>

        <div className="card-body">
          <ApexChartClient
            getOptions={getOrderOverViewChart}
            series={getOrderOverViewChart().series}
            type="bar"
            height={190}
          />
        </div>
      </div>
    </div>
  );
};

export default OrderOverView;
