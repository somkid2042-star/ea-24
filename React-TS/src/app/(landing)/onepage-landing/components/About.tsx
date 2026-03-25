import widgets4 from '@/assets/images/landing/widgets-4.jpg';
import widgets5 from '@/assets/images/landing/widgets-5.jpg';
import widgets6 from '@/assets/images/landing/widgets-6.jpg';
import widgets7 from '@/assets/images/landing/widgets-7.jpg';
import widgets8 from '@/assets/images/landing/widgets-8.jpg';
import widgets9 from '@/assets/images/landing/widgets-9.jpg';
import { LuMoveRight } from 'react-icons/lu';

const About = () => {
  return (
    <section id="about" className="relative lg:py-24 md:py-12 py-14">
      <div className="container">
        <div className="flex flex-col lg:gap-y-20 gap-y-12">
          <div className="text-center lg:w-3xl mx-auto">
            <h1 className="mb-6 leading-relaxed text-4xl font-semibold text-default-800">
              Why Developers Should Embrace{' '}
              <span className="relative inline-block px-2 mx-2 before:block before:absolute before:-inset-1 before:-skew-y-6 before:bg-primary/10 before:rounded-md before:backdrop-blur-xl">
                <span className="relative text-primary">Tailwick</span>
              </span>{' '}
            </h1>
            <p className="text-lg text-default-500">
              The purpose of developer communities is to provide the resources for developers to
              learn anything they want to.
            </p>
          </div>

          <div className="grid lg:grid-cols-12 gap-6 items-center">
            <div className="lg:col-span-5">
              <h1 className="mb-3 leading-normal capitalize text-4xl font-semibold text-default-800">
                Craft a Complete Website Quickly with the Help of Design Blocks
              </h1>
              <p className="text-lg mb-6 text-default-500">
                The block design approach basically breaks the design into small parts. These are
                built independently and then later combine into a customizable page which makes a
                website more flexible in terms of layout and content.
              </p>
              <button
                type="button"
                className="btn border-primary text-primary hover:bg-primary hover:text-white"
              >
                Discover Now
                <LuMoveRight className="size-4" />
              </button>
            </div>

            <div className="lg:col-span-6">
              <img src={widgets4} alt="" className="shadow-lg lg:ms-auto rounded-xl" />
              <img src={widgets5} alt="" className="shadow-lg -mt-24 rounded-xl ms-auto mr-24" />
            </div>
          </div>

          <div className="grid lg:grid-cols-12 gap-6 items-center lg:mt-12 mt-8">
            <div className="lg:col-span-6 lg:order-1 order-2">
              <img src={widgets6} alt="" className="shadow-lg  rounded-xl" />
              <img
                src={widgets7}
                alt=""
                className="shadow-lg -mt-24 ms-auto lg:me-24 md:me-40 rounded-xl"
              />
            </div>

            <div className="lg:col-span-5 lg:order-2 order-1">
              <h1 className="mb-3 leading-normal capitalize text-4xl font-semibold text-default-800">
                Boost Your Business Using Our Potent Tools
              </h1>
              <p className="text-lg mb-6 text-default-500">
                The block design approach basically breaks the design into small parts. These are
                built independently and then later combine into a customizable page which makes a
                website more flexible in terms of layout and content.
              </p>
              <button
                type="button"
                className="btn border-primary text-primary hover:bg-primary hover:text-white"
              >
                Discover Now
                <LuMoveRight className="size-4" />
              </button>
            </div>
          </div>

          <div className="grid lg:grid-cols-12 gap-6 items-center lg:mt-12 mt-8">
            <div className="lg:col-span-5">
              <h1 className="mb-3 leading-normal capitalize text-4xl font-semibold text-default-800">
                Building a User-Friendly Website is Effortless
              </h1>
              <p className="text-lg mb-4 text-default-500">
                With a user-friendly interface and easy navigation, the user decreases search time
                and increases satisfaction, fulfilling his needs in a fast and efficient way.
              </p>
              <ul className="flex flex-col gap-y-3 mb-6 text-lg list-disc list-inside text-default-900">
                <li>6+ Ready touse Dashboard</li>

                <li>Light, Dark & RTL Mode Support</li>

                <li>Multiple Layouts Support</li>
              </ul>

              <button
                type="button"
                className="btn border-primary text-primary hover:bg-primary hover:text-white"
              >
                Discover Now
                <LuMoveRight className="size-4" />
              </button>
            </div>

            <div className="lg:col-span-6">
              <img src={widgets8} alt="" className="shadow-lg lg:ms-auto me-auto rounded-xl" />
              <img
                src={widgets9}
                alt=""
                className="shadow-lg -mt-24 rounded-xl ms-auto lg:me-24 mr-40"
              />
            </div>
          </div>
        </div>
      </div>
    </section>
  );
};

export default About;
