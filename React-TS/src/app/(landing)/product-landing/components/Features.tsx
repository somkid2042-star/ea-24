import Cta from '@/assets/images/landing/cta.png';
import { LuMoveRight } from 'react-icons/lu';
import { Link } from 'react-router';

const Features = () => {
  return (
    <section id="Features" className="relative lg:pb-28 pb-10">
      <div className="absolute top-0 start-0 size-64 bg-purple-500/10 blur-3xl"></div>
      <div>
        <div className="container">
          <div className="grid lg:grid-cols-2 items-center">
            <div className="lg:w-lg">
              <h1 className="mb-3 leading-normal capitalize text-4xl font-semibold text-default-800">
                Explore our flagship product and discover its unique features
              </h1>
              <p className="mb-5 text-lg text-default-500">
                Whatever your running gait, a good pair of running shoes will provide flexibility,
                durability, and support.
              </p>
              <ul className="flex flex-col gap-y-2 mb-6 list-disc list-inside text-sm text-default-800">
                <li>Matches Your Foot Shape & Type</li>

                <li>Easy to Wear</li>

                <li>Heels That You Can Wear</li>

                <li>Good Quality & Condition</li>

                <li>Segments of Solid Rubber</li>
              </ul>
              <Link to="#" className="btn text-primary text-base">
                Shopping Now
                <LuMoveRight className="size-4" />
              </Link>
            </div>

            <div className="relative lg:mt-0 mt-6">
              <div
                className="absolute start-0 bg-center bg-cover lg:bottom-40 bottom-20  w-52 h-96 bg-[url('../images/cta-2.png')] rounded-md md:block hidden"
                data-aos="fade-left"
                data-aos-delay="400"
              >
                <div className="absolute inset-0 bg-gradient-to-b from-purple-500/30 to-accent from-30%"></div>
              </div>

              <div className="md:ms-20">
                <img src={Cta} alt="" className="w-lg relative inline-block" />
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
};

export default Features;
