import ApexChartClient from '@/components/client-wrapper/ApexChartClient';
import { getAnalyticsReports } from './data';

const AnalyticsReports = () => {
  return (
    <div className="card">
      <div className="card-header mb-4">
        <h6 className="card-title">Analytics Reports</h6>
      </div>

      <div className="card-body">
        <ApexChartClient
          getOptions={getAnalyticsReports}
          series={getAnalyticsReports().series}
          type="line"
          height={260}
        />
      </div>
    </div>
  );
};

export default AnalyticsReports;
