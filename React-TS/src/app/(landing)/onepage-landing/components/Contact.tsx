import { LuShoppingCart } from 'react-icons/lu';

const Contact = () => {
  return (
    <section id="contact" className="relative py-20 bg-blue-700/80 dark:bg-blue-900">
      <div className="absolute size-125 border border-dashed rotate-45 border-t-primary border-l-primary border-r-default-700 border-b-default-700 rounded-full right-40 -bottom-62.5 z-10 lg:block hidden"></div>
      <div className="container">
        <div className="lg:flex justify-between items-center">
          <div>
            <h1 className="mb-4 capitalize text-blue-50 leading-normal text-4xl font-semibold">
              Ready to get started with Tailwick
            </h1>

            <p className="text-lg text-blue-200">
              Tell us which describes you, and we'll get in touch with next steps.
            </p>
          </div>

          <button
            type="button"
            className="relative z-20 btn  bg-card hover:text-blue-800 text-primary lg:mt-0 md:mt-4"
          >
            <LuShoppingCart className="size-4" />
            Purchase Now
          </button>
        </div>
      </div>
    </section>
  );
};

export default Contact;
