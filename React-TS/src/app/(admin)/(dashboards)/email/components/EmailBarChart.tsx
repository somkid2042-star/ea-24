import ApexChartClient from '@/components/client-wrapper/ApexChartClient';
import { LuInfo } from 'react-icons/lu';
import {
  getDeliveredRate,
  getHardBounceRate,
  getSpanReportRate,
  getUnsubscribedRate,
} from './data';

type EmailCardData = {
  title: string;
  value: number;
  getOptions: () => ApexCharts.ApexOptions;
  tooltip?: string;
};

const EmailCard = ({ title, tooltip, value, getOptions }: EmailCardData) => {
  return (
    <div className="card">
      <div className="card-body">
        <div className="flex items-center justify-between mb-3">
          <p className="text-default-500">{title}</p>
          {tooltip && (
            <div className="hs-tooltip [--placement:top]">
              <button type="button" className="hs-tooltip-toggle">
                <LuInfo className="size-4 text-default-500 mt-2" />
                <span
                  className="hs-tooltip-content hs-tooltip-shown:opacity-100 hs-tooltip-shown:visible opacity-0 transition-opacity inline-block absolute invisible z-30 py-1 px-2 bg-default-900 text-xs font-medium text-default-100 rounded-md shadow-2xs"
                  role="tooltip"
                >
                  {tooltip}
                </span>
              </button>
            </div>
          )}
        </div>

        <h5 className="mb-4 text-default-800 text-lg font-semibold">
          <span data-target={value}>{value}</span>%
        </h5>
        <ApexChartClient
          getOptions={getOptions}
          series={getOptions().series}
          type="bar"
          height={80}
          className="w-87 h-20"
        />
      </div>
    </div>
  );
};

const EmailBarChart = () => {
  const cards: EmailCardData[] = [
    {
      title: 'Delivered Rate',
      value: 100,
      getOptions: getDeliveredRate,
      tooltip:
        'Taking the number of delivered emails and dividing it by the total number of emails sent',
    },
    {
      title: 'Hard Bounce Rate',
      value: 89,
      getOptions: getHardBounceRate,
      tooltip:
        'Taking the number of delivered emails and dividing it by the total number of emails sent',
    },
    {
      title: 'Unsubscribed Rate',
      value: 33,
      getOptions: getUnsubscribedRate,
      tooltip:
        'Taking the number of delivered emails and dividing it by the total number of emails sent',
    },
    {
      title: 'Spam Report Rate',
      value: 11.8,
      getOptions: getSpanReportRate,
      tooltip:
        'Taking the number of delivered emails and dividing it by the total number of emails sent',
    },
  ];

  return (
    <div className="grid lg:grid-cols-4 md:grid-cols-2 grid-cols-1 gap-5 mb-5">
      {cards.map((card, idx) => (
        <EmailCard key={idx} {...card} />
      ))}
    </div>
  );
};

export default EmailBarChart;
