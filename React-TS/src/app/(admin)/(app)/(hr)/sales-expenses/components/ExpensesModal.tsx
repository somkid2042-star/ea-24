import { LuX } from 'react-icons/lu';

const ExpensesModal = () => {
  return (
    <div
      id="sales-expenses-add"
      className="hs-overlay hidden size-full fixed top-0 start-0 z-80 overflow-x-hidden overflow-y-auto pointer-events-none"
      role="dialog"
      tabIndex={-1}
      aria-labelledby="sales-expenses-add-label2"
    >
      <div className="hs-overlay-animation-target hs-overlay-open:scale-100 hs-overlay-open:opacity-100 scale-95 opacity-0 ease-in-out transition-all duration-200 sm:max-w-lg sm:w-full m-3 sm:mx-auto min-h-[calc(100%-56px)] flex items-center">
        <div className="w-full flex flex-col card border border-default-200 shadow-2xs rounded-xl pointer-events-auto">
          <div className="card-header">
            <h3 id="sales-expenses-add-label2" className="font-bold text-default-800 text-base">
              Add Expense
            </h3>
            <div>
              <button
                type="button"
                className="size-5 text-default-800"
                aria-label="Close"
                data-hs-overlay="#sales-expenses-add"
              >
                <span className="sr-only">Close</span>
                <LuX className="size-5" />
              </button>
            </div>
          </div>

          <div className="card-body">
            <div className="mb-4">
              <label
                htmlFor="publishDateTime"
                className="inline-block mb-2 text-sm text-default-800 font-medium"
              >
                Purchase Date
              </label>
              <input
                type="text"
                id="publishDateTime"
                className="form-input"
                placeholder="Purchase Date"
                data-provider="flatpickr"
                data-date-format="d M, Y"
                data-enable-timerequired
                required
                readOnly
              />
            </div>

            <div className="mb-4">
              <label
                htmlFor="invoiceNo"
                className="inline-block mb-2 text-sm text-default-800 font-medium"
              >
                Purchased By
              </label>
              <input
                type="text"
                id="invoiceNo"
                className="form-input"
                placeholder="Purchased By"
                required
              />
            </div>

            <div className="mb-4">
              <label
                htmlFor="invoiceNo"
                className="inline-block mb-2 text-sm text-default-800 font-medium"
              >
                Paid By
              </label>
              <input
                type="text"
                id="invoiceNo"
                className="form-input"
                placeholder="Paid By  "
                required
              />
            </div>

            <div className="mb-4">
              <label
                htmlFor="invoiceNo"
                className="inline-block mb-2 text-sm text-default-800 font-medium"
              >
                Item
              </label>
              <input
                type="text"
                id="invoiceNo"
                className="form-input"
                placeholder="Item title"
                required
              />
            </div>

            <div className="mb-4">
              <label
                htmlFor="invoiceNo"
                className="inline-block mb-2 text-sm text-default-800 font-medium"
              >
                Amount
              </label>
              <input
                type="number"
                id="invoiceNo"
                className="form-input"
                placeholder="$00.00"
                required
              />
            </div>
          </div>

          <div className="card-footer mt-4 flex gap-2 justify-end">
            <button className="bg-transparent text-danger btn border-0 hover:bg-danger/10">
              Cancel
            </button>

            <button className="text-white btn bg-primary">Add Expense</button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default ExpensesModal;
