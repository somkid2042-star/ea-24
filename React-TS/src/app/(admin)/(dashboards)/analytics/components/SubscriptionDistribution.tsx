import ApexChartClient from '@/components/client-wrapper/ApexChartClient';
import { getSubscriptionDistribution } from './data';

const SubscriptionDistribution = () => {
  return (
    <div className="card">
      <div className="card-header">
        <h6 className="card-title">Subscription Distribution</h6>
      </div>

      <div className="card-body">
        <ApexChartClient
          getOptions={getSubscriptionDistribution}
          series={getSubscriptionDistribution().series}
          type="donut"
          height={290}
        />
      </div>
    </div>
  );
};

export default SubscriptionDistribution;
