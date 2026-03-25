import { LuRocket, LuShoppingCart } from 'react-icons/lu';
import { Link } from 'react-router';

const Hero = () => {
  return (
    <section className="relative lg:pt-44 lg:pb-36 md:pt-34 md:pb-20 pt-30 pb-16">
      <div className="absolute rotate-45 size-125 border border-dashed border-t-default-300  border-l-default-300  border-r-default-300/40 border-b-default-700  rounded-full end-40 -bottom-62.5 z-20 lg:block hidden"></div>

      <div className="absolute rotate-45 size-175 border border-dashed border-t-default-300  border-l-default-300  border-r-default-300/40 border-b-default-700 rounded-full end-16 -bottom-87.5 z-20 lg:block hidden"></div>

      <div className="container">
        <div className="grid lg:grid-cols-2">
          <div>
            <h1 className="mb-8 leading-relaxed md:text-5xl text-4xl font-semibold text-default-800">
              Effective Management of Large Projects at
              <span className="relative inline-block px-2 mx-2 before:block before:absolute before:-inset-1 before:-skew-y-6 before:bg-primary/10 before:rounded-md before:backdrop-blur-xl">
                <span className="relative text-primary">Tailwick</span>
              </span>
            </h1>
            <p className="mb-6 text-lg text-default-500">
              Effective professional services project management means having a firm grasp on the
              scope, budget, resources, personnel, and timeline dedicated to a project. An effective
              project manager is able to manage unplanned issues while keeping the ball rolling on
              company goals and tasks in progress.
            </p>
            <div className="flex items-center gap-2.5">
              <Link to="#">
                <button type="button" className="btn bg-primary text-white">
                  <LuRocket className="size-4" />
                  Get Started
                </button>
              </Link>

              <Link to="#">
                <button
                  type="button"
                  className="btn hover:bg-danger border border-dashed border-danger hover:text-white bg-transparent text-danger"
                >
                  <LuShoppingCart className="size-4" />
                  Buy Now
                </button>
              </Link>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
};

export default Hero;
