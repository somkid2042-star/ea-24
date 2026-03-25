import { LuX } from 'react-icons/lu';

const AddDepartment = () => {
  return (
    <div
      id="department-edit-modal"
      className="hs-overlay hidden size-full fixed top-0 start-0 z-80 overflow-x-hidden overflow-y-auto pointer-events-none"
      role="dialog"
      tabIndex={-1}
      aria-labelledby="department-delete-modal-label2"
    >
      <div className="hs-overlay-animation-target hs-overlay-open:scale-100 hs-overlay-open:opacity-100 scale-95 opacity-0 ease-in-out transition-all duration-200 sm:max-w-lg sm:w-full m-3 sm:mx-auto min-h-[calc(100%-56px)] flex items-center">
        <div className="w-full flex flex-col card border border-default-200 shadow-2xs rounded-xl pointer-events-auto">
          <div className="card-header">
            <h3
              id="department-delete-modal-label2"
              className="font-bold text-default-800 text-base"
            >
              Add Department
            </h3>
            <div>
              <button
                type="button"
                className="size-5 text-default-800"
                aria-label="Close"
                data-hs-overlay="#department-edit-modal"
              >
                <span className="sr-only">Close</span>
                <LuX className="size-5" />
              </button>
            </div>
          </div>

          <div className="p-4 overflow-y-auto">
            <div className="flex flex-col gap-y-4">
              <div className="lg:col-span-12">
                <label
                  htmlFor="Department Name"
                  className="inline-block mb-2 text-base font-medium"
                >
                  Department Name
                </label>
                <input
                  type="text"
                  id="Department Name"
                  className="form-input"
                  placeholder="Department Name"
                />
              </div>

              <div className="lg:col-span-12">
                <label
                  htmlFor="Head of Dep. Name"
                  className="inline-block mb-2 text-base font-medium"
                >
                  Head of Dep. Name
                </label>
                <input type="text" placeholder="Head name" className="form-input" />
              </div>

              <div className="lg:col-span-12">
                <label htmlFor="Phone Number" className="inline-block mb-2 text-base font-medium">
                  Phone Number
                </label>
                <input
                  type="text"
                  id="Phone Number"
                  className="form-input"
                  placeholder="1234567890"
                />
              </div>

              <div className="lg:col-span-12">
                <label htmlFor="Email" className="inline-block mb-2 text-base font-medium">
                  Email
                </label>
                <input type="text" placeholder="Enter Email" className="form-input" />
              </div>

              <div className="lg:col-span-12">
                <label htmlFor="Total Employee" className="inline-block mb-2 text-base font-medium">
                  Total Employee
                </label>
                <input type="text" placeholder="0" className="form-input" />
              </div>
            </div>
          </div>
          <div className="flex justify-end items-center gap-x-2 py-3 px-4">
            <button
              data-hs-overlay="#department-edit-modal"
              className="bg-transparent text-danger btn border-0 hover:bg-danger/10"
              aria-label="Close"
            >
              Cancel
            </button>

            <button type="button" className="text-white  btn bg-primary">
              Add Department
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default AddDepartment;
