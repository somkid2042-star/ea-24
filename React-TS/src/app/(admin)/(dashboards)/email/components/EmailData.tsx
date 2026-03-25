import ApexChartClient from '@/components/client-wrapper/ApexChartClient';
import { getEmailDataChart } from './data';

const EmailData = () => {
  return (
    <div className="lg:col-span-2 col-span-1">
      <div className="card">
        <div className="card-header">
          <h6 className="card-title">Email Data</h6>
          <div>
            <select className="form-input form-input-sm">
              <option defaultValue="">This Yearly</option>
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
            getOptions={getEmailDataChart}
            series={getEmailDataChart().series}
            type="line"
            height={333}
          />
        </div>
      </div>
    </div>
  );
};

export default EmailData;
