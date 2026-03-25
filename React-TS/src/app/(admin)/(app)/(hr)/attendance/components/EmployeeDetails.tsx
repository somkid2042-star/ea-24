import user from '@/assets/images/user/user-3.jpg';
import { Link } from 'react-router';

const EmployeeDetails = () => {
  return (
    <div className="col-span-1">
      <div className="mb-5">
        <label htmlFor="deliveryStatusSelect" className="inline-block card-title">
          Select Employee
        </label>
        <select id="typeSelect" name="typeSelect" className="form-input">
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

      <div className="card">
        <div className="card-body">
          <div className="text-center">
            <div className="mx-auto rounded-full size-20 bg-default-100">
              <img src={user} alt="" className="h-20 rounded-full" />
            </div>

            <h6 className="mt-3 mb-1 text-base text-heading font-semibold">
              <Link to="#">Willie Torres</Link>
            </h6>
            <p className="text-default-500">Product Designer</p>
          </div>

          <div className="mt-5 overflow-x-auto">
            <table className="w-full mb-0">
              <tbody>
                <tr>
                  <td className="py-2.5 text-default-500">Employee ID</td>
                  <td className="py-2.5 font-semibold">#TWE1001501</td>
                </tr>

                <tr>
                  <td className="py-2.5 text-default-500">Experience</td>
                  <td className="py-2.5 font-semibold">3 Year</td>
                </tr>

                <tr>
                  <td className="py-2.5 text-default-500">Joining Date</td>
                  <td className="py-2.5 font-semibold">05 Feb, 2020</td>
                </tr>

                <tr>
                  <td className="py-2.5 text-default-500">Total Hours (Years)</td>
                  <td className="py-2.5 font-semibold">953.8 Hrs</td>
                </tr>

                <tr>
                  <td className="py-2.5 text-default-500">Total Hours</td>
                  <td className="py-2.5 font-semibold">218.4 Hrs</td>
                </tr>

                <tr>
                  <td className="py-2.5 text-default-500">Regular Hours</td>
                  <td className="py-2.5 font-semibold">172 Hrs</td>
                </tr>
                <tr>
                  <td className="py-2.5 text-default-500">Overtime</td>
                  <td className="py-2.5 font-semibold">24 Hrs</td>
                </tr>

                <tr>
                  <td className="py-2.5 text-default-500">Holiday</td>
                  <td className="py-2.5 font-semibold">22.40 Hrs</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  );
};

export default EmployeeDetails;
