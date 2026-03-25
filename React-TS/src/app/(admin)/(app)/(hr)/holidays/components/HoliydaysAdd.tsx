import { LuX } from 'react-icons/lu';

const HoliydaysAdd = () => {
  return (
    <div
      id="holidaysLeaveDeleteModal2"
      className="hs-overlay hidden size-full fixed top-0 start-0 z-80 overflow-x-hidden overflow-y-auto pointer-events-none"
      role="dialog"
      tabIndex={-1}
      aria-labelledby="holidaysLeaveDeleteModal-label2"
    >
      <div className="hs-overlay-animation-target hs-overlay-open:scale-100 hs-overlay-open:opacity-100 scale-95 opacity-0 ease-in-out transition-all duration-200 sm:max-w-lg sm:w-full m-3 sm:mx-auto min-h-[calc(100%-56px)] flex items-center">
        <div className="w-full flex flex-col card border border-default-200 shadow-2xs rounded-xl pointer-events-auto">
          <div className="card-header">
            <h3 id="holidaysLeaveDeleteModal-label2" className="card-title">
              Add Holiday
            </h3>

            <div>
              <button
                type="button"
                className="size-5 text-default-800"
                aria-label="Close"
                data-hs-overlay="#holidaysLeaveDeleteModal2"
              >
                <span className="sr-only">Close</span>
                <LuX className="size-5" />
              </button>
            </div>
          </div>
          <div className="card-body">
            <div className="grid grid-cols-1 gap-4 lg:grid-cols-12">
              <div className="lg:col-span-12">
                <label htmlFor="typeSelect" className="inline-block mb-2 text-base font-medium">
                  Type
                </label>
                <select
                  id="typeSelect"
                  name="typeSelect"
                  className="form-input"
                  data-choices
                  data-choices-search-false
                >
                  <option value="Gazetted Holiday">Gazetted Holiday</option>
                  <option value="Observance">Observance</option>
                  <option value="Restricted Holiday" defaultValue="">
                    Restricted Holiday
                  </option>
                  <option value="Season">Season</option>
                </select>
              </div>

              <div className="lg:col-span-12">
                <label htmlFor="holidayInput" className="inline-block mb-2 text-base font-medium">
                  Holiday Name
                </label>
                <input
                  type="text"
                  id="holidayInput"
                  className="form-input bg-transparent border-default-200 focus:outline-none focus:border-primary  placeholder:text-default-400"
                  placeholder="Holiday name"
                />
              </div>

              <div className="lg:col-span-12">
                <label
                  htmlFor="holidayDateInput"
                  className="inline-block mb-2 text-base font-medium"
                >
                  Date
                </label>
                <input
                  type="text"
                  placeholder="Select Date"
                  data-provider="flatpickr"
                  data-date-format="d M, Y"
                  data-range-date="true"
                  readOnly
                  aria-placeholder="Select Date"
                  className="form-input"
                />
              </div>
            </div>
          </div>
          <div className="flex justify-end items-center gap-x-2 py-3 px-4">
            <button
              className="btn border-0 text-sm rounded-md text-danger bg-transparent transition-all duration-300 hover:bg-danger/10"
              aria-label="Close"
            >
              Cancel
            </button>
            <button type="button" className="btn bg-primary text-white">
              Add Holiday
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default HoliydaysAdd;
