import img from '@/assets/images/user/user-dummy-img.jpg';
import { LuImagePlus, LuX } from 'react-icons/lu';

const EditEmployeeData = () => {
  return (
    <div
      id="employeeEdit"
      className="hs-overlay hidden size-full fixed top-0 start-0 z-80 overflow-x-hidden overflow-y-auto pointer-events-none"
      role="dialog"
      tabIndex={-1}
      aria-labelledby="employeeEditlabel"
    >
      <div className="hs-overlay-animation-target hs-overlay-open:scale-100 hs-overlay-open:opacity-100 scale-95 opacity-0 ease-in-out transition-all duration-200 max-w-md lg:w-full m-3 mx-auto min-h-[calc(100%-56px)] flex items-center">
        <div className="w-full flex flex-col card border border-default-200 shadow-2xs rounded-xl pointer-events-auto">
          <div className="card-header">
            <h3 id="employeeEditlabel" className="font-semibold text-base text-default-800">
              Edit Employee Data
            </h3>

            <button type="button" aria-label="Close" data-hs-overlay="#employeeEdit">
              <span className="sr-only">Close</span>
              <LuX className="size-5" />
            </button>
          </div>

          <div className="card-body overflow-y-auto lg:h-full h-160">
            <div className="grid grid-cols-1 gap-6 lg:grid-cols-12">
              <div className="lg:col-span-12 flex justify-center">
                <div className="relative mx-auto mb-4 rounded-full shadow-md size-24 bg-default-200">
                  <img
                    src={img}
                    alt="Profile"
                    className="object-cover w-full h-full rounded-full user-profile-image"
                  />

                  <div className="absolute bottom-0 right-0 flex items-center justify-center rounded-full size-8 bg-default-50 shadow-lg cursor-pointer">
                    <input
                      id="profile-img-file-input"
                      name="profile-img-file-input"
                      type="file"
                      className="hidden"
                    />
                    <label
                      htmlFor="profile-img-file-input"
                      className="flex items-center justify-center w-full h-full rounded-full cursor-pointer"
                    >
                      <LuImagePlus className="size-4 text-default-400" />
                    </label>
                  </div>
                </div>
              </div>

              <div className="lg:col-span-12">
                <label
                  htmlFor="employeeId"
                  className="block mb-2 text-sm font-medium text-default-700"
                >
                  Employee ID
                </label>
                <input
                  type="text"
                  id="employeeId"
                  defaultValue="#TWE1001528"
                  className="form-input"
                  disabled
                />
              </div>

              <div className="lg:col-span-12">
                <label
                  htmlFor="employeeInput"
                  className="block mb-2 text-sm font-medium text-default-700"
                >
                  Name
                </label>
                <input
                  type="text"
                  id="employeeInput"
                  placeholder="Employee name"
                  defaultValue="Willie Torres"
                  className="form-input"
                />
              </div>

              <div className="lg:col-span-12">
                <label
                  htmlFor="emailInput"
                  className="block mb-2 text-sm font-medium text-default-700"
                >
                  Email
                </label>
                <input
                  type="email"
                  id="emailInput"
                  placeholder="example@tailwick.com"
                  defaultValue="willie@tailwick.com"
                  className="form-input"
                />
              </div>

              <div className="lg:col-span-6">
                <label
                  htmlFor="phoneNumberInput"
                  className="block mb-2 text-sm font-medium text-default-700"
                >
                  Phone Number
                </label>
                <input
                  type="text"
                  id="phoneNumberInput"
                  placeholder="Enter phone number"
                  defaultValue="070 3715 3689"
                  className="form-input"
                />
              </div>

              <div className="lg:col-span-6">
                <label
                  htmlFor="locationInput"
                  className="block mb-2 text-sm font-medium text-default-700"
                >
                  Location
                </label>
                <input
                  type="text"
                  id="locationInput"
                  placeholder="Enter location"
                  className="form-input"
                />
              </div>

              <div className="lg:col-span-6">
                <label
                  htmlFor="joiningDateInput"
                  className="block mb-2 text-sm font-medium text-default-700"
                >
                  Joining Date
                </label>
                <input
                  type="date"
                  id="joiningDateInput"
                  defaultValue="05 Feb, 2020"
                  className="form-input"
                />
              </div>

              <div className="lg:col-span-6">
                <label
                  htmlFor="experienceInput"
                  className="block mb-2 text-sm font-medium text-default-700"
                >
                  Experience
                </label>
                <input type="text" id="experienceInput" placeholder="0.0" className="form-input" />
              </div>

              <div className="lg:col-span-12">
                <label
                  htmlFor="designationSelect"
                  className="block mb-2 text-sm font-medium text-default-700"
                >
                  Designation
                </label>
                <select id="designationSelect" className="form-input">
                  <option defaultValue="">Angular Developer</option>
                  <option>ASP.Net Developer</option>
                  <option>NodeJS Developer</option>
                  <option>Project Manager</option>
                  <option>React Developer</option>
                  <option>Team Leader</option>
                  <option>UI / UX Designer</option>
                  <option>VueJs Developer</option>
                  <option>Web Designer</option>
                </select>
              </div>
            </div>
          </div>

          <div className="card-footer flex justify-end gap-2">
            <button
              type="button"
              className="btn bg-transparent border-0  text-danger hover:bg-danger/10"
              data-hs-overlay="#employeeEdit"
            >
              Cancel
            </button>

            <button type="button" className="btn bg-primary text-white">
              Update
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default EditEmployeeData;
