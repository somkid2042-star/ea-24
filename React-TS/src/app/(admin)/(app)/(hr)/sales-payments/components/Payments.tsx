import { LuChevronLeft, LuChevronRight, LuSearch } from 'react-icons/lu';
import Flatpickr from 'react-flatpickr';
import { Link } from 'react-router';

type PaymentStatus = 'Paid' | 'Pending' | 'Failed';

type Payment = {
  id: string;
  plan: string;
  date: string;
  type: string;
  username: string;
  amount: string;
  status: PaymentStatus;
};

const paymentsData: Payment[] = [
  {
    id: '#TWP10021320',
    plan: 'Regular License',
    date: '02 July, 2023',
    type: 'PayPal',
    username: 'Infra Teach',
    amount: '$2,403',
    status: 'Paid',
  },
  {
    id: '#TWP10021321',
    plan: 'Extended License',
    date: '08 Nov, 2023',
    type: 'Credit Card',
    username: 'Kim Broberg',
    amount: '$1,341',
    status: 'Pending',
  },
  {
    id: '#TWP10021322',
    plan: 'Extended License',
    date: '11 Aug, 2023',
    type: 'Bank Transfer',
    username: 'Everett Moore',
    amount: '$816.21',
    status: 'Failed',
  },
  {
    id: '#TWP10021323',
    plan: 'Regular License',
    date: '20 Sep, 2023',
    type: 'PayPal',
    username: 'Omari Welch',
    amount: '$1,184',
    status: 'Paid',
  },
  {
    id: '#TWP10021324',
    plan: 'Regular License',
    date: '07 Oct, 2023',
    type: 'Debit Card',
    username: 'Susana Dooley',
    amount: '$5,463',
    status: 'Paid',
  },
  {
    id: '#TWP10021325',
    plan: 'Regular License',
    date: '18 Dec, 2023',
    type: 'PayPal',
    username: 'Paul Gerhold',
    amount: '$3,463',
    status: 'Pending',
  },
  {
    id: '#TWP10021326',
    plan: 'Extended License',
    date: '21 Jan, 2024',
    type: 'Bank Transfer',
    username: 'Lucie Beahan',
    amount: '$1,543',
    status: 'Failed',
  },
  {
    id: '#TWP10021327',
    plan: 'Regular License',
    date: '02 Feb, 2023',
    type: 'PayPal',
    username: 'Jose White',
    amount: '$4,177',
    status: 'Paid',
  },
  {
    id: '#TWP10021328',
    plan: 'Extended License',
    date: '11 Dec, 2023',
    type: 'Debit Card',
    username: 'Jonas Frederiksen',
    amount: '$2,307',
    status: 'Pending',
  },
  {
    id: '#TWP10021329',
    plan: 'Extended License',
    date: '01 Jan, 2023',
    type: 'PayPal',
    username: 'Stephen Tillman',
    amount: '$543.99',
    status: 'Paid',
  },
];

const Payments = () => {
  const getStatusClass = (status: PaymentStatus) => {
    switch (status) {
      case 'Paid':
        return 'bg-success/15 text-success';
      case 'Pending':
        return 'bg-warning/15 text-warning';
      case 'Failed':
        return 'bg-danger/15 text-danger';
      default:
        return '';
    }
  };

  const getDotClass = (status: PaymentStatus) => {
    switch (status) {
      case 'Paid':
        return 'bg-success';
      case 'Pending':
        return 'bg-warning';
      case 'Failed':
        return 'bg-danger';
      default:
        return '';
    }
  };

  return (
    <div className="card">
      <div className="card-header flex justify-between items-center">
        <div className="flex gap-3">
          <div className="relative">
            <input
              type="email"
              className="form-input form-input-sm ps-9"
              placeholder="Search for...."
            />
            <div className="absolute inset-y-0 start-0 flex items-center pointer-events-none ps-4">
              <LuSearch className="size-4 flex items-center text-default-500" />
            </div>
          </div>

          <Flatpickr
            options={{
              mode: 'range',
              dateFormat: 'd M, Y',
            }}
            className="form-input form-input-sm"
            placeholder="Select Date"
          />
        </div>

        <div>
          <select id="statusFilter" className="form-input form-input-sm" defaultValue="Paid">
            <option value="Failed">Failed</option>
            <option value="Paid">Paid</option>
            <option value="Pending">Pending</option>
          </select>
        </div>
      </div>

      <div className="flex flex-col">
        <div className="overflow-x-auto">
          <div className="min-w-full inline-block align-middle">
            <div className="overflow-hidden">
              <table className="min-w-full divide-y divide-default-200">
                <thead className="bg-default-150">
                  <tr className="text-sm font-normal text-default-500">
                    <th className="px-3.5 py-3 text-start">Payment ID</th>
                    <th className="px-3.5 py-3 text-start">Membership Plan</th>
                    <th className="px-3.5 py-3 text-start">Date</th>
                    <th className="px-3.5 py-3 text-start">Payment Type</th>
                    <th className="px-3.5 py-3 text-start">Username</th>
                    <th className="px-3.5 py-3 text-start">Amount</th>
                    <th className="px-3.5 py-3 text-start">Status</th>
                  </tr>
                </thead>

                <tbody className="divide-y divide-default-200">
                  {paymentsData.map(payment => (
                    <tr key={payment.id} className="text-default-800 font-normal">
                      <td className="px-3.5 py-2.5 whitespace-nowrap text-sm text-primary">
                        <Link to="#">{payment.id}</Link>
                      </td>
                      <td className="px-3.5 py-2.5 whitespace-nowrap text-sm">{payment.plan}</td>
                      <td className="px-3.5 py-2.5 whitespace-nowrap text-sm">{payment.date}</td>
                      <td className="px-3.5 py-2.5 whitespace-nowrap text-sm">{payment.type}</td>
                      <td className="px-3.5 py-2.5 whitespace-nowrap text-sm">
                        {payment.username}
                      </td>
                      <td className="px-3.5 py-2.5 whitespace-nowrap text-sm">{payment.amount}</td>
                      <td className="px-3.5 py-2.5 whitespace-nowrap text-sm">
                        <span
                          className={`inline-flex items-center gap-x-1.5 py-0.5 px-2.5 rounded text-xs font-medium ${getStatusClass(
                            payment.status
                          )}`}
                        >
                          <span
                            className={`size-1.5 me-1 rounded-full inline-block ${getDotClass(
                              payment.status
                            )}`}
                          ></span>
                          {payment.status}
                        </span>
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
            Showing <b>{paymentsData.length}</b> of <b>10</b> Results
          </p>
          <nav className="flex items-center gap-2" aria-label="Pagination">
            <button
              type="button"
              className="btn btn-sm border bg-transparent border-default-200 text-default-600 hover:bg-primary/10 hover:text-primary hover:border-primary/10 flex items-center"
            >
              <LuChevronLeft className="size-4 me-1" /> Prev
            </button>

            <button className="btn size-7.5 bg-transparent border border-default-200 text-default-600 hover:bg-primary/10 hover:text-primary">
              1
            </button>
            <button className="btn size-7.5 bg-primary text-white">2</button>
            <button className="btn size-7.5 bg-transparent border border-default-200 text-default-600 hover:bg-primary/10 hover:text-primary">
              3
            </button>

            <button
              type="button"
              className="btn btn-sm border bg-transparent border-default-200 text-default-600 hover:bg-primary/10 hover:text-primary hover:border-primary/10 flex items-center"
            >
              Next <LuChevronRight className="size-4 ms-1" />
            </button>
          </nav>
        </div>
      </div>
    </div>
  );
};

export default Payments;
