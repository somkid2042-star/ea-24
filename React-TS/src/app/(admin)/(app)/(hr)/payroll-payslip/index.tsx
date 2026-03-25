import signature from '@/assets/images/signature.png';
import PageBreadcrumb from '@/components/PageBreadcrumb';
import PageMeta from '@/components/PageMeta';
const Index = () => {
  return (
    <>
      <PageMeta title="Payslip" />
      <main>
        <PageBreadcrumb title="Payslip" subtitle="Menu" />
        <div className="lg:w-5xl w-full mx-auto">
          <div className="card relative">
            <div className="card-body">
              <div className="absolute top-0 end-0 opacity-30">
                {/* <img src={downloadImg} alt="" /> */}
              </div>

              <div className="text-center">
                <h5 className="inline-block relative text-lg text-default-800 font-semibold">
                  Salary Slip
                  <span className="absolute start-0 end-0 -bottom-2 h-0.25 bg-gradient-to-r from-white via-primary to-white"></span>
                </h5>
              </div>

              <div className="mt-16 text-sm">
                <p className="mb-2 text-default-500">
                  Employee ID: <span className="font-semibold text-default-800">#TWE1001524</span>
                </p>
                <p className="mb-2 text-default-500">
                  Employee Name:{' '}
                  <span className="font-semibold text-default-800">Patricia Garcia</span>
                </p>
                <p className="mb-2 text-default-500">
                  Experience: <span className="font-semibold text-default-800">2 Year</span>
                </p>
                <p className="text-default-500">
                  Create Date: <span className="font-semibold text-default-800">08 Oct 2023</span>
                </p>
              </div>

              <div className="flex flex-col mt-10">
                <div className="overflow-x-auto">
                  <div className="min-w-full inline-block align-middle">
                    <div className="overflow-hidden">
                      <table className="min-w-full  divide-y divide-default-200">
                        <thead className="bg-default-150">
                          <tr className="text-sm font-normal text-default-800 whitespace-nowrap">
                            <th scope="col" className="px-3.5 py-2.5 text-start">
                              Month
                            </th>
                            <th scope="col" className="px-3.5 py-2.5 text-start">
                              Salary Amount
                            </th>
                            <th scope="col" className="px-3.5 py-2.5 text-start">
                              Deductions(TDS)
                            </th>
                            <th scope="col" className="px-3.5 py-2.5 text-start">
                              Professional Tax
                            </th>
                            <th scope="col" className="px-3.5 py-2.5 text-start">
                              Provident Fund
                            </th>
                            <th scope="col" className="px-3.5 py-2.5 text-start">
                              Net Payable
                            </th>
                            <th scope="col" className="px-3.5 py-2.5 text-start">
                              Status
                            </th>
                          </tr>
                        </thead>

                        <tbody className="divide-y divide-default-200">
                          <tr className="text-default-800 font-normal">
                            <td className="px-3.5 py-2.5 whitespace-nowrap text-sm">Oct, 2023</td>
                            <td className="px-3.5 py-2.5 whitespace-nowrap text-sm">$25,000</td>
                            <td className="px-3.5 py-2.5 whitespace-nowrap text-sm"> $800 </td>
                            <td className="px-3.5 py-2.5 whitespace-nowrap text-sm">$150 </td>
                            <td className="px-3.5 py-2.5 whitespace-nowrap text-sm "> $500</td>
                            <td className="px-3.5 py-2.5 whitespace-nowrap text-sm">$23,550 </td>
                            <td className="px-3.5 py-2.5 whitespace-nowrap">
                              <span className="inline-flex items-center gap-x-1.5 py-0.5 px-2.5 rounded text-xs font-medium bg-success/10 text-success border border-success/20">
                                Paid
                              </span>
                            </td>
                          </tr>

                          <tr className="text-default-800 font-normal">
                            <td className="px-4 py-3 whitespace-nowrap text-sm">Nov, 2023</td>
                            <td className="px-4 py-3 whitespace-nowrap text-sm">$25,000</td>
                            <td className="px-4 py-3 whitespace-nowrap text-sm">$800</td>
                            <td className="px-4 py-3 whitespace-nowrap text-sm">$150</td>
                            <td className="px-4 py-3 whitespace-nowrap text-sm">$500</td>
                            <td className="px-4 py-3 whitespace-nowrap text-sm">$23,550</td>
                            <td className="px-4 py-3 whitespace-nowrap">
                              <span className="inline-flex items-center gap-x-1.5 py-0.5 px-2.5 rounded text-xs font-medium bg-success/10 text-success border border-success/20">
                                Paid
                              </span>
                            </td>
                          </tr>

                          <tr className="text-default-800 font-normal">
                            <td className="px-4 py-3 whitespace-nowrap text-sm">Dec, 2023</td>
                            <td className="px-4 py-3 whitespace-nowrap text-sm">$25,000</td>
                            <td className="px-4 py-3 whitespace-nowrap text-sm">$800</td>
                            <td className="px-4 py-3 whitespace-nowrap text-sm">$150</td>
                            <td className="px-4 py-3 whitespace-nowrap text-sm">$500</td>
                            <td className="px-4 py-3 whitespace-nowrap text-sm">$23,550</td>
                            <td className="px-4 py-3 whitespace-nowrap">
                              <span className="inline-flex items-center gap-x-1.5 py-0.5 px-2.5 rounded text-xs font-medium bg-success/10 text-success border border-success/20">
                                Paid
                              </span>
                            </td>
                          </tr>
                        </tbody>
                      </table>
                    </div>
                  </div>
                </div>
              </div>

              <div className="grid lg:grid-cols-2 grid-cols-1 mt-10 gap-5">
                <div className="text-sm">
                  <p className="mb-2 text-default-500">
                    For any inquiries, please contact us at +(252) 0123 456 7890 or reach out via
                    email at tailwick@themesdesign.in.
                  </p>
                  <p className="mb-2 text-default-500">Best Regards,</p>
                  <p className="mb-2 text-default-500">Themesdesign</p>
                  <p className="text-default-500">
                    Founder &amp; CEO:{' '}
                    <span className="font-semibold text-default-800">Paula Keenan</span>
                  </p>
                </div>

                <div className="flex flex-col lg:justify-end text-center lg:items-end items-center">
                  <img src={signature} alt="" className="h-12" />
                  <h6 className="text-default-800 font-semibold text-sm">Authorized Sign</h6>
                </div>
              </div>
            </div>
          </div>
        </div>
      </main>
    </>
  );
};

export default Index;
