import product01 from '@/assets/images/product/img-01.png';
import product04 from '@/assets/images/product/img-04.png';
import product08 from '@/assets/images/product/img-08.png';
import { LuMoveRight } from 'react-icons/lu';
import { Link } from 'react-router';

type productstype = {
  id: number;
  img: string;
  title: string;
  price: number;
  quantity: number;
  total: number;
  link: string;
};

type summarytype = {
  label: string;
  value: string;
};

type servicestype = {
  id: string;
  title: string;
  desc: string;
  price: string;
};
const products: productstype[] = [
  {
    id: 1,
    img: product08,
    title: 'Roar Twill Blue Baseball Cap',
    price: 149.99,
    quantity: 2,
    total: 299.98,
    link: '/product-overviewp',
  },
  {
    id: 2,
    img: product04,
    title: 'Mesh Ergonomic Green Chair',
    price: 362.21,
    quantity: 1,
    total: 362.21,
    link: '/product-overviewp',
  },
  {
    id: 3,
    img: product01,
    title: 'Smartest Printed T-shirt',
    price: 89.99,
    quantity: 3,
    total: 269.97,
    link: '/product-overviewp',
  },
];

const summary: summarytype[] = [
  { label: 'Sub Total', value: '$932.16' },
  { label: 'Estimated Tax (18%)', value: '$167.79' },
  { label: 'Item Discounts (12%)', value: '-$111.86' },
  { label: 'Shipping Charge', value: '$0' },
];

const services: servicestype[] = [
  {
    id: 'switchPrice1',
    title: 'Care + Package',
    desc: '2 year of additional care',
    price: '$24.99',
  },
  {
    id: 'switchPrice2',
    title: 'Environment Friendly',
    desc: 'The primary goal of eco-warriors is creating',
    price: '$19.99',
  },
];

const OrdersSummary = () => {
  return (
    <div className="col-span-1">
      <div className="p-5 card mb-5">
        <h6 className="card-title mb-4">Orders Summary</h6>

        <div className="px-4 py-3 mb-4 text-danger rounded-md bg-red-50">
          These products are limited, checkout within <span className="font-bold">03m 21s</span>
        </div>

        <div>
          {products.map(product => (
            <div
              key={product.id}
              className="flex justify-between items-center gap-5 py-4 border-b border-dashed border-default-200"
            >
              <div className="flex items-center gap-3">
                <div className="flex items-center justify-center rounded-md size-12 bg-default-100">
                  <img src={product.img} alt={product.title} className="h-8" width={32} />
                </div>
                <div>
                  <h6 className="mb-1 text-[15px] text-default-800 font-semibold">
                    <Link
                      to={product.link}
                      className="transition-all duration-300 ease-linear hover:text-primary"
                    >
                      {product.title}
                    </Link>
                  </h6>
                  <p className="text-default-500 text-sm">
                    ${product.price} x {product.quantity}
                  </p>
                </div>
              </div>
              <span className="text-default-500 text-sm">${product.total}</span>
            </div>
          ))}
        </div>

        {summary.map((item, index) => (
          <div key={index} className="flex justify-between items-center gap-5 py-3">
            <span className="text-default-500 text-sm">{item.label}</span>
            <span className="text-default-800 text-sm">{item.value}</span>
          </div>
        ))}

        <div className="flex justify-between items-center gap-5 font-semibold pt-3">
          <span className="text-default-500 text-sm">Total Amount (USD)</span>
          <span className="text-default-800 text-sm">$988.09</span>
        </div>

        <div className="mt-4">
          <button
            type="button"
            className="text-[13px] py-2 px-4 rounded bg-primary text-white transition-all duration-300 hover:bg-blue-600 inline-flex justify-center w-full items-center"
          >
            Place Order
            <LuMoveRight className="size-4 ms-1.5" />
          </button>
        </div>
      </div>

      <div className="mb-5">
        <h6 className="mb-4 underline text-base text-default-800 font-semibold">
          Additional Service
        </h6>
        {services.map(service => (
          <div key={service.id} className="p-5 card mb-5">
            <div className="flex justify-between flex-wrap items-center gap-3">
              <div>
                <h6 className="mb-1 text-[15px] text-default-800 font-semibold">{service.title}</h6>
                <p className="text-default-500 text-sm">{service.desc}</p>
              </div>
              <div className="flex items-center gap-3">
                <label className="text-default-800 font-semibold text-sm" htmlFor={service.id}>
                  {service.price}
                </label>
                <input type="checkbox" id={service.id} className="form-switch" />
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

export default OrdersSummary;
