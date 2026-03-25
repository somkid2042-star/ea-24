import { Link } from 'react-router';
import { LuDownload } from 'react-icons/lu';

type OrderStep = {
  title: string;
  description: string;
  date: string;
};

const orderSteps: OrderStep[] = [
  {
    title: 'Order Placed',
    description: 'Your order has been successfully submitted.',
    date: '02 Nov, 2023',
  },
  {
    title: 'Order Processing',
    description:
      'Once the order is received, it goes through the processing stage. During this time, the items are gathered, and the order is prepared for shipment.',
    date: '02 Nov, 2023',
  },
  {
    title: 'Shipped Order',
    description: "The order is shipped out to the customer's designated delivery address.",
    date: '04 Nov, 2023',
  },
  {
    title: 'Out for Delivery',
    description:
      'This status indicates that the order is currently out for delivery by the shipping or courier company.',
    date: '06 Nov, 2023',
  },
  {
    title: 'Delivered',
    description:
      'Finally, when the order successfully reaches the customer\'s address and is handed over, the status changes to "Delivered."',
    date: '09 Nov, 2023',
  },
];

const OrderStatus = () => {
  return (
    <div className="card mt-5">
      <div className="card-body">
        <div className="flex justify-between gap-5 items-center mb-4">
          <h6 className="card-title">Order Status</h6>
          <div className="flex items-center gap-3">
            <Link to="#" className="text-danger underline text-sm">
              Cancelled Order
            </Link>
            <Link
              to="/invoice-overview"
              className="btn btn-sm bg-primary text-white flex items-center gap-1"
            >
              <LuDownload className="size-4" />
              Invoice
            </Link>
          </div>
        </div>

        <div>
          {orderSteps.map((step, index) => (
            <div
              key={index}
              className="relative px-6 before:absolute before:border-s before:start-0.75 before:border-primary before:end-0.75 before:top-1.5 before:-bottom-1.5 after:absolute after:size-2 after:bg-primary after:rounded-full after:start-0 after:end-0 after:top-1.5 pb-4"
            >
              <div className="flex justify-between">
                <div>
                  <h6 className="mb-2 card-title">{step.title}</h6>
                  <p className="text-default-500 text-sm">{step.description}</p>
                </div>
                <p className="text-[13px] text-default-400">{step.date}</p>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

export default OrderStatus;
