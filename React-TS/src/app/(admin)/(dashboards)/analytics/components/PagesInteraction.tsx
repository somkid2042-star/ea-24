import ApexChartClient from '@/components/client-wrapper/ApexChartClient';
import { getPagesInteraction } from './data';

const PagesInteraction = () => {
  return (
    <div className="lg:col-span-7 col-span-1">
      <div className="card">
        <div className="card-header">
          <h6 className="card-title">Pages Interaction</h6>

          <button>
            <select className="bg-default-200 text-default-600 form-input form-input-sm">
              <option defaultValue="">This Yearly</option>
              <option>1 Weekly</option>
              <option>1 Monthly</option>
              <option>3 Monthly</option>
              <option>6 Monthly</option>
              <option>This Yearly</option>
            </select>
          </button>
        </div>

        <div className="card-body">
          <ApexChartClient
            getOptions={getPagesInteraction}
            series={getPagesInteraction().series}
            type="bar"
            height={350}
          />
        </div>
      </div>
    </div>
  );
};

export default PagesInteraction;
