import { LuContainer, LuTruck } from 'react-icons/lu';

const OrderSummary = () => {
  return (
    <div className="col-span-1">
      <div className="sticky top-20">
        <div className="p-5 card mb-5">
          <h6 className="card-title mb-4">Order Summary</h6>
          <div className="overflow-x-auto">
            <table className="w-full">
              <tbody className="table-total">
                <tr className="text-sm">
                  <td className="py-2 text-default-500"> Sub Total </td>
                  <td className="py-2 text-default-500 cart-subtotal"> $932.16 </td>
                </tr>

                <tr className="text-sm">
                  <td className="py-2 text-default-500"> Estimated Tax (18%)</td>
                  <td className="py-2 text-default-500 cart-tax"> $167.79</td>
                </tr>

                <tr className="text-sm">
                  <td className="py-2 text-default-500">Item Discounts (12%) </td>
                  <td className="py-2 text-default-500 cart-discount"> -$111.86 </td>
                </tr>

                <tr className="text-sm">
                  <td className="py-2 text-default-500"> Shipping Charge </td>
                  <td className="py-2 text-default-500 cart-shipping"> $0 </td>
                </tr>

                <tr className="font-semibold text-sm text-default-800">
                  <td className="pt-2"> Total Amount (USD) </td>
                  <td className="pt-2 cart-total"> $988.09 </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>

        <div className="grid grid-cols-2 gap-2 mb-5">
          <button
            type="button"
            className="btn bg-danger/90 text-white transition-all duration-300 hover:bg-danger"
          >
            Continue to Shopping
          </button>

          <button
            type="button"
            className="btn bg-primary/90 text-white transition-all duration-300 hover:bg-primary"
          >
            Checkout
          </button>
        </div>

        <div className="p-5 card mb-5">
          <div className="flex items-center gap-5">
            <div className="btn bg-default-200 size-12">
              <LuTruck className="size-6 text-default-500 fill-default-200" />
            </div>

            <div>
              <h6 className="mb-1 text-default-800 font-semibold text-sm">Estimated Delivery</h6>
              <p className="text-default-500 text-sm">01 - 07 Dec, 2023</p>
            </div>
          </div>
        </div>

        <div className="p-5 card">
          <div className="flex items-center gap-5">
            <div className="btn bg-default-200 size-12">
              <LuContainer className="size-6 text-default-500 fill-default-200" />
            </div>

            <div>
              <h6 className="mb-1 text-default-800 font-semibold text-sm">
                Free Shipping & Returns
              </h6>
              <p className="text-default-500 text-sm">On all orders over $200.00</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default OrderSummary;
