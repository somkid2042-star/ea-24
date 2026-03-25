import { Link } from 'react-router';
import Flatpickr from 'react-flatpickr';
import {
  LuChevronLeft,
  LuChevronRight,
  LuEllipsis,
  LuPlus,
  LuSearch,
  LuSquarePen,
  LuTrash2,
} from 'react-icons/lu';

type Expense = {
  id: number;
  date: string;
  item: string;
  purchasedBy: string;
  paidBy: string;
  amount: string;
};

const expensesData: Expense[] = [
  {
    id: 1,
    date: '02 July, 2023',
    item: 'Mac System',
    purchasedBy: 'HR',
    paidBy: 'HR',
    amount: '$5,478',
  },
  {
    id: 2,
    date: '08 Nov, 2023',
    item: 'HP Desktop',
    purchasedBy: 'Louisa Howe',
    paidBy: 'HR',
    amount: '$4,342',
  },
  {
    id: 3,
    date: '11 Aug, 2023',
    item: 'i5 PC',
    purchasedBy: 'Everett Moore',
    paidBy: 'Admin',
    amount: '$8,327',
  },
  {
    id: 4,
    date: '20 Sep, 2023',
    item: 'Decoration',
    purchasedBy: 'Omari Welch',
    paidBy: 'HR',
    amount: '$563',
  },
  {
    id: 5,
    date: '07 Oct, 2023',
    item: 'Cake',
    purchasedBy: 'HR',
    paidBy: 'Susana Dooley',
    amount: '$148',
  },
  {
    id: 6,
    date: '18 Dec, 2023',
    item: 'Salary to Employees',
    purchasedBy: 'Omari Welch',
    paidBy: 'Paula Keenan',
    amount: '$4,500',
  },
  {
    id: 7,
    date: '21 Jan, 2024',
    item: 'Salary to Employees',
    purchasedBy: 'Everett Moore',
    paidBy: 'Paula Keenan',
    amount: '$3,000',
  },
  {
    id: 8,
    date: '02 Feb, 2023',
    item: 'HP & Lenovo Desktop',
    purchasedBy: 'HR',
    paidBy: 'HR',
    amount: '$4,177',
  },
  {
    id: 9,
    date: '11 Dec, 2023',
    item: 'Birthday Party',
    purchasedBy: 'HR',
    paidBy: 'HR',
    amount: '$2,307',
  },
  {
    id: 10,
    date: '01 Jan, 2023',
    item: 'Festival Decoration',
    purchasedBy: 'Lucie Beahan',
    paidBy: 'HR',
    amount: '$543.99',
  },
];

const Expenses = () => {
  return (
    <div className="card">
      <div className="card-header">
        <div className="flex gap-3">
          <div className="relative">
            <input
              type="text"
              className="form-input form-input-sm ps-9"
              placeholder="Search for...."
            />
            <div className="absolute inset-y-0 start-0 flex items-center ps-3">
              <LuSearch className="size-4 flex items-center text-default-500" />
            </div>
          </div>

          <Flatpickr
            options={{
              mode: 'range',
              dateFormat: 'd M, Y',
            }}
            className="form-input form-input-sm w-full"
            placeholder="Select Date"
          />
        </div>

        <Link
          to="#"
          className="btn btn-sm bg-primary text-white"
          aria-haspopup="dialog"
          aria-expanded="false"
          aria-controls="sales-expenses-add"
          data-hs-overlay="#sales-expenses-add"
        >
          <LuPlus className="size-4 me-1" />
          Add Estimate
        </Link>
      </div>

      <div className="flex flex-col">
        <div className="overflow-x-auto">
          <div className="min-w-full inline-block align-middle">
            <div className="overflow-hidden">
              <table className="min-w-full  divide-y divide-default-200">
                <thead className="bg-default-150">
                  <tr className="text-sm font-normal text-default-500 whitespace-nowrap">
                    <th scope="col" className="px-3.5 py-3 text-start">
                      Purchase Date
                    </th>
                    <th scope="col" className="px-3.5 py-3 text-start">
                      Item
                    </th>
                    <th scope="col" className="px-3.5 py-3 text-start">
                      Purchased By
                    </th>
                    <th scope="col" className="px-3.5 py-3 text-start">
                      Paid By
                    </th>
                    <th scope="col" className="px-3.5 py-3 text-start">
                      Amount
                    </th>
                    <th scope="col" className="px-3.5 py-3 text-start">
                      Action
                    </th>
                  </tr>
                </thead>

                <tbody className="divide-y divide-default-200">
                  {expensesData.map(expense => (
                    <tr key={expense.id} className="text-default-800 font-normal">
                      <td className="px-3.5 py-2.5 whitespace-nowrap text-sm">{expense.date}</td>
                      <td className="px-3.5 py-2.5 whitespace-nowrap text-sm">{expense.item}</td>
                      <td className="px-3.5 py-2.5 whitespace-nowrap text-sm">
                        {expense.purchasedBy}
                      </td>
                      <td className="px-3.5 py-2.5 whitespace-nowrap text-sm">{expense.paidBy}</td>
                      <td className="px-3.5 py-2.5 whitespace-nowrap text-sm">{expense.amount}</td>
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
                            <LuEllipsis className="size-4" />
                          </button>
                          <div
                            className="hs-dropdown-menu transition-[opacity,margin] duration hs-dropdown-open:opacity-100 opacity-0 hidden min-w-40 card z-30 mt-2 p-2 text-sm"
                            role="menu"
                          >
                            <Link
                              className="flex items-center gap-1.5 py-1.5 font-medium px-3 text-default-500 hover:bg-default-150 rounded"
                              to="#"
                            >
                              <LuSquarePen className="size-3" /> Edit
                            </Link>
                            <Link
                              className="flex items-center gap-1.5 py-1.5 font-medium px-3 text-default-500 hover:bg-default-150 rounded"
                              to="#"
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

        <div className="card-footer">
          <p className="text-default-500 text-sm">
            Showing <b>10</b> of <b>25</b> Results
          </p>
          <nav className="flex items-center gap-2" aria-label="Pagination">
            <button
              type="button"
              className="btn btn-sm border bg-transparent border-default-200 text-default-600 hover:bg-primary/10 hover:text-primary hover:border-primary/10"
            >
              <LuChevronLeft className="size-4 me-1" /> Prev
            </button>

            <button
              type="button"
              className="btn size-7.5 bg-transparent border border-default-200 text-default-600 hover:bg-primary/10 hover:text-primary hover:border-primary/10"
            >
              1
            </button>

            <button type="button" className="btn size-7.5 bg-primary text-white">
              2
            </button>

            <button
              type="button"
              className="btn size-7.5 bg-transparent border border-default-200 text-default-600 hover:bg-primary/10 hover:text-primary hover:border-primary/10"
            >
              3
            </button>

            <button
              type="button"
              className="btn btn-sm border bg-transparent border-default-200 text-default-600 hover:bg-primary/10 hover:text-primary hover:border-primary/10"
            >
              Next <LuChevronRight className="size-4 ms-1" />
            </button>
          </nav>
        </div>
      </div>
    </div>
  );
};

export default Expenses;
