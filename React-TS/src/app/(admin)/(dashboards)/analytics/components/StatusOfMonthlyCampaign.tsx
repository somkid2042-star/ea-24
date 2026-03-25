import { LuEye, LuMail, LuPackageOpen, LuUsers, LuUserX } from 'react-icons/lu';

type CampaignItem = {
  id: number;
  label: string;
  value: string;
  percentage: string;
  percentageColor: 'text-success' | 'text-danger';
  icon: React.ElementType;
  iconColor: string;
  bgColor: string;
};
const StatusOfMonthlyCampaign = () => {
  const campaignData: CampaignItem[] = [
    {
      id: 1,
      label: 'Clicked',
      value: '9,745',
      percentage: '2.5%',
      percentageColor: 'text-success',
      icon: LuMail,
      iconColor: 'text-danger',
      bgColor: 'bg-danger/10',
    },
    {
      id: 2,
      label: 'Subscribe',
      value: '3,352',
      percentage: '18.9%',
      percentageColor: 'text-success',
      icon: LuUsers,
      iconColor: 'text-secondary',
      bgColor: 'bg-secondary/10',
    },
    {
      id: 3,
      label: 'Unsubscribe',
      value: '85,745',
      percentage: '1.2%',
      percentageColor: 'text-danger',
      icon: LuUserX,
      iconColor: 'text-orange-500',
      bgColor: 'bg-orange-500/10',
    },
    {
      id: 4,
      label: 'Viewers',
      value: '85,745',
      percentage: '11.6%',
      percentageColor: 'text-success',
      icon: LuEye,
      iconColor: 'text-success',
      bgColor: 'bg-success/10',
    },
    {
      id: 5,
      label: 'Opened',
      value: '85,745',
      percentage: '3.1%',
      percentageColor: 'text-danger',
      icon: LuPackageOpen,
      iconColor: 'text-default-950',
      bgColor: 'bg-default-950/10',
    },
    {
      id: 6,
      label: 'Trial Period',
      value: '70,775',
      percentage: '22%',
      percentageColor: 'text-danger',
      icon: LuUserX,
      iconColor: 'text-info',
      bgColor: 'bg-info/10',
    },
  ];

  return (
    <div className="card">
      <div className="card-header">
        <h6 className="card-title">Status of Monthly Campaign</h6>
      </div>

      <div className="card-body">
        <ul className="flex flex-col gap-5">
          {campaignData.map(item => {
            const Icon = item.icon;
            return (
              <li key={item.id} className="flex items-center gap-3 text-sm">
                <div className={`${item.bgColor} btn size-8`}>
                  <Icon className={`${item.iconColor} size-4`} />
                </div>
                <h6 className="grow text-default-900">{item.label}</h6>
                <p>{item.value}</p>
                <div className={`w-12 ${item.percentageColor} text-end`}>{item.percentage}</div>
              </li>
            );
          })}
        </ul>
      </div>
    </div>
  );
};

export default StatusOfMonthlyCampaign;
