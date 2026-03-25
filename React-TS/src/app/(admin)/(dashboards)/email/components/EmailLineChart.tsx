import ApexChartClient from '@/components/client-wrapper/ApexChartClient';
import { getClickRate, getClickThrough, getOpenRate, getSentEmail } from './data';
import { LuGoal, LuMousePointerClick, LuRocket, LuSquareMousePointer } from 'react-icons/lu';

const EmailLineChart = () => {
  return (
    <div className="mb-5">
      <div className="card">
        <div className="card-body">
          <div className="grid grid-cols-1 gap-5 divide-y md:divide-x md:divide-y-0 md:grid-cols-2 lg:grid-cols-4 divide-default-200">
            <div className="py-5 md:pe-5 pe-0 md:border-e md:border-b-0 border-b border-default-200">
              <div className="grid grid-cols-3 mb-4">
                <div className="text-default-500 text-sm w-36 shrink-0">
                  <div className="flex items-center gap-1.5 mb-6">
                    <LuRocket className="size-4" />
                    <p className="uppercase">sent</p>
                  </div>
                  <h5 className="text-default-800 text-lg font-semibold">
                    <span className="counter-value" data-target="1452">
                      1,452
                    </span>
                  </h5>
                </div>

                <div className="col-span-2">
                  <ApexChartClient
                    getOptions={getSentEmail}
                    series={getSentEmail().series}
                    type="line"
                    height={80}
                  />
                </div>
              </div>
              <span className="text-default-500">238 Emails (Monthly)</span>
            </div>

            <div className="md:p-5 px-0 py-5  md:border-e md:border-b-0 border-b border-default-200">
              <div className="grid grid-cols-3 mb-4">
                <div className="text-default-500 text-sm w-36 shrink-0">
                  <div className="flex items-center gap-1.5 mb-6">
                    <LuMousePointerClick className="size-4" />
                    <p className="uppercase">Open Rate</p>
                  </div>
                  <h5 className="text-default-800 text-lg font-semibold">
                    <span data-target="92.74">92.74</span>%
                  </h5>
                </div>

                <div className="col-span-2">
                  <ApexChartClient
                    getOptions={getOpenRate}
                    series={getOpenRate().series}
                    type="line"
                    height={80}
                  />
                </div>
              </div>
              <span className="text-default-500">60 Opened (Monthly)</span>
            </div>

            <div className="md:p-5 px-0 py-5  md:border-e md:border-b-0 border-b border-default-200">
              <div className="grid grid-cols-3 mb-4">
                <div className="text-default-500 text-sm w-36 shrink-0">
                  <div className="flex items-center gap-1.5 mb-6">
                    <LuSquareMousePointer className="size-4" />
                    <p className="uppercase">Open Rate</p>
                  </div>
                  <h5 className="text-default-800 text-lg font-semibold">
                    <span data-target="3.79">3.79</span>%
                  </h5>
                </div>

                <div className="col-span-2">
                  <ApexChartClient
                    getOptions={getClickRate}
                    series={getClickRate().series}
                    type="line"
                    height={80}
                  />
                </div>
              </div>
              <span className="text-default-500">29 Clicks (Monthly)</span>
            </div>

            <div className="py-5 md:ps-5 ps-0">
              <div className="grid grid-cols-3 mb-4">
                <div className="text-default-500 text-sm w-36 shrink-0">
                  <div className="flex items-center gap-1.5 mb-6">
                    <LuGoal className="size-4" />
                    <p className="uppercase">Clicks Through</p>
                  </div>
                  <h5 className="text-default-800 text-lg font-semibold">
                    <span data-target="4.06">4.06</span>%
                  </h5>
                </div>

                <div className="col-span-2">
                  <ApexChartClient
                    getOptions={getClickThrough}
                    series={getClickThrough().series}
                    type="line"
                    height={80}
                  />
                </div>
              </div>
              <span className="text-default-500">29 Click Through (Monthly)</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default EmailLineChart;
