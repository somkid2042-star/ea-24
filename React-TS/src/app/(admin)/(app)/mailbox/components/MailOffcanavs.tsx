import avatar1 from '@/assets/images/user/avatar-1.png';
import avatar5 from '@/assets/images/user/avatar-5.png';
import SimplebarClient from '@/components/client-wrapper/SimplebarClient';
import {
  LuArchiveRestore,
  LuChevronsLeft,
  LuImage,
  LuMic,
  LuPrinter,
  LuSend,
  LuStar,
  LuTrash2,
} from 'react-icons/lu';
import { Link } from 'react-router';

const MailOffcanavs = () => {
  return (
    <div
      id="emailOverview"
      className="card shadow-none hs-overlay [--body-scroll:true] [--overlay-backdrop:false] hs-overlay-open:translate-x-0 hidden translate-x-full absolute top-0 end-0 transition-all duration-300 transform h-full max-w-full w-full z-80 bg-card"
      role="dialog"
      tabIndex={-1}
      aria-labelledby="emailOverview-label"
    >
      <div className="card-header py-4">
        <button
          type="button"
          className="size-8 inline-flex justify-center items-center gap-x-2 rounded-full border border-transparent bg-default-100 text-default-800 hover:bg-default-150 focus:outline-hidden focus:bg-default-200 disabled:opacity-50 disabled:pointer-events-none"
          aria-label="Close"
          data-hs-overlay="#emailOverview"
        >
          <span className="sr-only">Close</span>
          <LuChevronsLeft className="size-4" />
        </button>

        <div className="flex-grow">
          <h3 id="emailOverview-label" className="font-bold text-default-800 mb-1.5">
            How Custom Software Can Solve Your Business Challenges
          </h3>
          <p className="text-default-500 dark:text-zink-200">
            <Link to="#!">infrateach@tailwick.com</Link> (Aug 6, 2023, 9:04 PM)
          </p>
        </div>

        <div className="flex gap-3 shrink-0">
          <Link
            to="#!"
            className="flex items-center justify-center transition-all duration-200 ease-linear size-6 text-default-500 dark:text-zink-200 hover:text-primary dark:hover:text-primary"
          >
            <LuArchiveRestore className="size-4" />
          </Link>
          <Link
            to="#!"
            className="flex items-center justify-center transition-all duration-200 ease-linear size-6 text-default-500 dark:text-zink-200 hover:text-sky-500 dark:hover:text-sky-500"
          >
            <LuPrinter className="size-4" />
          </Link>
          <Link
            to="#!"
            className="flex items-center justify-center transition-all duration-200 ease-linear size-6 text-default-500 dark:text-zink-200 hover:text-yellow-500 dark:hover:text-yellow-500"
          >
            <LuStar className="size-4" />
          </Link>
          <Link
            to="#!"
            className="flex items-center justify-center transition-all duration-200 ease-linear size-6 text-default-500 dark:text-zink-200 hover:text-danger dark:hover:text-danger"
          >
            <LuTrash2 className="size-4" />
          </Link>
        </div>
      </div>

      <SimplebarClient className="max-h-150">
        <div className="p-5 space-y-6">
          <div className="flex gap-3">
            <div className="relative flex items-center justify-center font-semibold rounded-full text-default-500 size-9 bg-default-100 shrink-0 dark:text-zink-200 dark:bg-zink-600">
              <img src={avatar5} alt="" className="rounded-full h-9" />
            </div>

            <div className="grow">
              <div className="flex items-center">
                <div className="grow">
                  <h6>Infra Teach</h6>
                  <p className="text-default-500 dark:text-zink-200">
                    <Link to="#!">infrateach@tailwick.com</Link>
                  </p>
                </div>
                <div className="shrink-0">Aug 6, 2023, 9:04 PM</div>
              </div>
              <div className="p-4 mt-3 rounded-md bg-default-100 dark:bg-zink-600">
                <p className="mb-2 last:mb-0">Hi,</p>
                <p className="mb-2 last:mb-0">
                  Custom software solutions are tailor-made software applications designed to meet
                  the unique needs of a specific business or organization. Unlike off-the-shelf
                  software, which offers a standardized solution for a broad range of users, custom
                  software is precisely crafted to align with the workflows, processes, and
                  objectives of a particular business.
                </p>
                <p className="mb-2 last:mb-0">
                  The key advantage of custom software lies in its ability to be scalable and
                  flexible. It can evolve alongside the business, accommodating changing
                  requirements and supporting expansion. By adapting to the specific needs of the
                  organization, custom software empowers businesses to gain a competitive edge,
                  differentiate themselves in the market, and deliver enhanced experiences to their
                  customers.
                </p>
                <p className="mb-2 last:mb-0">Thank You</p>
              </div>
            </div>
          </div>

          <div className="flex gap-3">
            <div className="relative flex items-center justify-center font-semibold bg-pink-100 rounded-full text-default-500 size-9 shrink-0 dark:bg-pink-500/20 dark:text-zink-200">
              <img src={avatar1} alt="" className="rounded-full h-9" />
            </div>
            <div className="grow">
              <div className="flex items-center">
                <div className="grow">
                  <h6>Me</h6>
                  <p className="text-default-500 dark:text-zink-200">
                    <Link to="#!">paulakeenan@tailwick.com</Link>
                  </p>
                </div>
                <div className="shrink-0">07 Nov, 2023, 10:14 PM</div>
              </div>
              <div className="p-4 mt-3 rounded-md bg-default-100 dark:bg-zink-600">
                <p className="mb-2 last:mb-0">Hi,</p>
                <p className="mb-2 last:mb-0">
                  I hope this email finds you well. Let me start by saying that I am a big fan of
                  your work and it has inspired me to push myself beyond what I thought were my
                  limits!
                </p>
                <p className="mb-2 last:mb-0">
                  After taking a good look at [target company] I realize that you could improve in
                  [improvement area]. I have helped many others improve in the same area and I‘d be
                  more than happy to talk with you about it!
                </p>
                <p className="mb-2 last:mb-0">
                  Would you be available for a quick call to discuss how our [product/service] could
                  help you?
                </p>
                <p className="mb-2 last:mb-0">Regards,</p>
                <p className="mb-2 last:mb-0">Themesdesign</p>
              </div>
            </div>
          </div>

          <div className="flex gap-3">
            <div className="relative flex items-center justify-center font-semibold rounded-full text-default-500 size-9 bg-default-100 shrink-0 dark:text-zink-200 dark:bg-zink-600">
              <img src={avatar5} alt="" className="rounded-full h-9" />
            </div>
            <div className="grow">
              <div className="flex items-center">
                <div className="grow">
                  <h6>Infra Teach</h6>
                  <p className="text-default-500 dark:text-zink-200">
                    <Link to="#!">infrateach@tailwick.com</Link>
                  </p>
                </div>
                <div className="shrink-0">07 Nov, 2023, 10:42 PM</div>
              </div>
              <div className="p-4 mt-3 rounded-md bg-default-100 dark:bg-zink-600">
                <p className="mb-2 last:mb-0">Hello, Themesdesign</p>
                <p className="mb-2 last:mb-0">
                  You are probably very busy, I totally understand that!
                </p>
                <p className="mb-2 last:mb-0">
                  It would be great to hear back from you. So, please let me know when you find some
                  time.
                </p>
              </div>
            </div>
          </div>
        </div>
      </SimplebarClient>

      <div className="card-footer py-4">
        <div className="grow">
          <input
            type="text"
            id="inputText"
            className="form-input"
            placeholder="Enter Message"
            required
            autoComplete="off"
          />
        </div>

        <div className="flex gap-2 shrink-0">
          <button type="button" className="btn hover:bg-default-100">
            <LuMic className="size-4" />
          </button>
          <button type="button" className="btn hover:bg-default-100">
            <LuImage className="size-4" />
          </button>
          <button type="button" className="btn bg-primary text-white">
            <LuSend className="inline-block mr-1 align-middle size-4" />{' '}
            <span className="align-middle">Send</span>
          </button>
        </div>
      </div>
    </div>
  );
};

export default MailOffcanavs;
