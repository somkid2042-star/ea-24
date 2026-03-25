import { Link } from 'react-router';

const Activities = () => {
  return (
    <div className="grid lg:grid-cols-4 grid-cols-1 mb-5 gap-5">
      <div className="lg:col-span-2">
        <h5 className="mb-2 text-xl text-default-800 font-semibold">Welcome Paula Keenan 🎉</h5>
        <p>
          The salary of
          <Link to="#" className="underline text-default-900">
            Glennie Langosh
          </Link>
          is pending since 05 Dec, 2023. the documentation of the tasks, workflows, and activities
          that make up a process managed by the HR or People Ops team.
          <Link to="#" className="text-danger">
            Learn More
          </Link>
        </p>
      </div>

      <div className="lg:col-start-4">
        <div className="card">
          <div className="card-body">
            <div className="grid grid-cols-3">
              <div className="px-4 text-center border-e border-default-200 text-sm">
                <h6 className="mb-1 font-bold">
                  <span className="counter-value text-default-800" data-target="36">
                    36
                  </span>
                </h6>
                <p className="text-default-500">Absent</p>
              </div>

              <div className="px-4 text-center border-e border-default-200 text-sm">
                <h6 className="mb-1 font-bold">
                  <span className="counter-value text-default-800" data-target="465">
                    465
                  </span>
                </h6>
                <p className="text-default-500">Attendance</p>
              </div>

              <div className="px-4 text-center text-sm">
                <h6 className="mb-1 font-bold">
                  <span className="counter-value text-default-800" data-target="50">
                    50
                  </span>
                </h6>
                <p className="text-default-500">Late</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Activities;
