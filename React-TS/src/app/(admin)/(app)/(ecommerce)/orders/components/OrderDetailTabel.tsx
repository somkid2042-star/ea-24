import {
  LuBoxes,
  LuChevronLeft,
  LuChevronRight,
  LuEllipsis,
  LuEye,
  LuLoader,
  LuPackageCheck,
  LuPackageX,
  LuPlus,
  LuRefreshCw,
  LuSearch,
  LuSquarePen,
  LuTrash2,
} from 'react-icons/lu';
import { Link } from 'react-router';

type Order = {
  id: string;
  orderDate: string;
  deliveryDate: string;
  customerName: string;
  paymentMethod: string;
  amount: string;
  status: 'Delivered' | 'Shipping' | 'New' | 'Pending' | 'Return' | 'Cancelled';
};

const orders: Order[] = [
  {
    id: '#TWT5015100365',
    orderDate: '08 Jun, 2023',
    deliveryDate: '15 Jun, 2023',
    customerName: 'Marie Prohaska',
    paymentMethod: 'Credit Card',
    amount: '$541.32',
    status: 'Delivered',
  },
  {
    id: '#TWT5015100366',
    orderDate: '11 July, 2023',
    deliveryDate: '20 July, 2023',
    customerName: 'Jaqueline Hammes',
    paymentMethod: 'Paypal',
    amount: '$1,876.33',
    status: 'Shipping',
  },
  {
    id: '#TWT5015100367',
    orderDate: '21 Aug, 2023',
    deliveryDate: '24 Aug, 2023',
    customerName: 'Marlene Hirthe',
    paymentMethod: 'Visa Card',
    amount: '$15,023.99',
    status: 'New',
  },
  {
    id: '#TWT5015100368',
    orderDate: '28 Nov, 2023',
    deliveryDate: '02 Dec, 2023',
    customerName: 'Reagan Larson',
    paymentMethod: 'American Express',
    amount: '$783.56',
    status: 'Delivered',
  },
  {
    id: '#TWT5015100369',
    orderDate: '11 Oct, 2023',
    deliveryDate: '16 Oct, 2023',
    customerName: 'Glennie Langosh',
    paymentMethod: 'American Express',
    amount: '$986.49',
    status: 'Pending',
  },
  {
    id: '#TWT5015100370',
    orderDate: '16 Feb, 2023',
    deliveryDate: '22 Feb, 2023',
    customerName: 'Rickie Cremin',
    paymentMethod: 'COD',
    amount: '$741.32',
    status: 'Delivered',
  },
  {
    id: '#TWT5015100371',
    orderDate: '18 Apr, 2023',
    deliveryDate: '29 Apr, 2023',
    customerName: 'Domenic Tromp',
    paymentMethod: 'Credit Card',
    amount: '$1,386.49',
    status: 'Shipping',
  },
  {
    id: '#TWT5015100372',
    orderDate: '21 Jan, 2024',
    deliveryDate: '24 Jan, 2023',
    customerName: 'Akeem Paucek',
    paymentMethod: 'PayPal',
    amount: '$3,487.21',
    status: 'New',
  },
  {
    id: '#TWT5015100373',
    orderDate: '05 Oct, 2024',
    deliveryDate: '11 Oct, 2023',
    customerName: 'David Gaby',
    paymentMethod: 'COD',
    amount: '$5,986.11',
    status: 'Return',
  },
  {
    id: '#TWT5015100374',
    orderDate: '07 Oct, 2024',
    deliveryDate: '13 Oct, 2023',
    customerName: 'Joel Freeleagus',
    paymentMethod: 'American Express',
    amount: '$9,451.75',
    status: 'Cancelled',
  },
];

const statusClasses: Record<string, string> = {
  Delivered: 'bg-success/10 text-success border border-success/30',
  Shipping: 'bg-secondary/10 text-secondary border border-secondary/30',
  New: 'bg-info/10 text-info border border-info/30',
  Pending: 'bg-warning/10 text-warning border border-warning/30',
  Return: 'bg-default-100 text-default-800/80 border border-default-800/20',
  Cancelled: 'bg-danger/10 text-danger border border-danger/30',
};

