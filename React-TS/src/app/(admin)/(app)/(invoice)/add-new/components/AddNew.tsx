import { Link } from 'react-router';
import Flatpickr from 'react-flatpickr';
import { LuDownload, LuEye, LuMinus, LuPlus, LuRefreshCcw, LuSave } from 'react-icons/lu';

const AddNew = () => {
  return (
    <>
      <div className="lg:flex justify-between items-center mb-5">
        <div>
          <h6 className="mb-1 card-title">New Invoice</h6>
        </div>

        <div className="flex flex-wrap items-center md:justify-end gap-2 md:mt-0 mt-4">
          <button className="bg-default-200 text-default-500 text-nowrap btn border-0 hover:bg-default-300">
            <LuEye className="size-4  me-1" />
            Preview
          </button>

          <button
            className="bg-info/90 text-white btn text-nowrap border-0 hover:bg-info"
            onClick={() => window.print()}
          >
            Save Draft
          </button>

          <button className="btn bg-primary text-white text-nowrap border-0">
            <LuSave className="size-4 text-white me-1" />
            Save & Download
          </button>
        </div>
      </div>

      <div className="card">
        <div className="card-body">
          <h6 className="mb-4 text-default-800 underline text-base font-semibold">
            Generale Info:
          </h6>
          <div className="grid lg:grid-cols-4 grid-cols-1 gap-5 mb-6">
            <div className="col-span-1">
              <label
                htmlFor="First Name"
                className="inline-block mb-2 text-sm text-default-800 font-medium"
              >
                Invoice No.
              </label>
              <input
                type="text"
                id="First Name"
                className="form-input"
                placeholder="Enter invoice no.."
                value="#TW15090251"
                readOnly
              />
            </div>

            <div className="col-span-1">
              <label
                htmlFor="invoiceNo"
                className="inline-block mb-2 text-sm text-default-800 font-medium"
              >
                Invoice Date
              </label>
              <Flatpickr
                options={{
                  mode: 'single',
                  dateFormat: 'd M, Y',
                }}
                className="form-input"
                placeholder="Select Date"
              />
            </div>

            <div className="col-span-1">
              <label
                htmlFor="InvoiceDue"
                className="inline-block mb-2 text-sm text-default-800 font-medium"
              >
                Invoice Due
              </label>
              <input
                type="date"
                id="InvoiceDue"
                className="form-input"
                placeholder="Invoice Due"
                required
              />
            </div>
            <div className="col-span-1">
              <label
                htmlFor="legalRegistrationNo"
                className="inline-block mb-2 text-sm text-default-800 font-medium"
              >
                Legal Registration No.
              </label>
              <input
                type="number"
                id="legalRegistrationNo"
                className="form-input"
                placeholder="Legal Registration No"
                required
              />
            </div>

            <div className="col-span-1">
              <label
                htmlFor="emailInvoiceInput"
                className="inline-block mb-2 text-sm text-default-800 font-medium"
              >
                Email
              </label>
              <input
                type="email"
                id="emailInvoiceInput"
                className="form-input"
                placeholder="tailwick@themesdesign.in"
                required
              />
            </div>

            <div className="col-span-1">
              <label
                htmlFor="websiteInput"
                className="inline-block mb-2 text-default-800 text-sm font-medium"
              >
                Website
              </label>
              <input
                type="text"
                id="websiteInput"
                className="form-input"
                placeholder="www.themesdesign.in"
                required
              />
            </div>

            <div className="col-span-1">
              <label
                htmlFor="contactInput"
                className="inline-block mb-2 text-default-800 text-sm font-medium"
              >
                Contact US
              </label>
              <input
                type="number"
                id="contactInput"
                className="form-input"
                placeholder="(241) 1234 567 8900"
                required
              />
            </div>

            <div className="col-span-1">
              <label
                htmlFor="paymentStatus"
                className="inline-block mb-2 text-sm text-default-800 font-medium"
              >
                Payment Status
              </label>
              <select className="form-input">
                <option defaultValue="Paid">Paid</option>
                <option value="Unpaid">Unpaid</option>
                <option value="Cancel">Cancel</option>
                <option value="Refund">Refund</option>
              </select>
            </div>
          </div>

          <h6 className="mb-4 text-default-800 text-base underline font-semibold">
            Shipping Info:
          </h6>

          <div className="grid lg:grid-cols-4 grid-cols-1 gap-5">
            <div className="col-span-1">
              <label
                htmlFor="fullNameShippingInput"
                className="inline-block mb-2 text-sm text-default-800 font-medium"
              >
                Full Name
              </label>
              <input
                type="text"
                id="fullNameShippingInput"
                className="form-input"
                placeholder="Full Name"
                required
              />
            </div>

            <div className="col-span-1">
              <label
                htmlFor="phoneNoShippingInput"
                className="inline-block mb-2 text-sm text-default-800 font-medium"
              >
                Phone No.
              </label>
              <input
                type="number"
                id="phoneNoShippingInput"
                className="form-input"
                placeholder="(00) 1234 567 8956"
                required
              />
            </div>

            <div className="col-span-1">
              <label
                htmlFor="alternativeNoShippingInput"
                className="inline-block mb-2 text-sm text-default-800 font-medium"
              >
                Alternative No.
              </label>
              <input
                type="number"
                id="alternativeNoShippingInput"
                className="form-input"
                placeholder="(00) 1234 567 8956"
                required
              />
            </div>

            <div className="col-span-1">
              <label
                htmlFor="taxShippingInput"
                className="inline-block mb-2 text-sm text-default-800 font-medium"
              >
                TAX No.
              </label>
              <input
                type="number"
                id="taxShippingInput"
                className="form-input"
                placeholder="12-34567974"
                required
              />
            </div>

            <div className="lg:col-span-4 col-span-1">
              <label
                htmlFor="addressShippingInput"
                className="inline-block mb-2 text-sm text-default-800 font-medium"
              >
                Address
              </label>
              <textarea
                className="form-input"
                placeholder="Address"
                id="addressShippingInput"
                rows={3}
              ></textarea>
            </div>
          </div>

          <div className="mt-5">
            <div className="flex items-center gap-2">
              <input type="checkbox" id="switchAddress" className="form-switch" />
              <label htmlFor="switchAddress" className="text-sm text-default-600 ">
                Will your Shipping & Billing address same?
              </label>
            </div>
          </div>

          <h6 className="my-5 text-default-800 text-base underline font-semibold">Billing Info:</h6>

          <div className="grid lg:grid-cols-4 grid-cols-1 gap-5">
            <div className="col-span-1">
              <label
                htmlFor="fullNameBillingInput"
                className="inline-block mb-2 text-sm text-default-800 font-medium"
              >
                Full Name
              </label>
              <input
                type="text"
                id="fullNameBillingInput"
                className="form-input"
                placeholder="Full Name"
                required
              />
            </div>

            <div className="col-span-1">
              <label
                htmlFor="phoneNoBillingInput"
                className="inline-block mb-2 text-sm text-default-800 font-medium"
              >
                Phone No.
              </label>
              <input
                type="number"
                id="phoneNoBillingInput"
                className="form-input"
                placeholder="(00) 1234 567 8956"
                required
              />
            </div>

            <div className="col-span-1">
              <label
                htmlFor="alternativeNoBillingInput"
                className="inline-block mb-2 text-sm text-default-800 font-medium"
              >
                Alternative No.
              </label>
              <input
                type="number"
                id="alternativeNoBillingInput"
                className="form-input"
                placeholder="(00) 1234 567 8956"
                required
              />
            </div>

            <div className="col-span-1">
              <label
                htmlFor="taxBillingInput"
                className="inline-block mb-2 text-sm text-default-800 font-medium"
              >
                TAX No.
              </label>
              <input
                type="number"
                id="taxBillingInput"
                className="form-input"
                placeholder="12-34567974"
                required
              />
            </div>

            <div className="lg:col-span-4 grid-cols-1">
              <label
                htmlFor="addressBillingInput"
                className="inline-block mb-2 text-sm text-default-800 font-medium"
              >
                Address
              </label>
              <textarea
                className="form-input"
                placeholder="Address"
                id="addressBillingInput"
                rows={3}
              ></textarea>
            </div>
          </div>

          <h6 className="my-4 text-default-800 text-base underline font-semibold">
            Products Info:
          </h6>

          <div className="overflow-x-auto">
            <table className="w-full whitespace-nowrap">
              <thead>
                <tr className="border border-default-200 text-default-500 text-center font-medium  uppercase">
                  <th className="px-3.5 py-2.5">Item Name</th>
                  <th className="px-3.5 py-2.5">Quantity</th>
                  <th className="px-3.5 py-2.5">Price</th>
                  <th className="px-3.5 py-2.5">Discount</th>
                  <th className="px-3.5 py-2.5">TAX</th>
                  <th className="px-3.5 py-2.5 w-44">Total</th>
                </tr>
              </thead>

              <tbody className="item-list">
                <tr className="border border-default-200">
                  <td className="">
                    <input
                      type="text"
                      id="itemName1"
                      className="bg-transparent block w-full border-0 rounded-md text-sm text-default-500 placeholder:text-default-400 ring-0"
                      placeholder="Item Name"
                      required
                    />
                  </td>

                  <td className="w-40 border rounded-xl border-default-200 ">
                    <div className="flex p-2 justify-center">
                      <button
                        type="button"
                        className="size-9 minusBtn border rounded-tr-0 rounded-br-0 border-default-200 flex justify-center items-center"
                      >
                        <LuMinus className="size-4 text-default-500" />
                      </button>
                      <input
                        type="number"
                        className="text-center ps-2 w-12 h-9 border-t border-b border-e-0 bg-transparent border-l-0 border-default-200 ring-0 product-quantity focus:shadow-none"
                        value="2"
                        min="0"
                        max="100"
                        readOnly
                      />
                      <button
                        type="button"
                        className="size-9 plusBtn rounded-tl-0 rounded-bl-0 border  border-default-200 flex justify-center items-center"
                      >
                        <LuPlus className="size-4 text-default-500" />
                      </button>
                    </div>
                  </td>

                  <td className="w-40 border border-default-200">
                    <input
                      type="text"
                      id="itemName1"
                      className="bg-transparent block w-full border-0 rounded-md text-sm text-default-500 placeholder:text-default-400 ring-0"
                      placeholder="$00.00"
                      required
                    />
                  </td>

                  <td className="w-40 border border-default-200">
                    <input
                      type="text"
                      id="itemName1"
                      className="bg-transparent block w-full border-0 rounded-md text-sm text-default-500 placeholder:text-default-400 ring-0"
                      placeholder="0%"
                      required
                    />
                  </td>

                  <td className="w-40 border border-default-200">
                    <input
                      type="text"
                      id="itemName1"
                      className="bg-transparent block w-full border-0 rounded-md text-sm text-default-500 placeholder:text-default-400 ring-0"
                      placeholder="0%"
                      required
                    />
                  </td>

                  <td className="border border-default-200 " rowSpan={2}>
                    <div className="mb-1">
                      <input
                        type="text"
                        id="ItemTotal"
                        className="bg-transparent block w-full border-0 rounded-md text-sm text-default-500 placeholder:text-default-400 ring-0"
                        placeholder="$00.00"
                        required
                        readOnly
                      />
                    </div>

                    <input
                      type="text"
                      id="itemDiscountsInput"
                      className="bg-transparent block w-full border-0 rounded-md text-sm text-default-500 placeholder:text-default-400 ring-0"
                      placeholder="-$00.00"
                      required
                      readOnly
                    />
                  </td>
                </tr>

                <tr>
                  <td className="border border-default-200">
                    <input
                      type="text"
                      id="itemdescription1"
                      className="bg-transparent block w-full border-0 rounded-md text-sm text-default-500 placeholder:text-default-400 ring-0"
                      placeholder="Enter Description (Optional)"
                      required
                    />
                  </td>

                  <td colSpan={3} className="border border-default-200 "></td>
                </tr>
              </tbody>

              <tbody className="before:block before:h-3 item-list">
                <tr className="item">
                  <td className="border border-default-200">
                    <input
                      type="text"
                      id="itemName1"
                      className="bg-transparent block w-full border-0 rounded-md text-sm text-default-500 placeholder:text-default-400 ring-0"
                      placeholder="Item Name"
                      required
                    />
                  </td>

                  <td className="w-40 border rounded-xl border-default-200 ">
                    <div className="flex p-2 justify-center">
                      <button
                        type="button"
                        className="size-9 minusBtn border rounded-tr-0 rounded-br-0 border-default-200 flex justify-center items-center"
                      >
                        <LuMinus className="size-4 text-default-500" />
                      </button>
                      <input
                        type="number"
                        className="text-center ps-2 w-12 h-9 border-t bg-transparent border-b border-e-0 border-l-0 border-default-200 ring-0 product-quantity focus:shadow-none"
                        value="2"
                        min="0"
                        max="100"
                        readOnly
                      />
                      <button
                        type="button"
                        className="size-9 plusBtn rounded-tl-0 rounded-bl-0 border  border-default-200 flex justify-center items-center"
                      >
                        <LuPlus className="size-4 text-default-500" />
                      </button>
                    </div>
                  </td>

                  <td className="w-40 border border-default-200 ">
                    <input
                      type="number"
                      id="itemName1"
                      className="bg-transparent block w-full border-0 rounded-md text-sm text-default-500 placeholder:text-default-400 ring-0"
                      placeholder="$00.00"
                      required
                    />
                  </td>

                  <td className="w-40 border border-default-200 ">
                    <input
                      type="text"
                      id="itemName1"
                      className="bg-transparent block w-full border-0 rounded-md text-sm text-default-500 placeholder:text-default-400 ring-0"
                      placeholder="0%"
                      required
                    />
                  </td>

                  <td className="w-40 border border-default-200 ">
                    <input
                      type="text"
                      id="itemName1"
                      className="bg-transparent block w-full border-0 rounded-md text-sm text-default-500 placeholder:text-default-400 ring-0"
                      placeholder="0%"
                      required
                    />
                  </td>

                  <td className="border border-default-200 " rowSpan={2}>
                    <div className="mb-1">
                      <input
                        type="text"
                        id="ItemTotal"
                        className="bg-transparent block w-full border-0 rounded-md text-sm text-default-500 placeholder:text-default-400 ring-0"
                        placeholder="$00.00"
                        readOnly
                      />
                    </div>
                    <input
                      type="text"
                      id="itemDiscountsInput"
                      className="bg-transparent block w-full border-0 rounded-md text-sm text-default-500 placeholder:text-default-400 ring-0"
                      placeholder="-$00.00"
                      readOnly
                    />
                  </td>
                </tr>

                <tr>
                  <td className="border border-default-200 ">
                    <input
                      type="text"
                      id="itemdescription1"
                      className="bg-transparent block w-full border-0 rounded-md text-sm text-default-500 placeholder:text-default-400 ring-0"
                      placeholder="Enter Description (Optional)"
                      required
                    />
                  </td>

                  <td colSpan={3} className="border border-default-200 "></td>
                </tr>
              </tbody>

              <tbody className="before:block before:h-4" id="invoiceTable">
                <tr>
                  <td colSpan={6}>
                    <Link to="" id="addBtn">
                      <button className="btn border border-primary w-auto bg-transparent  text-primary border-dashed hover:bg-primary/10">
                        <LuPlus className="size-3 me-2" />
                        Add Item
                      </button>
                    </Link>
                  </td>
                </tr>
              </tbody>

              <tbody className="before:block before:h-3" id="totalAmount">
                <tr className="text-default-800">
                  <td colSpan={4}></td>
                  <td className="border-b border-default-200 text-default-500 text-sm">
                    Sub Total
                  </td>
                  <td className="font-medium border-b border-default-200 ">
                    <input
                      type="text"
                      id="subTotale"
                      className=" bg-transparent block w-full border-0 rounded-md text-sm text-default-800 placeholder:text-default-800 ring-0"
                      placeholder="$00.00"
                      readOnly
                    />
                  </td>
                </tr>

                <tr className="text-default-800">
                  <td colSpan={4}></td>
                  <td className="border-b border-default-200  text-default-600 text-sm">
                    Estimated Tax (18%)
                  </td>
                  <td className="font-medium border-b border-default-200 text-default-600 text-sm">
                    <input
                      type="text"
                      id="subTotale"
                      className=" bg-transparent block w-full border-0 rounded-md text-sm text-default-800 placeholder:text-default-800 ring-0"
                      placeholder="$00.00"
                      readOnly
                    />
                  </td>
                </tr>

                <tr className="text-default-800">
                  <td colSpan={4}></td>
                  <td className="border-b border-default-200 text-default-600 text-sm">
                    Item Discounts
                  </td>
                  <td className="font-medium border-b border-default-200 ">
                    <input
                      type="text"
                      id="subTotale"
                      className=" bg-transparent block w-full border-0 rounded-md text-sm text-default-800 placeholder:text-default-800 ring-0"
                      placeholder="$00.00"
                      readOnly
                    />
                  </td>
                </tr>

                <tr className="text-default-800">
                  <td colSpan={4}></td>
                  <td className="border-b border-default-200  text-default-600 text-sm">
                    Shipping Charge
                  </td>
                  <td className="font-medium border-b border-default-200 ">
                    <input
                      type="text"
                      id="subTotale"
                      className=" bg-transparent block w-full border-0 rounded-md text-sm text-default-800 placeholder:text-default-800 ring-0"
                      placeholder="$00.00"
                      readOnly
                    />
                  </td>
                </tr>

                <tr className="text-default-800">
                  <td colSpan={4}></td>
                  <td className="border-b border-default-200 text-default-600 text-sm">
                    Total Amount
                  </td>
                  <td className="font-medium border-b border-default-200 ">
                    <input
                      type="text"
                      id="subTotale"
                      className=" bg-transparent block w-full border-0 rounded-md text-sm text-default-800 placeholder:text-default-800 ring-0"
                      placeholder="$00.00"
                      readOnly
                    />
                  </td>
                </tr>
              </tbody>
            </table>
          </div>

          <h6 className="mb-4 text-text-default-800 underline text-sm font-semibold">
            Payments Details:
          </h6>

          <div className="grid lg:grid-cols-4 grid-cols-1 gap-5">
            <div className="col-span-1">
              <label
                htmlFor="paymentMethod"
                className="inline-block mb-2 text-sm text-default-800 font-medium"
              >
                Full Name
              </label>
              <select className="form-input" data-kt-select name="paymentMethod" id="paymentMethod">
                <option value="">Select Method</option>
                <option value="Credit Card">Credit Card</option>
                <option value="Paypal">Paypal</option>
                <option value="Paypal">Paypal</option>
                <option value="American Express">American Express</option>
              </select>
            </div>

            <div className="col-span-1">
              <label
                htmlFor="cardHolderName"
                className="inline-block mb-2 text-sm text-default-800 font-medium"
              >
                Card Holder Name
              </label>
              <input
                type="number"
                id="cardHolderName"
                inputMode="numeric"
                pattern="[0-9\s]{13,19}"
                autoComplete="cc-number"
                maxLength={19}
                className="form-input"
                placeholder="Full Name"
                required
              />
            </div>

            <div className="col-span-1">
              <label
                htmlFor="cardNumber"
                className="inline-block mb-2 text-sm text-default-800 font-medium"
              >
                Card Number
              </label>
              <input
                type="text"
                id="cardNumber"
                className="form-input"
                placeholder="xxxx xxxx xxxx xxxx"
                required
              />
            </div>

            <div className="col-span-1">
              <label
                htmlFor="totalPayment"
                className="inline-block mb-2 text-sm text-default-800 font-medium "
              >
                Total Payment
              </label>
              <input
                type="text"
                id="totalPayment"
                className=" form-input"
                placeholder="$00.00"
                required
              />
            </div>

            <div className="lg:col-span-4 col-span-1">
              <label
                htmlFor="taxBillingInput"
                className="inline-block mb-2 text-sm text-default-800 font-medium"
              >
                Notes
              </label>
              <textarea
                className="form-input"
                placeholder="Enter notes pertaining to the customer or payment"
                id="taxBillingInput"
                rows={3}
              ></textarea>
            </div>
          </div>

          <div className="flex justify-end items-center mt-5">
            <div className="flex flex-wrap items-center gap-2">
              <button className="bg-default-200 text-default-500 text-nowrap border-0 btn hover:bg-default-300">
                {' '}
                <LuRefreshCcw className="size-4 me-1" />
                Reset
              </button>
              <button className="text-white border-0 btn text-nowrap bg-primary">
                {' '}
                <LuSave className="size-4 me-1" />
                Save
              </button>
              <button className="bg-teal-600 border-0 text-nowrap text-white btn hover:bg-tral-700">
                {' '}
                <LuDownload className="size-4 me-1" />
                Download
              </button>
            </div>
          </div>
        </div>
      </div>
    </>
  );
};

export default AddNew;
