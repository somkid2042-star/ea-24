import deleteImg from '@/assets/images/delete.png';
import { LuX } from 'react-icons/lu';
const Modal = () => {
  return (
    <div
      id="cart-item-delete-modal"
      className="hs-overlay hidden size-full fixed top-0 start-0 z-80 overflow-x-hidden overflow-y-auto pointer-events-none"
      role="dialog"
      tabIndex={-1}
      aria-labelledby="cart-item-delete-modal-label"
    >
      <div className="hs-overlay-animation-target hs-overlay-open:scale-100 hs-overlay-open:opacity-100 scale-95 opacity-0 ease-in-out transition-all duration-200 md:w-sm m-3 sm:mx-auto min-h-[calc(100%-56px)] flex items-center">
        <div className="w-full flex flex-col bg-card border border-default-200 shadow-2xs rounded-xl pointer-events-auto dark:bg-neutral-800 dark:border-neutral-700 dark:shadow-neutral-700/70 px-6 py-8 relative">
          <div className="absolute top-3 end-3">
            <button
              type="button"
              className="size-5 text-default-800"
              aria-label="Close"
              data-hs-overlay="#cart-item-delete-modal"
            >
              <span className="sr-only">Close</span>
              <LuX className="size-5" />
            </button>
          </div>

          <h3 className="font-semibold text-base text-default-800 dark:text-white text-center">
            <img src={deleteImg} alt="" className="size-12 mx-auto" />

            <div className="mt-5 text-center">
              <h5 className="mb-1 text-lg font-semibold text-default-800">Are you sure?</h5>
              <p className="text-default-500 text-sm font-normal">
                Are you certain you want to delete this record?
              </p>

              <div className="mt-5 flex gap-2 md:justify-center">
                <button
                  data-hs-overlay="#cart-item-delete-modal"
                  className="py-2 px-4 text-[13px] rounded-md text-danger bg-transparent transition-all duration-300 hover:bg-red-50"
                  aria-label="Close"
                >
                  Cancel
                </button>

                <button className="btn bg-danger text-white">Yes,Delete It!</button>
              </div>
            </div>
          </h3>
        </div>
      </div>
    </div>
  );
};

export default Modal;
