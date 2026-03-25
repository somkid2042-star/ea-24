import { Link } from 'react-router';

const ProductsVideo = () => {
  return (
    <>
      <h5 className="mb-5 underline text-lg font-semibold text-default-800">
        Products Video Tutorial
      </h5>
      <div className="grid lg:grid-cols-3 grid-cols-1 gap-5">
        <div className="card">
          <div className="card-body">
            <Link
              to="https://www.youtube.com/embed/qYgogv4R8zg?si=_YxUDmc2fDgHyPae"
              target="_blank"
            >
              <h6 className="mb-6 text-base  text-default-700 font-semibold">
                Setting Up Tailwind CSS
              </h6>
            </Link>

            <div className="flex justify-center">
              <iframe
                className="md:w-full rounded-md md:aspect-video"
                src="https://www.youtube.com/embed/qYgogv4R8zg?si=_YxUDmc2fDgHyPae"
                frameBorder={0}
              ></iframe>
            </div>
          </div>
        </div>

        <div className="card">
          <div className="card-body">
            <Link
              to="https://www.youtube.com/embed/TrftauE2Vyk?si=HRCFmq5956C01yB3"
              target="_blank"
            >
              <h6 className="mb-6 text-base text-default-700 font-semibold">
                Composing Utilities with @apply – Tailwind CSS
              </h6>
            </Link>

            <div className="flex justify-center">
              <iframe
                className="md:w-full rounded-md md:aspect-video"
                src="https://www.youtube.com/embed/TrftauE2Vyk?si=HRCFmq5956C01yB3"
                frameBorder={0}
              ></iframe>
            </div>
          </div>
        </div>

        <div className="card">
          <div className="card-body">
            <Link
              to="https://www.youtube.com/embed/_CntOc4hBcg?si=-gNbpwS69E8EmjvI"
              target="_blank"
            >
              <h6 className="mb-6 text-base text-default-700 font-semibold ">
                Sorting Tailwind CSS Classes Automatically with Prettier
              </h6>
            </Link>

            <div className="flex justify-center">
              <iframe
                className="md:w-full rounded-md md:aspect-video"
                src="https://www.youtube.com/embed/_CntOc4hBcg?si=-gNbpwS69E8EmjvI"
                frameBorder={0}
              ></iframe>
            </div>
          </div>
        </div>
      </div>
    </>
  );
};

export default ProductsVideo;
