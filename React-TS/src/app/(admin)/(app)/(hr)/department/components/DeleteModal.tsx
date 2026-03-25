import deleteImg from '@/assets/images/delete.png';
import { LuX } from 'react-icons/lu';

const DeleteModal = () => {
  return (
    <div
      id="department-delete-modal"
      className="hs-overlay hidden size-full fixed top-0 start-0 z-80 overflow-x-hidden overflow-y-auto pointer-events-none"
      role="dialog"
      tabIndex={-1}
      aria-labelledby="department-delete-modal-label"
    >
      <div className="hs-overlay-animation-target hs-overlay-open:scale-100 hs-overlay-open:opacity-100 scale-95 opacity-0 ease-in-out transition-all duration-200 md:w-sm m-3 mx-auto min-h-[calc(100%-56px)] flex items-center">
        <div className="w-full flex flex-col card shadow-2xs border border-default-200 rounded-xl pointer-events-auto px-6 py-8 relative">
          <div className="absolute top-3 end-3">
            <button
              type="button"
              className="size-5 text-default-800"
              aria-label="Close"
              data-hs-overlay="#department-delete-modal"
            >
              <span className="sr-only">Close</span>
              <LuX className="size-5" />
            </button>
          </div>

          <h3 className="font-semibold text-base text-default-800  text-center">
            <img src={deleteImg} alt="" className="size-12 mx-auto" />
            <div className="mt-5 text-center">
              <h5 className="mb-1 text-lg font-semibold text-default-800">Are you sure?</h5>
              <p className="text-default-500 text-sm font-normal">
                Are you certain you want to delete this record?
              </p>
              <div className="mt-5 flex gap-2 justify-center">
                <button
                  data-hs-overlay="#department-delete-modal"
                  className="btn text-danger bg-transparent hover:bg-danger/10"
                  aria-label="Close"
                >
                  Cancel
                </button>
                <button className="bg-danger text-white  btn border-0 btn-sm">
                  Yes,Delete It!
                </button>
              </div>
            </div>
          </h3>
        </div>
      </div>
    </div>
  );
};

export default DeleteModal;