const OrderDetailTable = () => {
  return (
    <div className="card">
      <div className="card-header flex justify-between items-center gap-2">
        <div className="relative">
          <input
            type="email"
            className="form-input form-input-sm ps-9"
            placeholder="Search for...."
          />
          <div className="absolute inset-y-0 start-0 flex items-center ps-3">
            <LuSearch className="size-3.5 flex items-center text-default-500" />
          </div>
        </div>

        <button className="btn btn-sm bg-primary text-white flex items-center gap-1">
          <LuPlus className="size-4" /> Add Product
        </button>
      </div>

      <div className="card-header">
        <div className="flex items-center flex-wrap gap-3">
          <button className="btn btn-sm bg-primary text-white font-medium flex items-center gap-1">
            <LuBoxes className="size-4" /> All Orders
          </button>
          <button className="btn btn-sm text-default-500 hover:text-primary border-0 bg-transparent flex items-center gap-1">
            <LuLoader className="size-4" /> Pending
          </button>
          <button className="btn btn-sm text-default-500 hover:text-primary border-0 bg-transparent flex items-center gap-1">
            <LuPackageCheck className="size-4" /> Delivered
          </button>
          <button className="btn btn-sm text-default-500 hover:text-primary border-0 bg-transparent flex items-center gap-1">
            <LuRefreshCw className="size-4" /> Returns
          </button>
          <button className="btn btn-sm text-default-500 hover:text-primary border-0 bg-transparent flex items-center gap-1">
            <LuPackageX className="size-4" /> Cancelled
          </button>
        </div>
      </div>

      <div className="flex flex-col overflow-x-auto">
        <div className="min-w-full inline-block align-middle">
          <div className="overflow-hidden">
            <table className="min-w-full divide-y divide-default-200">
              <thead className="bg-default-150">
                <tr className="text-sm font-normal text-default-500 whitespace-nowrap">
                  <th className="ps-4 text-start">
                    <input type="checkbox" className="form-checkbox" />
                  </th>
                  <th className="px-3.5 py-3 text-start">Order ID</th>
                  <th className="px-3.5 py-3 text-start">Order Date</th>
                  <th className="px-3.5 py-3 text-start">Delivery Date</th>
                  <th className="px-3.5 py-3 text-start">Customer Name</th>
                  <th className="px-3.5 py-3 text-start">Payment Method</th>
                  <th className="px-3.5 py-3 text-start">Amount</th>
                  <th className="px-3.5 py-3 text-start">Delivery Status</th>
                  <th className="px-3.5 py-3 text-start">Action</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-default-200">
                {orders.map((order, idx) => (
                  <tr key={idx} className="text-default-800 font-normal">
                    <td className="py-2.5 ps-4">
                      <input type="checkbox" className="form-checkbox" />
                    </td>
                    <td className="px-3.5 py-2.5 whitespace-nowrap text-sm text-primary">
                      {order.id}
                    </td>
                    <td className="px-3.5 py-2.5 whitespace-nowrap text-sm">{order.orderDate}</td>
                    <td className="px-3.5 py-2.5 whitespace-nowrap text-sm">
                      {order.deliveryDate}
                    </td>
                    <td className="px-3.5 py-2.5 whitespace-nowrap text-sm">
                      {order.customerName}
                    </td>
                    <td className="px-3.5 py-2.5 whitespace-nowrap text-sm">
                      {order.paymentMethod}
                    </td>
                    <td className="px-3.5 py-2.5 whitespace-nowrap text-sm">{order.amount}</td>
                    <td className="px-3.5 py-2.5 whitespace-nowrap">
                      <span
                        className={`inline-flex items-center gap-x-1.5 py-0.5 px-2.5 rounded text-xs font-medium ${statusClasses[order.status]}`}
                      >
                        {order.status}
                      </span>
                    </td>
                    <td className="px-3.5 py-2.5">
                      <div className="hs-dropdown relative inline-flex">
                        <button className="hs-dropdown-toggle btn size-7.5 bg-default-200 hover:bg-default-600 text-default-500 hover:text-white">
                          <LuEllipsis className="size-4" />
                        </button>
                        <div className="hs-dropdown-menu">
                          <Link
                            to=""
                            className="flex items-center gap-1.5 py-1.5 px-3 font-medium text-default-500 hover:bg-default-150 rounded"
                          >
                            <LuEye className="size-3" /> Overview
                          </Link>
                          <Link
                            to=""
                            className="flex items-center gap-1.5 py-1.5 px-3 font-medium text-default-500 hover:bg-default-150 rounded"
                          >
                            <LuSquarePen className="size-3" /> Edit
                          </Link>
                          <Link
                            to=""
                            className="flex items-center gap-1.5 py-1.5 px-3 font-medium text-default-500 hover:bg-default-150 rounded"
                          >
                            <LuTrash2 className="size-3" /> Delete
                          </Link>
                        </div>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <div className="card-footer flex justify-between items-center">
        <p className="text-default-500 text-sm">
          Showing <b>{orders.length}</b> of <b>19</b> Results
        </p>
        <nav className="flex items-center gap-2">
          <button className="btn btn-sm border bg-transparent border-default-200 text-default-600 hover:bg-primary/10 hover:text-primary hover:border-primary/10">
            <LuChevronLeft className="size-4 me-1" /> Prev
          </button>
          <button className="btn size-7.5 bg-transparent border border-default-200 text-default-600 hover:bg-primary/10 hover:text-primary hover:border-primary/10">
            1
          </button>
          <button className="btn size-7.5 bg-primary text-white">2</button>
          <button className="btn size-7.5 bg-transparent border border-default-200 text-default-600 hover:bg-primary/10 hover:text-primary hover:border-primary/10">
            3
          </button>
          <button className="btn btn-sm border bg-transparent border-default-200 text-default-600 hover:bg-primary/10 hover:text-primary hover:border-primary/10">
            Next <LuChevronRight className="size-4 ms-1" />
          </button>
        </nav>
      </div>
    </div>
  );
};

export default OrderDetailTable;
