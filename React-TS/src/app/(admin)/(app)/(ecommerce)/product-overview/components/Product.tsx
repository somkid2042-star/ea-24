import img01 from '@/assets/images/product/img-01.png';
import img09 from '@/assets/images/product/img-09.png';
import img12 from '@/assets/images/product/img-12.png';
import img13 from '@/assets/images/product/img-13.png';
import overview01 from '@/assets/images/product/overview-01.png';
import overview02 from '@/assets/images/product/overview-02.png';
import { LuCircleHelp, LuRepeat, LuShare2, LuShoppingCart, LuStar, LuStore } from 'react-icons/lu';
import { Link } from 'react-router';
const Product = () => {
  return (
    <div className="col-span-1">
      <div className="sticky top-24">
        <div className="card mb-5">
          <div className="card-body">
            <div className="grid md:grid-cols-3 grid-cols-1 gap-5 mb-5">
              <div className="md:col-span-2 grid-cols-1">
                <div className="rounded-md bg-default-100">
                  <img src={overview01} alt="" />
                </div>
              </div>

              <div className="col-span-1">
                <div className="rounded-md bg-default-100 mb-5">
                  <img src={overview02} alt="" />
                </div>

                <div className="rounded-md bg-default-100">
                  <img src={img01} alt="" />
                </div>
              </div>
            </div>

            <div className="grid md:grid-cols-3 grid-cols-1 gap-5">
              <div className="rounded-md bg-default-100">
                <img src={img09} alt="" />
              </div>

              <div className="rounded-md bg-default-100">
                <img src={img12} alt="" />
              </div>

              <div className="rounded-md bg-default-100">
                <img src={img13} alt="" />
              </div>
            </div>

            <div className="grid grid-cols-2 gap-2 mt-4">
              <Link
                to="/cart"
                className="border border-primary w-full rounded btn text-primary hover:bg-primary/10 border-dashed"
              >
                <LuShoppingCart className="size-3" />
                Add to Cart
              </Link>

              <button className="bg-danger/85 w-full rounded btn text-white hover:bg-danger">
                Buy Now
              </button>
            </div>

            <div className="flex items-center gap-3 mt-3 justify-evenly">
              <Link
                to="#"
                className="flex items-center gap-1.25 text-default-700 text-sm transition-all duration-300 hover:text-primary"
              >
                <LuRepeat className="size-3" />
                <span className="align-middle">Compare</span>
              </Link>

              <Link
                to="#"
                className="flex items-center gap-1.25 text-default-700 text-sm transition-all duration-300 hover:text-primary"
              >
                <LuCircleHelp className="size-3" />
                <span className="align-middle">Ask a Question</span>
              </Link>

              <Link
                to="#"
                className="flex items-center gap-1.25 text-default-700 text-sm transition-all duration-300 hover:text-primary"
              >
                <LuShare2 className="size-3" />
                <span className="align-middle">Share</span>
              </Link>
            </div>
          </div>
        </div>

        <div className="card">
          <div className="card-body border-b border-b-default-200">
            <div className="flex justify-between flex-wrap gap-5">
              <h6 className="text-default-800 font-semibold text-[15px] flex items-center gap-1.25">
                <LuStore className="size-4" />
                Themesdesign
              </h6>

              <span className="flex items-center gap-1.25 text-default-700">
                <LuStar className="size-4 text-yellow-500" />
                (4.8)
              </span>
            </div>
          </div>

          <div className="card-body">
            <div className="flex gap-5 justify-between">
              <h6 className="text-default-800 font-semibold text-[15px] flex items-center gap-1.25">
                <LuStore className="size-4 text-orange-500" />
                California, USA
              </h6>

              <button className="text-white btn btn-sm btn-primary">View Store</button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Product;
