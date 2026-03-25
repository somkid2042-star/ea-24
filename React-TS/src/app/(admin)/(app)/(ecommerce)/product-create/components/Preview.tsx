import image13 from '@/assets/images/product/img-03.png';

const Preview = () => {
  return (
    <div className="lg:col-span-3 col-span-1">
      <div className="sticky top-20">
        <div className="card">
          <div className="card-body">
            <h6 className="mb-4 card-title">Product Card Preview</h6>
            <div className="px-5 py-8 rounded-md bg-info/10">
              <img src={image13} alt="" className="block mx-auto h-44" width={176} />
            </div>

            <div className="mt-3">
              <h5 className="mb-2 text-lg text-default-800 font-medium ">
                $145.99 <small className="font-normal line-through text-default-600">299.99</small>
              </h5>
              <h6 className="mb-1 text-[15px] font-semibold text-default-800">
                Fastcolors Typography Men
              </h6>
              <p className="text-default-600">Men's Fashion</p>
            </div>

            <h6 className="mt-3 mb-2 card-title">Colors</h6>
            <div className="flex gap-2 flex-wrap items-center">
              <input
                id="color1"
                type="checkbox"
                className="form-checkbox rounded-full text-primary"
              />
              <input
                id="color2"
                type="checkbox"
                className="form-checkbox rounded-full text-danger"
              />
              <input
                id="color3"
                type="checkbox"
                className="form-checkbox rounded-full text-success"
              />
              <input
                id="color5"
                type="checkbox"
                className="form-checkbox rounded-full text-secondary"
              />
            </div>

            <h6 className="mt-3 mb-2 card-title">Sizes</h6>
            <div className="flex gap-2 flex-wrap items-center">
              <button className="size-7.5 text-xs text-default-500 btn border border-default-200 hover:bg-primary/10 hover:border-primary focus:bg-primary/10 focus:border-primary">
                XS
              </button>
              <button className="active size-7.5 text-xs text-default-500 btn border border-default-200 hover:bg-primary/10 hover:border-primary focus:bg-primary/10 focus:border-primary">
                S
              </button>
              <button className="size-7.5 text-xs text-default-500 btn border border-default-200 hover:bg-primary/10 hover:border-primary focus:bg-primary/10 focus:border-primary">
                M
              </button>
              <button className="size-7.5 text-xs text-default-500 btn border border-default-200 hover:bg-primary/10 hover:border-primary focus:bg-primary/10 focus:border-primary">
                L
              </button>
              <button className="size-7.5 text-xs text-default-500 btn border border-default-200 hover:bg-primary/10 hover:border-primary focus:bg-primary/10 focus:border-primary">
                XL
              </button>
              <button className="size-7.5 text-xs text-default-500 btn border border-default-200 hover:bg-primary/10 hover:border-primary focus:bg-primary/10 focus:border-primary">
                2XL
              </button>
            </div>

            <div className="grid md:grid-cols-2 grid-cols-1 gap-2 mt-4">
              <button className="border border-dashed border-primary bg-transparent btn text-primary hover:bg-primary/10">
                Create Product
              </button>

              <button className="bg-purple-500 text-white btn hover:bg-purple-600">Draft</button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Preview;
