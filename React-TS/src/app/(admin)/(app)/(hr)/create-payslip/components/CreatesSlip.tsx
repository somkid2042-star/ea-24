import logosm from '@/assets/images/logo-sm.png';
import signature from '@/assets/images/signature.png';
import Flatpickr from 'react-flatpickr';
import { LuPlus } from 'react-icons/lu';

const CreatesSlip = () => {
  return (
    <div className="lg:w-5xl w-full mx-auto">
      <div className="card relative">
        <div className="card-body">
          <div className="absolute top-0 end-0 opacity-30">
            <img src={logosm} alt="" />
          </div>
          <div className="text-center">
            <h5 className="inline-block relative text-lg text-default-800 font-semibold">
              Salary Slip
              <span className="absolute start-0 end-0 -bottom-2 h-0.25 bg-gradient-to-r from-white via-primary to-white"></span>
            </h5>
          </div>

          <div className="mt-16 lg:max-w-md w-full">
            <div className="mb-4">
              <label
                htmlFor="employeeID"
                className="inline-block mb-2 text-sm text-default-800 font-medium"
              >
                Employee ID
              </label>
              <input
                type="text"
                id="employeeID"
                className="form-input bg-default-100"
                value="#TWE1001524"
                disabled
              />
            </div>

            <div className="mb-4">
              <label
                htmlFor="employeeSelect"
                className="inline-block mb-2 text-sm text-default-800 font-medium"
              >
                Employee Name
              </label>
              <select className="form-input">
                <option value="">Select Employee</option>
                <option value="Willie Torres">Willie Torres</option>
                <option value="Patricia Garcia">Patricia Garcia</option>
                <option value="Juliette Fecteau">Juliette Fecteau</option>
                <option value="Thomas Hatfield">Thomas Hatfield</option>
                <option value="Juliette Fecteau">Juliette Fecteau</option>
                <option value="Nancy Reynolds">Nancy Reynolds</option>
                <option value="Holly Kavanaugh">Holly Kavanaugh</option>
                <option value="Jonas Frederiksen">Jonas Frederiksen</option>
              </select>
            </div>

            <div className="mb-4">
              <label
                htmlFor="ExperienceInput"
                className="inline-block mb-2 text-sm text-default-800 font-medium"
              >
                Experience
              </label>
              <input
                type="text"
                id="ExperienceInput"
                className="form-input"
                placeholder="0.4 year"
              />
            </div>

            <div className="mb-4">
              <label
                htmlFor="createDateInput"
                className="inline-block mb-2 text-sm text-default-800 font-medium"
              >
                Create Date
              </label>
              <Flatpickr
                options={{
                  mode: 'single',
                  dateFormat: 'Y-m-d',
                }}
                className="form-input"
                placeholder="Select Date"
              />
            </div>
          </div>

          <div className="mt-10 overflow-x-auto">
            <table className="w-full whitespace-nowrap">
              <thead className="bg-default-100 text-sm text-default-800">
                <tr>
                  <th className="px-3.5 py-2.5 font-semibold">Month</th>
                  <th className="px-3.5 py-2.5 font-semibold">Salary Amount</th>
                  <th className="px-3.5 py-2.5 font-semibold">Deductions(TDS)</th>
                  <th className="px-3.5 py-2.5 font-semibold">Professional Tax</th>
                  <th className="px-3.5 py-2.5 font-semibold">Provident Fund</th>
                  <th className="px-3.5 py-2.5 font-semibold">Net Payable</th>
                </tr>
              </thead>

              <tbody>
                <tr>
                  <td className="px-3.5 py-2.5">
                    <Flatpickr
                      options={{
                        mode: 'single',
                        dateFormat: 'Y-m-d',
                      }}
                      className="form-input"
                      placeholder="Select Date"
                    />
                  </td>

                  <td className="px-3.5 py-2.5">
                    <input type="number" className="form-input" placeholder="$00.00" />
                  </td>

                  <td className="px-3.5 py-2.5">
                    <input type="number" className="form-input" placeholder="$00.00" />
                  </td>

                  <td className="px-3.5 py-2.5">
                    <input type="number" className="form-input" placeholder="$00.00" />
                  </td>

                  <td className="px-3.5 py-2.5">
                    <input type="number" className="form-input" placeholder="$00.00" />
                  </td>

                  <td className="px-3.5 py-2.5">
                    <input type="number" className="form-input" placeholder="$00.00" />
                  </td>
                </tr>
              </tbody>

              <tbody className="before:block before:h-4">
                <tr>
                  <td colSpan={6}>
                    <button
                      type="button"
                      className="btn bg-transparent border border-dashed border-primary text-primary hover:bg-primary/10"
                    >
                      <LuPlus className="size-3 me-1" />
                      Add Item
                    </button>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>

          <div className="grid lg:grid-cols-2 grid-cols-1 mt-10 gap-5">
            <div className="text-sm">
              <p className="mb-2 text-default-500">
                For any inquiries, please contact us at +(252) 0123 456 7890 or reach out via email
                at tailwick@themesdesign.in.
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
  );
};

export default CreatesSlip;
