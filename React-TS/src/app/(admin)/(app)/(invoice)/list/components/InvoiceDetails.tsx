import logosm from '@/assets/images/logo-sm.png';
import { LuEllipsis, LuSave, LuSquarePen, LuTrash2 } from 'react-icons/lu';
import { Link } from 'react-router';

const InvoiceDetails = () => {
  return (
    <div className="lg:col-span-3 col-span-1">
      <div className="card">
        <div className="card-body">
          <div className="flex flex-wrap justify-between items-center md:gap-0 gap-4">
            <div>
              <h6 className="mb-1 text-base font-semibold text-default-800">#TW15090257</h6>
              <ul className="flex items-center gap-3 text-default-500 text-sm">
                <li>Create: 10 July, 2023</li>
                <li>Due: 10 July, 2023</li>
              </ul>
            </div>

            <div className="flex gap-2">
              <button className="btn bg-primary text-white" onClick={() => window.print()}>
                <LuSave className="size-4 text-white me-1" /> Save & Draft
              </button>

              <div className="hs-dropdown relative inline-flex">
                <button
                  type="button"
                  className="hs-dropdown-toggle btn size-9.5 bg-default-100 hover:bg-default-600 text-default-500 hover:text-white"
                  aria-haspopup="menu"
                  aria-expanded="false"
                  aria-label="Dropdown"
                  hs-dropdown-placement="bottom-end"
                >
                  <LuEllipsis className="size-4" />
                </button>
                <div className="hs-dropdown-menu" role="menu">
                  <div>
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
            </div>
          </div>
        </div>

        <div>
          <div className="card-body">
            <div className="grid lg:grid-cols-12 items-center gap-4">
              <div className="lg:col-span-3 text-start">
                <div className="size-16 bg-default-100 flex items-center justify-center rounded-md">
                  <img src={logosm} alt="" className="h-8" width={32} />
                </div>
                <h5 className="mt-4 mb-1 text-lg font-semibold text-default-800">Themesdesign</h5>
                <p className="text-default-500">IT Software Company</p>
              </div>

              <div className="lg:col-span-9 lg:col-start-12 lg:text-end text-start text-sm">
                <p className="mb-1 text-default-500">
                  Legal Registration No: <span className="font-semibold">2155420</span>
                </p>
                <p className="mb-1 truncate text-default-500">
                  Email: <span className="font-semibold">tailwick@themesdesign.in</span>
                </p>
                <p className="mb-1 text-default-500">
                  Website:{' '}
                  <Link
                    to="https://themesdesign.in"
                    target="_blank"
                    className="font-semibold underline text-primary"
                  >
                    www.themesdesign.in
                  </Link>
                </p>
                <p className="text-default-500">
                  Contact No: <span className="font-semibold">+(01) 123 678 9654</span>
                </p>
              </div>
            </div>

            <div className="grid md:grid-cols-4 grid-cols-1 mt-6 text-center md:divide-x divide-dashed divide-default-200">
              <div className="p-3 text-sm">
                <h6 className="mb-1 font-semibold text-default-800">#TW15090254</h6>
                <p className="text-default-500">Invoice No</p>
              </div>

              <div className="p-3 text-sm">
                <h6 className="mb-1 font-semibold text-default-800">10 July, 2023</h6>
                <p className="text-default-500">Create Date</p>
              </div>

              <div className="p-3 test-sm">
                <span className="inline-flex items-center gap-x-1.5 py-0.5 px-2.5 rounded text-xs font-medium bg-success/10 text-success ">
                  Paid
                </span>
                <p className="text-default-500">Payment Status</p>
              </div>

              <div className="p-3 text-sm">
                <h6 className="mb-1 font-semibold text-default-800">$873.96</h6>
                <p className="text-default-500">Total Amount</p>
              </div>
            </div>

            <div className="grid md:grid-cols-2 grid-cols-1 gap-5 mt-8">
              <div className="text-default-500">
                <p className="mb-2 text-sm uppercase">Shipping Address</p>
                <h6 className="mb-1 text-base font-semibold text-default-800">Paula Keenan</h6>
                <p className="mb-1 text-sm">176 Arvid Crest Sheastad, IA</p>
                <p className="mb-1 text-sm">+(211) 0123 456 897</p>
              </div>

              <div className="text-default-500">
                <p className="mb-2 text-sm uppercase ">Billing Address</p>
                <h6 className="mb-1 text-base font-semibold text-default-800">Paula Keenan</h6>
                <p className="mb-1 text-sm">176 Arvid Crest Sheastad, IA</p>
                <p className="mb-1 text-sm">+(211) 0123 456 897</p>
                <p className="mb-1 text-sm">TAX No. 5415421</p>
              </div>
            </div>

            <div className="mt-8 overflow-x-auto">
              <table className="w-full whitespace-nowrap">
                <thead>
                  <tr className="font-semibold border-b border-default-200 text-default-500 text-sm">
                    <th className="px-3.5 py-2.5 text-start">#</th>
                    <th className="px-3.5 py-2.5 text-start">Item Name</th>
                    <th className="px-3.5 py-2.5 text-start">Rate</th>
                    <th className="px-3.5 py-2.5 text-start">Quantity</th>
                    <th className="px-3.5 py-2.5 text-start">Amount</th>
                  </tr>
                </thead>

                <tbody>
                  <tr className="border-b border-default-200 text-default-800 text-sm">
                    <td className="px-3.5 py-2.5">1</td>
                    <td className="px-3.5 py-2.5">
                      <h6 className="mb-1 font-medium">Webadmin - Premium Admin & Dashboard</h6>
                      <p className="text-default-500">
                        Build with Bootstrap, React JS, Angular, Vue etc.
                      </p>
                    </td>
                    <td className="px-3.5 py-2.5">$24.00</td>
                    <td className="px-3.5 py-2.5">2</td>
                    <td className="px-3.5 py-2.5">$48</td>
                  </tr>

                  <tr className="border-b border-default-200 text-default-800 text-sm">
                    <td className="px-3.5 py-2.5">2</td>
                    <td className="px-3.5 py-2.5">
                      <h6 className="mb-1 font-medium">Webadmin - Admin & Dashboard</h6>
                      <p className="text-default-500">
                        Build with Bootstrap, React JS, Angular, Vue etc.
                      </p>
                    </td>
                    <td className="px-3.5 py-2.5">$25.00</td>
                    <td className="px-3.5 py-2.5">4</td>
                    <td className="px-3.5 py-2.5">$100</td>
                  </tr>

                  <tr className="border-b border-default-200 text-default-800 text-sm">
                    <td className="px-3.5 py-2.5">1</td>
                    <td className="px-3.5 py-2.5">
                      <h6 className="mb-1 font-medium">Tocly - Admin & Dashboard</h6>
                      <p className="text-default-500">
                        Build with Bootstrap, React JS, Angular, Vue etc.
                      </p>
                    </td>
                    <td className="px-3.5 py-2.5">$16.00</td>
                    <td className="px-3.5 py-2.5">9</td>
                    <td className="px-3.5 py-2.5">$144</td>
                  </tr>
                </tbody>

                <tbody>
                  <tr className="text-default-500 text-sm">
                    <td colSpan={3}></td>
                    <td className="border-b border-default-200 px-3.5 py-2.5">Sub Total</td>
                    <td className="border-b border-default-200 px-3.5 py-2.5">$292</td>
                  </tr>

                  <tr className="text-default-500 text-sm">
                    <td colSpan={3}></td>
                    <td className="border-b border-default-200 px-3.5 py-2.5">
                      Estimated Tax (18%)
                    </td>
                    <td className="border-b border-default-200 px-3.5 py-2.5">$52.56</td>
                  </tr>

                  <tr className="text-default-500 text-sm">
                    <td colSpan={3}></td>
                    <td className="border-b border-default-200 px-3.5 py-2.5">
                      Item Discounts (15%)
                    </td>
                    <td className="border-b border-default-200 px-3.5 py-2.5">-$43.8</td>
                  </tr>

                  <tr className="text-default-500 text-sm">
                    <td colSpan={3}></td>
                    <td className="border-b border-default-200 px-3.5 py-2.5">Shipping Charge</td>
                    <td className="border-b border-default-200 px-3.5 py-2.5">$29</td>
                  </tr>

                  <tr>
                    <td colSpan={3}></td>
                    <td className="border-b border-default-200 px-3.5 py-2.5 font-medium text-sm">
                      Total Amount
                    </td>
                    <td className="border-b border-default-200 px-3.5 py-2.5 font-medium text-sm">
                      $329.76
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>

            <div className="my-5 text-default-500 text-sm">
              <p className="mb-2 text-sm uppercase">Payments Details</p>
              <p className="mb-1">Payment Method: Credit Card</p>
              <p className="mb-1">Card Holder: Paula Keenan</p>
              <p className="mb-1">Card Number: xxxx xxxx xxxx 1402</p>
              <p>Total Amount: $755.96</p>
            </div>

            <p className="px-4 py-3 text-sm rounded-lg border border-info/20 text-info bg-info/10">
              <b>NOTES:</b> All accounts are to be paid within 7 days from receipt of invoice. To be
              paid by cheque or credit card or direct payment online. If account is not paid within
              7 days the credits details supplied as confirmation of work undertaken will be charged
              the agreed quoted fee noted above.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default InvoiceDetails;
