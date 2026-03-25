import React from 'react';
import {
  LuBoxes,
  LuLoader,
  LuPackageCheck,
  LuPackagePlus,
  LuPackageX,
  LuTruck,
} from 'react-icons/lu';

type OrderDetail = {
  id: number;
  count: string;
  label: string;
  icon: React.ElementType;
  bgColor: string;
  textColor: string;
};

const orderDetailsData: OrderDetail[] = [
  {
    id: 1,
    count: '15,101',
    label: 'Total Orders',
    icon: LuBoxes,
    bgColor: 'bg-primary/10',
    textColor: 'text-primary',
  },
  {
    id: 2,
    count: '9,543',
    label: 'Shipping Orders',
    icon: LuTruck,
    bgColor: 'bg-secondary/10',
    textColor: 'text-secondary',
  },
  {
    id: 3,
    count: '1,548',
    label: 'Pending Orders',
    icon: LuLoader,
    bgColor: 'bg-warning/15',
    textColor: 'text-warning',
  },
  {
    id: 4,
    count: '3,874',
    label: 'New Orders',
    icon: LuPackagePlus,
    bgColor: 'bg-primary/10',
    textColor: 'text-primary',
  },
  {
    id: 5,
    count: '30,914',
    label: 'Delivered Orders',
    icon: LuPackageCheck,
    bgColor: 'bg-success/10',
    textColor: 'text-success',
  },
  {
    id: 6,
    count: '3,863',
    label: 'Cancelled Orders',
    icon: LuPackageX,
    bgColor: 'bg-danger/10',
    textColor: 'text-danger',
  },
];

const OrderDetails = () => {
  return (
    <div className="col-span-1">
      <div className="grid md:grid-cols-2 grid-cols-1 gap-5">
        {orderDetailsData.map(({ id, count, label, icon: Icon, bgColor, textColor }) => (
          <div key={id} className="card">
            <div className="card-body">
              <div className="flex items-center gap-3">
                <div className={`btn size-12 text-15 ${bgColor} ${textColor}`}>
                  <Icon className="size-6" />
                </div>
                <div>
                  <h5 className="mb-1 text-base font-semibold text-default-800" data-target={count}>
                    {count}
                  </h5>
                  <p className="text-default-500 text-sm">{label}</p>
                </div>
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

export default OrderDetails;
