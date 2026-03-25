import home from '@/assets/images/landing/home.jpg';
import widgets2 from '@/assets/images/landing/widgets-2.jpg';
import widgets3 from '@/assets/images/landing/widgets-3.jpg';
import widgets from '@/assets/images/landing/widgets.jpg';

const Feature = () => {
  return (
    <section id="features" className="relative py-32 bg-default-900">
      <div className="container">
        <div className="grid lg:grid-cols-12 grid-cols-1 gap-5">
          <div className="lg:col-span-5 relative z-20 lg:order-1 order-2">
            <div className="relative z-10 grid lg:grid-cols-2 grid-cols-3 gap-5">
              <div className="lg:col-span-2">
                <img src={widgets} alt="" className="rounded-xl ms-auto" />
              </div>

              <div className="lg:col-span-1 lg:mt-5">
                <img src={widgets3} alt="" className="rounded-xl" />
              </div>

              <div className="lg:col-span-1 lg:mt-5">
                <img src={widgets2} alt="" className="rounded-xl" />
              </div>
            </div>
          </div>

          <div className="lg:col-span-7 relative z-20 lg:-mt-72 lg:order-2 order-1">
            <img src={home} alt="" className="rounded-xl shadow-2xl" />
          </div>
        </div>

        <div className="mt-24">
          <h1 className="mb-16 capitalize text-white font-semibold text-4xl leading-normal">
            Build for anyone who works with Tailwick
          </h1>
        </div>
      </div>

      <div className="absolute rotate-45 size-125 border border-dashed border-default-300/40 rounded-full -start-80 bottom-48 z-10 lg:block  hidden md:block"></div>
      <div className="absolute rotate-45 size-175 border border-dashed border-default-300/40 rounded-full -start-96 bottom-24 z-10 lg:block  hidden md:block"></div>
    </section>
  );
};

export default Feature;
