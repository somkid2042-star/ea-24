import Flatpickr from 'react-flatpickr';
import { LuX } from 'react-icons/lu';

const EstimentModal = () => {
  return (
    <div
      id="sales-estimates-add"
      className="hs-overlay hidden size-full fixed top-0 start-0 z-80 overflow-x-hidden overflow-y-auto pointer-events-none"
      role="dialog"
      tabIndex={-1}
    >
      <div className="hs-overlay-animation-target hs-overlay-open:scale-100 hs-overlay-open:opacity-100 scale-95 opacity-0 ease-in-out transition-all duration-200 sm:max-w-lg sm:w-full m-3 sm:mx-auto min-h-[calc(100%-56px)] flex items-center">
        <div className="w-full flex flex-col card border border-default-200 shadow-2xs rounded-xl pointer-events-auto">
          <div className="card-header">
            <h3 className="font-bold text-default-800 text-base">Add Estimate</h3>
            <div>
              <button
                type="button"
                className="size-5 text-default-800"
                aria-label="Close"
                data-hs-overlay="#sales-estimates-add"
              >
                <span className="sr-only">Close</span>
                <LuX className="size-5" />
              </button>
            </div>
          </div>

          <div className="card-body">
            <div className="grid grid-cols-2 gap-4">
              <div className="col-span-2">
                <label
                  htmlFor=""
                  className="inline-block mb-2 text-sm text-default-800 font-medium"
                >
                  User ID
                </label>
                <input id="" type="text" className="form-input" placeholder="#TW1500004" disabled />
              </div>

              <div className="col-span-2">
                <label
                  htmlFor="invoiceNo"
                  className="inline-block mb-2 text-sm text-default-800 font-medium"
                >
                  Client Name
                </label>
                <input
                  type="text"
                  id="invoiceNo"
                  className="form-input"
                  placeholder="Client name"
                  required
                />
              </div>

              <div className="col-span-2">
                <label
                  htmlFor="invoiceNo"
                  className="inline-block mb-2 text-sm text-default-800 font-medium"
                >
                  Estimate By
                </label>
                <select id="invoiceNo" className="form-input" required>
                  <option value="">Admin</option>
                  <option value="">Hr</option>
                </select>
              </div>

              <div className="col-span-1">
                <label
                  htmlFor="publishDateTime"
                  className="inline-block mb-2 text-sm text-default-800 font-medium"
                >
                  Estimate Date
                </label>
                <Flatpickr
                  options={{
                    mode: 'single',
                    enableTime: true,
                    dateFormat: 'Y-m-d H:i',
                  }}
                  className="form-input"
                  placeholder="Select Date"
                />
              </div>

              <div className="col-span-1 mb-4">
                <label
                  htmlFor="publishDateTime"
                  className="inline-block mb-2 text-sm text-default-800 font-medium"
                >
                  Expiry Date
                </label>
                <Flatpickr
                  options={{
                    mode: 'single',
                    enableTime: true,
                    dateFormat: 'Y-m-d H:i',
                  }}
                  className="form-input"
                  placeholder="Select Date"
                />{' '}
              </div>

              <div className="col-span-2">
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

              <div className="col-span-2">
                <label
                  htmlFor="invoiceNo"
                  className="inline-block mb-2 text-sm text-default-800 font-medium"
                >
                  Status
                </label>
                <select id="invoiceNo" className="form-input" required>
                  <option value="">Accepted</option>
                  <option value="">Declined</option>
                  <option value="">Expired</option>
                </select>
              </div>
            </div>
          </div>

          <div className="card-footer flex gap-2 justify-end">
            <button
              data-hs-overlay="#sales-estimates-add"
              className="btn border-0 text-danger bg-transparent hover:bg-red-50"
            >
              Cancel
            </button>

            <button className="text-white btn bg-primary">Add Estimate</button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default EstimentModal;
