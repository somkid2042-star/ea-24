import ApexChartClient from '@/components/client-wrapper/ApexChartClient';
import { LuEllipsisVertical, LuInfo } from 'react-icons/lu';
import { Link } from 'react-router';
import { getDailyVisitInsightsChart, getSatisfactionChart, getUserDeviceChart } from './data';

const UserChart = () => {
  return (
    <div className="grid lg:grid-cols-3 grid-cols-1 gap-5 mb-5">
      <div className="card">
        <div className="card-header">
          <div className="flex items-center gap-1.5">
            <h6 className="card-title">User Device</h6>
            <div className="hs-tooltip [--placement:top]">
              <button type="button" className="hs-tooltip-toggle">
                <LuInfo className="size-4 text-default-500 mt-2" />
                <span
                  className="hs-tooltip-content max-w-80 hs-tooltip-shown:opacity-100 hs-tooltip-shown:visible opacity-0 transition-opacity inline-block absolute invisible z-50 py-1 px-2 bg-default-900 text-xs font-medium text-default-100 rounded-md shadow-2xs"
                  role="tooltip"
                >
                  You can see your number of desktop, mobile, and tablet users.
                </span>
              </button>
            </div>
          </div>

          <div className="hs-dropdown relative inline-flex">
            <button
              type="button"
              className="hs-dropdown-toggle btn size-7.5 hover:bg-default-150"
              aria-haspopup="menu"
              aria-expanded="false"
              aria-label="Dropdown"
              hs-dropdown-placement="bottom-end"
            >
              <LuEllipsisVertical className="size-4 text-default-500" />
            </button>

            <div className="hs-dropdown-menu" role="menu">
              <Link
                className="flex items-center gap-x-3.5 py-1.5 font-medium px-3 text-default-600 hover:bg-default-150 rounded"
                to="#"
              >
                1 Weekly
              </Link>
              <Link
                className="flex items-center gap-x-3.5 py-1.5 font-medium px-3 text-default-600 hover:bg-default-150 rounded"
                to="#"
              >
                1 Monthly
              </Link>
              <Link
                className="flex items-center gap-x-3.5 py-1.5 font-medium px-3 text-default-600 hover:bg-default-150 rounded"
                to="#"
              >
                3 Monthly
              </Link>
              <Link
                className="flex items-center gap-x-3.5 py-1.5 font-medium px-3 text-default-600 hover:bg-default-150 rounded"
                to="#"
              >
                6 Monthly
              </Link>
              <Link
                className="flex items-center gap-x-3.5 py-1.5 font-medium px-3 text-default-600 hover:bg-default-150 rounded"
                to="#"
              >
                This Yearly
              </Link>
            </div>
          </div>
        </div>
        <div className="card-body">
          <ApexChartClient
            getOptions={getUserDeviceChart}
            series={getUserDeviceChart().series}
            type="radar"
            height={230}
          />
        </div>
      </div>

      <div className="card">
        <div className="card-header">
          <div className="flex items-center gap-1.5">
            <h6 className="card-title">Satisfaction Level</h6>
            <div className="hs-tooltip [--placement:top]">
              <button type="button" className="hs-tooltip-toggle">
                <LuInfo className="size-4 text-default-500 mt-2" />
                <span
                  className="hs-tooltip-content max-w-80 hs-tooltip-shown:opacity-100 hs-tooltip-shown:visible opacity-0 transition-opacity inline-block absolute invisible z-30 py-1 px-2 bg-default-900 text-xs font-medium text-default-100 rounded-md shadow-2xs "
                  role="tooltip"
                >
                  The 1-to-5 satisfaction scale is used for measuring customer satisfaction
                </span>
              </button>
            </div>
          </div>

          <div className="hs-dropdown relative inline-flex">
            <button
              type="button"
              className="hs-dropdown-toggle btn size-7.5 hover:bg-default-150"
              aria-haspopup="menu"
              aria-expanded="false"
              aria-label="Dropdown"
              hs-dropdown-placement="bottom-end"
            >
              <LuEllipsisVertical className="size-4 text-default-500" />
            </button>

            <div className="hs-dropdown-menu" role="menu">
              <Link
                className="flex items-center gap-x-3.5 py-1.5 font-medium px-3 text-default-600 hover:bg-default-150 rounded"
                to="#"
              >
                1 Weekly
              </Link>
              <Link
                className="flex items-center gap-x-3.5 py-1.5 font-medium px-3 text-default-600 hover:bg-default-150 rounded"
                to="#"
              >
                1 Monthly
              </Link>
              <Link
                className="flex items-center gap-x-3.5 py-1.5 font-medium px-3 text-default-600 hover:bg-default-150 rounded"
                to="#"
              >
                3 Monthly
              </Link>
              <Link
                className="flex items-center gap-x-3.5 py-1.5 font-medium px-3 text-default-600 hover:bg-default-150 rounded"
                to="#"
              >
                6 Monthly
              </Link>
              <Link
                className="flex items-center gap-x-3.5 py-1.5 font-medium px-3 text-default-600 hover:bg-default-150 rounded"
                to="#"
              >
                This Yearly
              </Link>
            </div>
          </div>
        </div>

        <div className="card-body">
          <ApexChartClient
            getOptions={getSatisfactionChart}
            series={getSatisfactionChart().series}
            type="radialBar"
            height={445}
          />
          <p className="text-center text-15xl">Based on Likes 💖</p>
        </div>
      </div>

      <div className="card">
        <div className="card-header">
          <div className="flex items-center gap-1.5">
            <h6 className="card-title">Daily Visit Insights </h6>
            <div className="hs-tooltip [--placement:top]">
              <button type="button" className="hs-tooltip-toggle">
                <LuInfo className="size-4 text-default-500 mt-2" />
                <span
                  className="hs-tooltip-content max-w-80 hs-tooltip-shown:opacity-100 hs-tooltip-shown:visible opacity-0 transition-opacity inline-block absolute invisible z-30 py-1 px-2 bg-default-900 text-xs font-medium text-default-100 rounded-md shadow-2xs"
                  role="tooltip"
                >
                  Analyst or business user discovering a pattern in data or a relationship between
                  variables
                </span>
              </button>
            </div>
          </div>

          <div className="hs-dropdown relative inline-flex">
            <button
              type="button"
              className="hs-dropdown-toggle btn size-7.5 hover:bg-default-150"
              aria-haspopup="menu"
              aria-expanded="false"
              aria-label="Dropdown"
              hs-dropdown-placement="bottom-end"
            >
              <LuEllipsisVertical className="size-4 text-default-500" />
            </button>

            <div className="hs-dropdown-menu" role="menu">
              <Link
                className="flex items-center gap-x-3.5 py-1.5 font-medium px-3 text-default-600 hover:bg-default-150 rounded"
                to="#"
              >
                1 Weekly
              </Link>
              <Link
                className="flex items-center gap-x-3.5 py-1.5 font-medium px-3 text-default-600 hover:bg-default-150 rounded"
                to="#"
              >
                1 Monthly
              </Link>
              <Link
                className="flex items-center gap-x-3.5 py-1.5 font-medium px-3 text-default-600 hover:bg-default-150 rounded"
                to="#"
              >
                3 Monthly
              </Link>
              <Link
                className="flex items-center gap-x-3.5 py-1.5 font-medium px-3 text-default-600 hover:bg-default-150 rounded"
                to="#"
              >
                6 Monthly
              </Link>
              <Link
                className="flex items-center gap-x-3.5 py-1.5 font-medium px-3 text-default-600 hover:bg-default-150 rounded"
                to="#"
              >
                This Yearly
              </Link>
            </div>
          </div>
        </div>

        <div className="card-body">
          <ApexChartClient
            getOptions={getDailyVisitInsightsChart}
            series={getDailyVisitInsightsChart().series}
            type="bar"
            height={240}
          />
        </div>
      </div>
    </div>
  );
};

export default UserChart;
