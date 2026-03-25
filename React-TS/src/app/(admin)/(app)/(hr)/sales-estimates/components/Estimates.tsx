import { Link } from 'react-router';
import {
  LuChevronLeft,
  LuChevronRight,
  LuEllipsisVertical,
  LuPlus,
  LuSearch,
  LuSquarePen,
  LuTrash2,
} from 'react-icons/lu';

type Estimate = {
  id: string;
  clientName: string;
  estimateBy: string;
  estimateDate: string;
  expiryDate: string;
  amount: string;
  status: 'Accepted' | 'Declined' | 'Expired';
};

const estimatesData: Estimate[] = [
  {
    id: '#TWE20015420',
    clientName: 'Infra Teach',
    estimateBy: 'HR',
    estimateDate: '02 July, 2023',
    expiryDate: '05 July, 2023',
    amount: '$2,403',
    status: 'Accepted',
  },
  {
    id: '#TWE20015421',
    clientName: 'Themesdesign',
    estimateBy: 'Admin',
    estimateDate: '08 Nov, 2023',
    expiryDate: '08 Nov, 2023',
    amount: '$1,749',
    status: 'Declined',
  },
  {
    id: '#TWE20015422',
    clientName: 'Judil Fashion',
    estimateBy: 'Admin',
    estimateDate: '11 Aug, 2023',
    expiryDate: '03 Aug, 2023',
    amount: '$816',
    status: 'Expired',
  },
  {
    id: '#TWE20015423',
    clientName: '4xM Infotech',
    estimateBy: 'HR',
    estimateDate: '20 Sep, 2023',
    expiryDate: '21 Sep, 2023',
    amount: '$1,184',
    status: 'Accepted',
  },
  {
    id: '#TWE20015424',
    clientName: 'Digitech Galaxy',
    estimateBy: 'HR',
    estimateDate: '07 Oct, 2023',
    expiryDate: '09 Oct, 2023',
    amount: '$5,463',
    status: 'Accepted',
  },
  {
    id: '#TWE20015425',
    clientName: 'Zoetic Fashion',
    estimateBy: 'HR',
    estimateDate: '18 Dec, 2023',
    expiryDate: '20 Dec, 2023',
    amount: '$3,463',
    status: 'Declined',
  },
];

const Estimates = () => {
  const getStatusClass = (status: Estimate['status']) => {
    switch (status) {
      case 'Accepted':
        return 'bg-success/15 text-success';
      case 'Declined':
        return 'bg-danger/10 text-danger';
      case 'Expired':
        return 'bg-warning/15 text-warning';
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
              type="text"
              className="form-input form-input-sm ps-11"
              placeholder="Search for...."
            />
            <div className="absolute inset-y-0 start-0 flex items-center ps-3">
              <LuSearch className="size-4 text-default-500" />
            </div>
          </div>

          <select
            id="statusFilter"
            className="form-input form-input-sm lg:w-52 w-full"
            defaultValue="Accepted"
          >
            <option value="Accepted">Accepted</option>
            <option value="Declined">Declined</option>
            <option value="Expired">Expired</option>
          </select>

          <input
            type="text"
            id="dateRangeFilterInput"
            className="form-input form-input-sm lg:w-52 w-full"
            placeholder="Select date"
            data-provider="flatpickr"
            data-date-format="d M, Y"
            data-range-date="true"
            readOnly
          />
        </div>

        <Link
          to="#"
          className="btn btn-sm bg-primary text-white flex items-center"
          aria-haspopup="dialog"
          aria-expanded="false"
          aria-controls="sales-estimates-add"
          data-hs-overlay="#sales-estimates-add"
        >
          <LuPlus className="size-4 me-1" />
          Add Estimate
        </Link>
      </div>

      <div className="flex flex-col">
        <div className="overflow-x-auto">
          <div className="min-w-full inline-block align-middle">
            <div className="overflow-hidden">
              <table className="min-w-full">
                <thead className="bg-default-150">
                  <tr className="text-sm font-normal text-default-500">
                    <th className="px-3.5 py-3 text-start">Estimate Number</th>
                    <th className="px-3.5 py-3 text-start">Client Name</th>
                    <th className="px-3.5 py-3 text-start">Estimate By</th>
                    <th className="px-3.5 py-3 text-start">Estimate Date</th>
                    <th className="px-3.5 py-3 text-start">Expiry Date</th>
                    <th className="px-3.5 py-3 text-start">Amount</th>
                    <th className="px-3.5 py-3 text-start">Status</th>
                    <th className="px-3.5 py-3 text-start">Action</th>
                  </tr>
                </thead>

                <tbody className="divide-y divide-default-200">
                  {estimatesData.map(estimate => (
                    <tr key={estimate.id} className="text-default-800 font-normal">
                      <td className="px-3.5 py-2.5 whitespace-nowrap text-sm text-primary">
                        <Link to="#">{estimate.id}</Link>
                      </td>
                      <td className="px-3.5 py-2.5 whitespace-nowrap text-sm">
                        {estimate.clientName}
                      </td>
                      <td className="px-3.5 py-2.5 whitespace-nowrap text-sm">
                        {estimate.estimateBy}
                      </td>
                      <td className="px-3.5 py-2.5 whitespace-nowrap text-sm">
                        {estimate.estimateDate}
                      </td>
                      <td className="px-3.5 py-2.5 whitespace-nowrap text-sm">
                        {estimate.expiryDate}
                      </td>
                      <td className="px-3.5 py-2.5 whitespace-nowrap text-sm">{estimate.amount}</td>
                      <td className="px-3.5 py-2.5 whitespace-nowrap text-sm">
                        <span
                          className={`inline-flex items-center gap-x-1.5 py-0.5 px-2.5 rounded text-xs font-medium ${getStatusClass(
                            estimate.status
                          )}`}
                        >
                          {estimate.status}
                        </span>
                      </td>
                      <td className="px-3.5 py-2.5 whitespace-nowrap text-sm">
                        <div className="hs-dropdown relative inline-flex">
                          <button
                            type="button"
                            className="hs-dropdown-toggle btn size-7.5 bg-default-200 hover:bg-default-600 text-default-500 hover:text-white"
                            aria-haspopup="menu"
                            aria-expanded="false"
                            aria-label="Dropdown"
                            hs-dropdown-placement="bottom-end"
                          >
                            <LuEllipsisVertical className="size-4" />
                          </button>
                          <div
                            className="hs-dropdown-menu transition-[opacity,margin] duration hs-dropdown-open:opacity-100 opacity-0 hidden min-w-40 card z-30 mt-2 p-2 text-sm"
                            role="menu"
                          >
                            <Link
                              className="flex items-center gap-1.5 py-1.5 font-medium px-3 text-default-500 hover:bg-default-150 rounded"
                              to="#"
                            >
                              <LuSquarePen className="size-3" />
                              Edit
                            </Link>
                            <Link
                              className="flex items-center gap-1.5 py-1.5 font-medium px-3 text-default-500 hover:bg-default-150 rounded"
                              to="#"
                            >
                              <LuTrash2 className="size-3" />
                              Delete
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
            Showing <b>{estimatesData.length}</b> of <b>8</b> Results
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

export default Estimates;
