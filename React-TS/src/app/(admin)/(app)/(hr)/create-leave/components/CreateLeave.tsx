import Flatpickr from 'react-flatpickr';

const CreateLeave = () => {
  return (
    <div className="grid lg:grid-cols-4 grid-cols-1 gap-5">
      <div className="lg:col-span-3 col-span-1">
        <div className="card">
          <div className="card-header">
            <h6 className="card-title">Add Leave</h6>
          </div>

          <div className="card-body">
            <div className="grid md:grid-cols-2 grid-cols-1 gap-5 mb-5">
              <div>
                <label
                  htmlFor="employeeName"
                  className="inline-block mb-2 text-sm text-default-800 font-medium"
                >
                  Employee
                </label>
                <select className="form-input">
                  <option value="">Select Employee</option>
                  <option value="Willie Torres">Willie Torres</option>
                  <option value="Patricia Garcia">Patricia Garcia</option>
                  <option value="Juliette Fecteau">Juliette Fecteau</option>
                  <option value="Thomas Hatfield">Thomas Hatfield</option>
                  <option value="Willie Torres">Willie Torres</option>
                  <option value="Juliette Fecteau">Juliette Fecteau</option>
                  <option value="Nancy Reynolds">Nancy Reynolds</option>
                  <option value="Holly Kavanaugh">Holly Kavanaugh</option>
                  <option value="Jonas Frederiksen">Jonas Frederiksen</option>
                </select>
              </div>

              <div>
                <label
                  htmlFor="employeeId"
                  className="inline-block mb-2 text-sm text-default-800 font-medium"
                >
                  Employee ID
                </label>
                <input
                  type="text"
                  id="employeeId"
                  className="form-input"
                  value="#TWE1001501"
                  disabled
                />
              </div>

              <div>
                <label
                  htmlFor="employeeName"
                  className="inline-block mb-2 text-sm text-default-800 font-medium"
                >
                  Leave Type
                </label>
                <select className="form-input">
                  <option value="">Select Leave Type</option>
                  <option value="Medical Leave">Medical Leave</option>
                  <option value="Casual Leave">Casual Leave</option>
                  <option value="Sick Leave">Sick Leave</option>
                  <option value="Annual Leave">Annual Leave</option>
                </select>
              </div>

              <div>
                <label
                  htmlFor="remainingLeaves"
                  className="inline-block mb-2 text-sm text-default-800 font-medium"
                >
                  Remaining Leaves
                </label>
                <input
                  type="text"
                  id="remainingLeaves"
                  className="form-input"
                  value="18"
                  disabled
                />
              </div>

              <div>
                <label
                  htmlFor="fromInput"
                  className="inline-block mb-2 text-sm text-default-800 font-medium"
                >
                  Form
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

              <div>
                <label
                  htmlFor="toInput"
                  className="inline-block mb-2 text-sm text-default-800 font-medium"
                >
                  To
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

              <div>
                <label
                  htmlFor="numberOfDayLeaves"
                  className="inline-block mb-2 text-sm text-default-800 font-medium"
                >
                  Number of Days
                </label>
                <input
                  type="text"
                  id="numberOfDayLeaves"
                  className="form-input"
                  value="01"
                  disabled
                />
              </div>

              <div>
                <label
                  htmlFor=""
                  className="inline-block mb-2 text-sm text-default-800 font-medium"
                >
                  Leave Day
                </label>
                <select className="form-input">
                  <option value="">Select Leave Day</option>
                  <option value="Full Day">Full Day</option>
                  <option value="Half Day">Half Day</option>
                </select>
              </div>
            </div>

            <div className="grid grid-cols-1 gap-5">
              <div>
                <label
                  htmlFor="reasonInput"
                  className="inline-block mb-2 text-sm text-default-800 font-medium"
                >
                  Reason
                </label>
                <textarea className="form-input" id="reasonInput" rows={3}></textarea>
              </div>
            </div>

            <div className="flex justify-end gap-2 mt-5">
              <button className="btn border-0 text-danger bg-transparent hover:bg-danger/10">
                Reset
              </button>
              <button className="btn bg-primary text-white">Apply Leave</button>
            </div>
          </div>
        </div>
      </div>

      <div className="col-span-1">
        <div className="card">
          <div className="card-header">
            <h6 className="card-title">Leave Information (2023)</h6>
          </div>
          <div className="card-body">
            <table className="w-full mb-0 text-sm">
              <tbody>
                <tr>
                  <td className="py-2.5 text-default-800">Medical Leave</td>
                  <th className="py-2.5 text-default-800 font-semibold">04</th>
                </tr>

                <tr>
                  <td className="py-2.5 text-default-800">Casual Leave</td>
                  <th className="py-2.5 text-default-800 font-semibold">08</th>
                </tr>

                <tr>
                  <td className="py-2.5 text-default-800">Sick Leave</td>
                  <th className="py-2.5 text-default-800 font-semibold">03</th>
                </tr>

                <tr>
                  <td className="py-2.5 text-default-800">Annual Leave</td>
                  <th className="py-2.5 text-default-800 font-semibold">12</th>
                </tr>

                <tr>
                  <td className="py-2.5 text-default-800">Use Leave</td>
                  <th className="py-2.5 text-default-800 font-semibold">09</th>
                </tr>

                <tr>
                  <td className="py-2.5 text-default-800">Remaining Leave</td>
                  <th className="py-2.5 text-default-800 font-semibold">18</th>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  );
};

export default CreateLeave;
