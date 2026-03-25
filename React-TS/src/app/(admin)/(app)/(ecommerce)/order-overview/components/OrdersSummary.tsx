import product01 from '@/assets/images/product/img-01.png';
import product04 from '@/assets/images/product/img-04.png';
import product08 from '@/assets/images/product/img-08.png';
import { Link } from 'react-router';

type OrderItem = {
  id: string;
  name: string;
  image: string;
  price: number;
  quantity: number;
  url?: string;
};

type SummaryItem = {
  label: string;
  value: string;
  isTotal?: boolean;
};

const orderItems: OrderItem[] = [
  {
    id: '1',
    name: 'Roar Twill Blue Baseball Cap',
    image: product08,
    price: 149.99,
    quantity: 2,
    url: '',
  },
  {
    id: '2',
    name: 'Mesh Ergonomic Green Chair',
    image: product04,
    price: 362.21,
    quantity: 1,
    url: '',
  },
  {
    id: '3',
    name: 'Smartest Printed T-shirt',
    image: product01,
    price: 89.99,
    quantity: 3,
    url: '',
  },
];

const summaryData: SummaryItem[] = [
  { label: 'Sub Total', value: '$932.16' },
  { label: 'Estimated Tax (18%)', value: '$167.79' },
  { label: 'Item Discounts (12%)', value: '-$111.86' },
  { label: 'Shipping Charge', value: '$0' },
  { label: 'Total Amount (USD)', value: '$988.09', isTotal: true },
];

const OrdersSummary = () => {
  return (
    <div className="card mt-5">
      <div className="card-body">
        <div className="flex justify-between gap-5 items-center">
          <h6 className="mb-4 card-title">Orders Summary</h6>
          <Link to="#" className="text-danger text-sm underline">
            Cancelled Order
          </Link>
        </div>

        <div>
          {orderItems.map(item => (
            <div
              key={item.id}
              className="flex justify-between items-center gap-5 py-4 border-b border-dashed border-default-200"
            >
              <div className="flex items-center gap-3">
                <div className="btn rounded-md size-12 bg-default-100">
                  <img src={item.image} alt={item.name} className="h-8" width={32} />
                </div>
                <div>
                  <h6 className="mb-1 card-title">
                    <Link
                      to={item.url ?? ''}
                      className="transition-all duration-300 ease-linear hover:text-primary"
                    >
                      {item.name}
                    </Link>
                  </h6>
                  <p className="text-default-500 text-sm">
                    ${item.price.toFixed(2)} x {item.quantity}
                  </p>
                </div>
              </div>
              <span className="text-sm">${(item.price * item.quantity).toFixed(2)}</span>
            </div>
          ))}

          {summaryData.map((summary, idx) => (
            <div
              key={idx}
              className={`flex justify-between items-center gap-5 py-3 text-sm ${summary.isTotal ? 'pt-4 font-semibold' : ''}`}
            >
              <span className="text-default-500">{summary.label}</span>
              <span className="text-default-800">{summary.value}</span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

export default OrdersSummary;
