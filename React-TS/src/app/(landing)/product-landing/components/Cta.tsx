const Cta = () => {
  return (
    <section className="relative md:py-20 py-12 border-t border-default-200">
      <div className="container">
        <div className="lg:flex justify-between items-center">
          <div>
            <h1 className="mb-4 capitalize text-default-800 leading-normal md:text-4xl text-3xl font-semibold">
              Sign up for update & newsletter
            </h1>
            <p className="text-lg text-default-500">
              Tell us which describes you, and we'll get in touch with next steps.
            </p>
          </div>

          <div className="flex p-1 lg:w-96 md:w-112 w-86 rounded-md  bg-default-200 relative mb-6 lg:mt-0 mt-4 h-12">
            <input
              type="email"
              placeholder="tailwick@themesdesign.in"
              className="px-3 text-sm border-0 ring-0 bg-transparent"
            />
            <button
              type="button"
              className="absolute end-1 top-1.25 btn text-white bg-gradient-to-r from-primary to-purple-500 hover:from-purple-500 hover:to-primary border-0"
            >
              Subscribe Now
            </button>
          </div>
        </div>
      </div>
    </section>
  );
};

export default Cta;
