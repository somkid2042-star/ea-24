import ApexChartClient from '@/components/client-wrapper/ApexChartClient';
import {
  getHiredCandidates,
  getRjectedCandidates,
  getTotalApplication,
  getTotalEmployee,
} from './data';

type EmployeeCardProps = {
  title: string;
  value: number;
  percentage: string;
  percentageType: 'success' | 'danger';
  chartOptions: () => ApexCharts.ApexOptions;
};

const EmployeeCard = ({
  title,
  value,
  percentage,
  percentageType,
  chartOptions,
}: EmployeeCardProps) => {
  return (
    <div className="card">
      <div className="card-body">
        <div className="grid grid-cols-4">
          <div className="col-span-3">
            <p className="text-base text-default-500 font-medium">{title}</p>
            <h5 className="text-3xl font-medium mt-4">
              <span data-target={value}>{value}</span>
            </h5>
          </div>

          <div>
            <ApexChartClient
              getOptions={chartOptions}
              series={chartOptions().series}
              type="radialBar"
              height={110}
            />
          </div>
        </div>

        <div className="flex items-center justify-between gap-3 mt-8">
          <p className="font-medium text-sm text-default-600">
            <span className={`font-medium text-${percentageType}`}>{percentage}</span> Increase
          </p>
          <p className="font-semibold text-base text-default-400">This Month</p>
        </div>
      </div>
    </div>
  );
};

const EmployeDetails = () => {
  return (
    <div className="col-span-1">
      <div className="grid md:grid-cols-2 grid-cols-1 gap-5">
        <EmployeeCard
          title="Total Employee"
          value={615}
          percentage="15%"
          percentageType="success"
          chartOptions={getTotalEmployee}
        />

        <EmployeeCard
          title="Total Application"
          value={174}
          percentage="26%"
          percentageType="success"
          chartOptions={getTotalApplication}
        />

        <EmployeeCard
          title="Hired Candidates"
          value={64}
          percentage="0.5%"
          percentageType="danger"
          chartOptions={getHiredCandidates}
        />

        <EmployeeCard
          title="Rejected Candidates"
          value={110}
          percentage="16%"
          percentageType="danger"
          chartOptions={getRjectedCandidates}
        />
      </div>
    </div>
  );
};

export default EmployeDetails;
