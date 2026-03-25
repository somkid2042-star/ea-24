import { LuX } from 'react-icons/lu';

const EventModal = () => {
  return (
    <div
      id="addEmailModal"
      className="hs-overlay hidden size-full fixed top-0 start-0 z-80 overflow-x-hidden overflow-y-auto pointer-events-none"
      role="dialog"
      tabIndex={-1}
      aria-labelledby="addEmailModal-label"
    >
      <div className=" hs-overlay-open:scale-100 hs-overlay-open:opacity-100 scale-95 opacity-0 ease-in-out transition-all duration-200 sm:max-w-4xl sm:w-full m-3 sm:mx-auto min-h-[calc(100%-56px)] flex items-center">
        <div className="card w-full border border-default-200 pointer-events-auto">
          <div className="card-header">
            <h3 className="font-semibold text-base text-default-800">New Message</h3>
            <button
              type="button"
              className="size-5 text-default-800"
              aria-label="Close"
              data-hs-overlay="#addEmailModal"
            >
              <span className="sr-only">Close</span>
              <LuX className="size-5" />
            </button>
          </div>

          <div className="card-body">
            <div className="mb-4">
              <label htmlFor="event-title" className="inline-block mb-2 text-base font-medium">
                To
              </label>
              <input
                type="text"
                id="event-title"
                className="form-input"
                placeholder="tailwink@themesdesign.in"
              />
            </div>

            <div className="mb-4">
              <label htmlFor="subject" className="inline-block mb-2 text-base font-medium">
                Subject
              </label>
              <input type="text" id="subject" className="form-input" placeholder="Subject" />
            </div>

            <div>
              <label htmlFor="Textarea" className="inline-block mb-2 text-base font-medium">
                Example Textarea
              </label>
              <textarea id="Textarea" className="form-input" rows={3}></textarea>
            </div>
          </div>

          <div className="card-footer flex gap-2 md:justify-end">
            <button
              type="reset"
              data-hs-overlay="#addEmailModal"
              className="btn text-danger btn border-0 hover:bg-red-50"
            >
              Cancel
            </button>

            <button type="submit" className="btn bg-primary text-white">
              Send
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default EventModal;
