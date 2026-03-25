import { LuCloudUpload, LuX } from 'react-icons/lu';
import { Link } from 'react-router';

const Modal = () => {
  return (
    <div
      id="ecommerce-sellers-add"
      className="hs-overlay hidden size-full fixed top-0 start-0 z-80 overflow-x-hidden overflow-y-auto pointer-events-none"
      role="dialog"
      tabIndex={-1}
      aria-labelledby="ecommerce-sellers-add-label"
    >
      <div className="hs-overlay-animation-target hs-overlay-open:scale-100 hs-overlay-open:opacity-100 scale-95 opacity-0 ease-in-out transition-all duration-200 sm:max-w-lg sm:w-full m-3 sm:mx-auto min-h-[calc(100%-56px)] flex items-center">
        <div className="w-full flex flex-col card border border-default-200 shadow-2xs rounded-xl pointer-events-auto">
          <div className="card-header">
            <h3
              id="ecommerce-sellers-add-label"
              className="font-semibold text-base text-default-800"
            >
              Add Seller
            </h3>

            <button
              type="button"
              className="size-5 text-default-800"
              aria-label="Close"
              data-hs-overlay="#ecommerce-sellers-add"
            >
              <span className="sr-only">Close</span>
              <LuX className="size-5" />
            </button>
          </div>

          <div className="card-body overflow-y-auto">
            <div className="mb-4">
              <label htmlFor="" className="inline-block mb-2 text-sm text-default-800 font-medium">
                Company Logo
              </label>
              <div className="flex items-center justify-center bg-transparent border border-dashed rounded-md cursor-pointer dropzone border-default-300 dropzone2">
                <div className="w-full py-5 text-lg text-center dz-message needsclick">
                  <div className="mb-3 flex justify-center">
                    <LuCloudUpload className="size-12 fill-default-200 text-default-500" />
                  </div>

                  <h5 className="mb-0 font-normal text-[15px] text-default-500">
                    Drag and drop your files or <Link to="#">browse</Link> your files
                  </h5>
                </div>
              </div>
            </div>

            <div className="mb-4">
              <label htmlFor="" className="inline-block mb-2 text-sm text-default-800 font-medium">
                Company Name
              </label>
              <input id="" type="text" className="form-input" placeholder="Seller name" />
            </div>

            <div>
              <label htmlFor="" className="inline-block mb-2 text-sm text-default-800 font-medium">
                Owner Name
              </label>
              <input id="" type="text" className="form-input" placeholder="Owner Name" />
            </div>

            <div className="mt-4 flex gap-2 md:justify-end">
              <button
                className="btn border-0 text-danger bg-transparent transition-all duration-300 hover:bg-danger/10"
                aria-label="Close"
                data-hs-overlay="#ecommerce-sellers-add"
              >
                Cancel
              </button>

              <button className="btn bg-primary text-white">Add Seller</button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Modal;
