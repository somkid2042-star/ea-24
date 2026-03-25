import ProductHome from '@/assets/images/landing/product-home.png';
import { LuPlus, LuShoppingCart } from 'react-icons/lu';
import { Link } from 'react-router';

const Hero = () => {
  return (
    <section id="home" className="relative lg:pb-24 md:pt-48 pt-40">
      <div className="absolute top-0 start-0 size-64 bg-primary/10 blur-3xl"></div>
      <div className="absolute bottom-0 end-0 size-64 bg-purple-500/10 blur-3xl"></div>

      <div className="container">
        <div className="grid lg:grid-cols-12 items-center gap-5">
          <div className="lg:col-span-5">
            <h1 className="mb-4 leading-relaxed lg:text-6xl md:text-4xl text-4xl font-semibold text-default-800">
              Exclusive Collections 2024
            </h1>
            <p className="mb-6 text-lg text-default-500">
              In 2024, metallics will be taking over the sneaker world. I love this trend because
              there are so many different ways to wear it. You can wear sequined sneakers, white
              sneakers with metallic accents, or all-over silver.
            </p>
            <div>
              <Link to="#">
                <button
                  type="button"
                  className="btn border-0 bg-gradient-to-r from-primary to-purple-500 hover:from-purple-500 hover:to-primary text-white rounded-md"
                >
                  Shop Now
                  <LuShoppingCart className="size-4" />
                </button>
              </Link>
            </div>
          </div>

          <div className="lg:col-span-6">
            <div className="relative">
              <div className="absolute text-center -z-20 -top-20 -end-64 md:text-[10rem] lg:text-[14rem] text-default-100/50 font-normal font-tourney lg:block hidden">
                Unique Fashion
              </div>

              <div className="hs-tooltip [--placement:top] inline-block z-40">
                <button
                  type="button"
                  className="hs-tooltip-toggle size-10 justify-center items-center rounded-full absolute lg:flex hidden bottom-20 bg-card text-black left-60"
                >
                  <LuPlus className="size-5" />
                  <span
                    className="hs-tooltip-content hs-tooltip-shown:opacity-100 hs-tooltip-shown:visible opacity-0 transition-opacity inline-block absolute invisible  py-1 px-2 bg-default-900 text-xs font-medium text-white rounded-md shadow-2xs dark:bg-neutral-700"
                    role="tooltip"
                  >
                    $199.99
                  </span>
                </button>
                <img src={ProductHome} alt="" className="lg:ms-40 md:ms-20 w-xl mx-auto" />
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
};

export default Hero;
