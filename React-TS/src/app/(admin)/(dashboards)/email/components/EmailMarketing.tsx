import ApexChartClient from '@/components/client-wrapper/ApexChartClient';
import { LuEllipsis } from 'react-icons/lu';
import { Link } from 'react-router';
import { getEmailMarketingChart } from './data';

const EmailMarketing = () => {
  return (
    <div className="col-span-1">
      <div className="card">
        <div className="card-header">
          <h6 className="card-title">Email Marketing</h6>
          <div className="hs-dropdown relative inline-flex">
            <button
              type="button"
              className="hs-dropdown-toggle btn size-7.5 hover:bg-default-150"
              aria-haspopup="menu"
              aria-expanded="false"
              aria-label="Dropdown"
              hs-dropdown-placement="bottom-end"
            >
              <LuEllipsis className="size-4 text-default-600" />
            </button>

            <div
              className="hs-dropdown-menu"
              role="menu"
              aria-orientation="vertical"
              aria-labelledby="hs-dropdown-custom-icon-trigger"
            >
              <Link
                className="flex items-center gap-x-3.5 py-1.5 font-medium px-3 text-default-600 hover:bg-default-150 rounded"
                to="#"
              >
                This Year
              </Link>

              <Link
                className="flex items-center gap-x-3.5 py-1.5 font-medium px-3 text-default-600 hover:bg-default-150 rounded"
                to="#"
              >
                Last Year
              </Link>
            </div>
          </div>
        </div>

        <div className="card-body">
          <ApexChartClient
            getOptions={getEmailMarketingChart}
            series={getEmailMarketingChart().series}
            type="radialBar"
            height={345}
          />
        </div>
      </div>
    </div>
  );
};

export default EmailMarketing;
