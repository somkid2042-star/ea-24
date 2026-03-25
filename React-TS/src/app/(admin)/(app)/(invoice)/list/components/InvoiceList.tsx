import SimplebarClient from '@/components/client-wrapper/SimplebarClient';
import { Link } from 'react-router';
import { LuCalendarClock, LuSearch, LuSlidersHorizontal } from 'react-icons/lu';

type Invoice = {
  id: string;
  name: string;
  amount: string;
  date: string;
  status: 'Paid' | 'Unpaid' | 'Cancel' | 'Refund';
};

const invoices: Invoice[] = [
  {
    id: '#TW15090251',
    name: 'Paula Keenan',
    amount: '$873.96',
    date: '21 Jan, 2024',
    status: 'Unpaid',
  },
  {
    id: '#TW15090252',
    name: 'Jaqueline Hammes',
    amount: '$1,203.74',
    date: '27 Oct, 2023',
    status: 'Paid',
  },
  {
    id: '#TW15090253',
    name: 'Akeem Paucek',
    amount: '$1,423.10',
    date: '04 Feb, 2024',
    status: 'Paid',
  },
  {
    id: '#TW15090254',
    name: 'Stephon Trantow',
    amount: '$1,420.99',
    date: '14 July, 2023',
    status: 'Cancel',
  },
  {
    id: '#TW15090255',
    name: 'Domenic Tromp',
    amount: '$247.18',
    date: '11 April, 2023',
    status: 'Refund',
  },
  {
    id: '#TW15090256',
    name: 'Marie Prohaska',
    amount: '$559.32',
    date: '03 Aug, 2023',
    status: 'Paid',
  },
  {
    id: '#TW15090257',
    name: 'Ethel Corwin',
    amount: '$2,147.65',
    date: '15 Dec, 2024',
    status: 'Unpaid',
  },
];

const statusClasses = {
  Paid: 'inline-flex items-center gap-x-1.5 py-0.5 px-2.5 rounded text-xs font-medium bg-success/10 text-success',
  Unpaid: 'text-warning bg-warning/20 rounded text-xs py-0.5 px-2.5',
  Cancel: 'text-danger bg-danger/10 rounded text-xs py-0.5 px-2.5',
  Refund: 'text-default-600 bg-default-200 rounded text-xs py-0.5 px-2.5',
};

const InvoiceList = () => {
  return (
    <div className="lg:col-span-1 col-span-1 card print:hidden">
      <div className="sticky top-24">
        <div className="card-body">
          <h6 className="mb-4 card-title">Invoice List</h6>

          <div className="flex items-center gap-2">
            <div className="relative w-full">
              <input
                type="text"
                className="ps-11 form-input form-input-sm"
                placeholder="Search for..."
              />
              <div className="absolute inset-y-0 start-0 flex items-center ps-3">
                <LuSearch className="size-4 text-default-500" />
              </div>
            </div>

            <button
              type="button"
              className="btn size-7.5 bg-info/15 text-primary hover:text-white hover:bg-sky-600"
            >
              <LuSlidersHorizontal className="size-4" />
            </button>
          </div>
        </div>

        <SimplebarClient className="overflow-x-auto h-150">
          {invoices.map(invoice => (
            <Link
              to="#"
              key={invoice.id}
              className="block border-t p-5 border-default-200 hover:bg-default-100 active"
            >
              <div className="flex justify-between">
                <div className="w-full">
                  <h6 className="font-semibold text-sm text-default-700">{invoice.id}</h6>
                  <div>
                    <h6 className="mt-3 mb-2 text-base font-semibold text-default-800">
                      {invoice.name}
                    </h6>
                    <div className="flex items-center justify-between gap-6">
                      <p className="text-default-500 text-sm">{invoice.amount}</p>
                      <button type="button" className="inline-flex text-sm items-center">
                        <LuCalendarClock className="size-4 text-default-500 me-1.5" />
                        {invoice.date}
                      </button>
                    </div>
                  </div>
                </div>

                <div>
                  <span className={statusClasses[invoice.status]}>{invoice.status}</span>
                </div>
              </div>
            </Link>
          ))}
        </SimplebarClient>
      </div>
    </div>
  );
};

export default InvoiceList;
