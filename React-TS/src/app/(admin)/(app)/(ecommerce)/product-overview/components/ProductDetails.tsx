import { Link } from 'react-router';
import {
  LuContainer,
  LuEllipsis,
  LuSquarePen,
  LuStar,
  LuStarHalf,
  LuTag,
  LuTrash2,
  LuTruck,
} from 'react-icons/lu';

const ProductDetails = () => {
  return (
    <>
      <div className="flex justify-between items-center">
        <span className="px-2.5 py-0.5 text-xs inline-block font-semibold rounded bg-info/10 text-info">
          New Arrivals
        </span>

        <div className="hs-dropdown relative inline-flex">
          <button
            type="button"
            className="hs-dropdown-toggle btn size-7.5 bg-default-200 hover:bg-default-600 text-default-500 hover:text-white"
            aria-haspopup="menu"
            aria-expanded="false"
            aria-label="Dropdown"
            hs-dropdown-placement="bottom-end"
          >
            <LuEllipsis className="size-4 " />
          </button>

          <div className="hs-dropdown-menu" role="menu">
            <Link
              className="flex items-center gap-1.5 py-1.5 font-medium px-3 text-sm text-default-500 hover:bg-default-150 rounded"
              to="#"
            >
              <LuSquarePen className="size-3" />
              Edit
            </Link>

            <Link
              className="flex items-center gap-1.5 py-1.5 font-medium px-3 text-sm text-default-500 hover:bg-default-150 rounded"
              to="#"
            >
              <LuTrash2 className="size-3" />
              Delete
            </Link>
          </div>
        </div>
      </div>

      <h5 className="mt-3 mb-1 text-xl text-default-800 font-semibold">
        Smartees Printed Men Round Neck Pink
      </h5>

      <ul className="flex flex-wrap text-sm items-center gap-4 mb-5 text-default-500">
        <li>
          <Link to="#!" className="font-medium underline text-primary text-sm">
            Rossie Fadel
          </Link>
        </li>
        <li>
          Seller:{' '}
          <Link to="#!" className="font-medium text-sm">
            Themesdesign
          </Link>
        </li>
        <li>
          Published: <span className="font-medium text-sm">20 Oct, 2023</span>
        </li>
      </ul>

      <div className="flex flex-wrap items-center gap-3 mb-4">
        <div className="flex items-center gap-2 text-yellow-500">
          <LuStar className="size-4 fill-yellow-500" />
          <LuStar className="size-4 fill-yellow-500" />
          <LuStar className="size-4 fill-yellow-500" />
          <LuStar className="size-4 fill-yellow-500" />
          <LuStarHalf className="size-4 fill-yellow-500" />
          <div className="text-default-800 text-sm">
            <h6>(4.8)</h6>
          </div>
        </div>

        <div className="text-default-800 text-sm">
          <h6>973 Reviews</h6>
        </div>

        <div className="text-default-800 text-sm">
          <h6>1,231 Sold</h6>
        </div>
      </div>

      <div className="mb-4">
        <p className="mb-1 text-success text-sm">Special Price</p>

        <h4 className="text-default-900 font-semibold text-xl">
          $487.32{' '}
          <small className="font-normal text-base line-through align-middle text-default-500">
            $599.99
          </small>{' '}
          <small className="text-success text-base align-middle">20% Off</small>
        </h4>
      </div>

      <h6 className="mb-3 text-[15px] font-semibold text-default-800">Select Color</h6>

      <div className="flex gap-2">
        <input
          id="color1"
          name="SelectColor"
          type="radio"
          className="form-radio rounded-sm size-5 text-primary"
        />

        <input
          id="color2"
          name="SelectColor"
          type="radio"
          className="form-radio rounded-sm size-5 text-red-300"
        />

        <input
          id="color3"
          name="SelectColor"
          type="radio"
          className="form-radio rounded-sm size-5 text-green-300"
        />

        <input
          id="color4"
          name="SelectColor"
          type="radio"
          className="form-radio rounded-sm size-5 text-default-500"
        />

        <input
          id="color5"
          name="SelectColor"
          type="radio"
          className="form-radio rounded-sm size-5 text-purple-500"
        />

        <input
          id="color6"
          name="SelectColor"
          type="radio"
          className="form-radio rounded-sm size-5 text-sky-500"
        />

        <input
          id="color7"
          name="SelectColor"
          type="radio"
          className="form-radio rounded-sm size-5 text-yellow-500"
        />

        <input
          id="color8"
          name="SelectColor"
          type="radio"
          className="form-radio rounded-sm size-5 text-green-500"
        />

        <input
          id="color9"
          name="SelectColor"
          type="radio"
          className="form-radio rounded-sm size-5 text-default-800"
        />

        <input
          id="color10"
          name="SelectColor"
          type="radio"
          className="form-radio rounded-sm size-5 text-default-200"
        />

        <input
          id="color11"
          name="SelectColor"
          type="radio"
          className="form-radio rounded-sm size-5 text-emerald-300"
        />
      </div>

      <h6 className="mt-5 mb-3 card-title">Select Size</h6>

      <div className="flex gap-2 items-center">
        <button className="btn  size-8 text-xs text-default-500 border border-default-200 hover:bg-primary/10 hover:border-primary focus:bg-primary/10 focus:border-primary">
          XS
        </button>
        <button className="active btn  size-8 text-xs text-default-500 border border-default-200 hover:bg-primary/10 hover:border-primary focus:bg-primary/10 focus:border-primary">
          S
        </button>
        <button className="btn  size-8 text-xs text-default-500 border border-default-200 hover:bg-primary/10 hover:border-primary focus:bg-primary/10 focus:border-primary">
          M
        </button>
        <button className="btn  size-8 text-xs text-default-500 border border-default-200 hover:bg-primary/10 hover:border-primary focus:bg-primary/10 focus:border-primary">
          L
        </button>
        <button className="btn  size-8 text-xs text-default-500 border border-default-200 hover:bg-primary/10 hover:border-primary focus:bg-primary/10 focus:border-primary">
          XL
        </button>
        <button className="btn  size-8 text-xs text-default-500 border border-default-200 hover:bg-primary/10 hover:border-primary focus:bg-primary/10 focus:border-primary">
          2XL
        </button>
      </div>

      <h6 className="mt-5 mb-3 card-title">Available Offers (4)</h6>

      <div className="flex gap-2 flex-col">
        <div className="flex gap-1.75 items-center">
          <div>
            <LuTag className="size-4 text-success fill-success/20" />
          </div>

          <div className="text-default-700 text-sm">
            <span className="text-default-800 font-semibold">Bank Offer</span> 10% Instant Discount
            on Paypal, up to $1250 on orders of $5,000 and above
            <Link to="#" className="underline text-primary">
              T&C
            </Link>
          </div>
        </div>

        <div className="flex gap-1.75 items-center text-sm">
          <div>
            <LuTag className="size-4 text-success fill-success/20" />
          </div>

          <div className="text-default-700 text-sm">
            <span className="text-default-800 font-semibold"> Special Price</span> Get at flat $199
            <Link to="#" className="underline text-primary">
              T&C
            </Link>
          </div>
        </div>

        <div className="flex gap-1.75 items-center text-sm">
          <div>
            <LuTag className="size-4 text-success fill-success/20" />
          </div>

          <div className="text-default-700">
            <span className="text-default-800 font-semibold"> Partner Offer</span> Purchase now &
            get 1 surprise cashback coupon in Future
            <Link to="#" className="underline text-primary">
              Know More
            </Link>
          </div>
        </div>

        <div className="flex gap-1.75 items-center text-sm">
          <div>
            <LuTag className="size-4 text-success fill-success/20" />
          </div>

          <div className="text-default-700">
            <span className="text-default-800 font-semibold"> Bank Offer </span> UPI Offer Men's
            Clothing
            <Link to="#" className="underline text-primary">
              T&C
            </Link>
          </div>
        </div>
      </div>

      <div className="grid lg:grid-cols-3 grid-cols-1 gap-3 my-5">
        <div className="flex items-center gap-5 p-4 border rounded-md border-default-200">
          <div className="flex items-center justify-center">
            <LuTruck className="size-6 text-default-500 fill-default-200" />
          </div>

          <div className="text-default-700 text-sm">
            <h6 className="mb-2 text-default-800 font-semibold">Estimated Delivery</h6>
            <p>01 - 07 Dec, 2023</p>
          </div>
        </div>

        <div className="flex items-center gap-5 p-4 border rounded-md border-default-200">
          <div className="flex items-center justify-center">
            <LuContainer className="size-6 text-default-500 fill-default-200" />
          </div>

          <div className="text-default-700 text-sm">
            <h6 className="mb-2 text-default-800 font-semibold">Free Shipping & Returns</h6>
            <p>On all orders over $200.00</p>
          </div>
        </div>
      </div>

      <div className="mt-5">
        <h6 className="card-title mb-3">Product Description:</h6>
        <p className="mb-2 text-sm text-default-600">
          Latest <b>Trends</b> in Fashion Clothing. Currently, the latest clothing trends for women
          on FabAlley include playful check print, breezy floral motif, bold red hue, cool denim
          fabric, quirky polka dot and romantic ruffles.
        </p>
        <p className="text-default-600 text-sm">
          <b>Avoid shapeless and baggy clothing</b>. Stay away from pieces with extra fabric at the
          hips or bust to keep your look proportionate. Avoid wearing ruffles or pleats around your
          waist or hips. Be sure to wear supportive undergarments that fit you well!
        </p>
      </div>

      <div className="mt-5">
        <h6 className="card-title">Features:</h6>
        <div className="overflow-x-auto">
          <table className="w-full">
            <tbody>
              <tr>
                <th className="px-3.5 py-2.5 font-semibold text-start text-sm w-64 text-default-500">
                  Type
                </th>
                <td className="px-3.5 py-2.5 text-sm text-default-700">Round Neck</td>
              </tr>

              <tr>
                <th className="px-3.5 py-2.5 font-semibold text-start w-64 text-default-500 text-sm">
                  Sleeve
                </th>
                <td className="px-3.5 py-2.5 text-sm text-default-700">Half Sleeve</td>
              </tr>

              <tr>
                <th className="px-3.5 py-2.5 font-semibold text-start w-64 text-default-500 text-sm">
                  Fit
                </th>
                <td className="px-3.5 py-2.5 text-sm text-default-700">Regular</td>
              </tr>

              <tr>
                <th className="px-3.5 py-2.5 font-semibold text-start w-64 text-default-500 text-sm">
                  Fabric
                </th>
                <td className="px-3.5 py-2.5 text-sm text-default-700">Cotton Blend</td>
              </tr>

              <tr>
                <th className="px-3.5 py-2.5 font-semibold text-start w-64 text-default-500 text-sm">
                  Pack of
                </th>
                <td className="px-3.5 py-2.5 text-sm text-default-700">1</td>
              </tr>

              <tr>
                <th className="px-3.5 py-2.5 font-semibold text-start w-64 text-default-500 text-sm">
                  Product Code
                </th>
                <td className="px-3.5 py-2.5 text-sm text-default-700">TWT1542</td>
              </tr>

              <tr>
                <th className="px-3.5 py-2.5 font-semibold text-start w-64 text-default-500 text-sm">
                  Ideal for
                </th>
                <td className="px-3.5 py-2.5 text-sm text-default-700">Women</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </>
  );
};

export default ProductDetails;
