import type { JSX } from 'react';
import { LuCircleDollarSign, LuCreditCard, LuTruck, LuUser } from 'react-icons/lu';

type DetailCard = {
  title: string;
  lines: string[];
  icon: JSX.Element;
  iconBg: string;
};

const orderDetails: DetailCard[] = [
  {
    title: 'Shipping Details',
    lines: ['Pauline Hylton', '1235 Crossing Meadows Dr, Onalaska', 'West Virginia, USA'],
    icon: <LuTruck className="text-2xl" />,
    iconBg: 'bg-secondary/10 text-secondary',
  },
  {
    title: 'Billing Details',
    lines: ['Pauline Hylton', '1235 Crossing Meadows Dr, Onalaska', 'West Virginia, USA'],
    icon: <LuCreditCard className="text-2xl" />,
    iconBg: 'bg-danger/10 text-danger',
  },
  {
    title: 'Payment Details',
    lines: [
      'ID: #TSD456DF41SD5',
      'Payment Method: Credit Card',
      'Card Number: xxxx xxxx xxxx 1501',
    ],
    icon: <LuCircleDollarSign className="text-2xl" />,
    iconBg: 'bg-info/10 text-info',
  },
  {
    title: 'Customer Info',
    lines: ['Pauline Hylton', 'pauline@tailwick.com', '+(78) 120 4843 4714'],
    icon: <LuUser className="text-2xl rounded-full" />,
    iconBg: 'bg-warning/20 text-warning',
  },
];

const OrderDetails = () => {
  return (
    <div className="grid lg:grid-cols-4 md:grid-cols-2 grid-cols-1 gap-5 mb-5">
      {orderDetails.map((detail, idx) => (
        <div key={idx} className="card">
          <div className="card-body">
            <div className="flex justify-between">
              <div>
                <h6 className="mb-4 card-title">{detail.title}</h6>
                {detail.lines.map((line, i) => (
                  <p
                    key={i}
                    className={`mb-${i < detail.lines.length - 1 ? 1 : 0} text-default-500 text-sm font-${i === 0 ? 'semibold text-default-800' : 'normal'}`}
                  >
                    {line}
                  </p>
                ))}
              </div>
              <div className={`btn ${detail.iconBg}  size-12 float-end`}>{detail.icon}</div>
            </div>
          </div>
        </div>
      ))}
    </div>
  );
};

export default OrderDetails;
