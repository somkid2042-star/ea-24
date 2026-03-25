import { useState } from 'react';
import Flatpickr from 'react-flatpickr';
import { LuCheck, LuChevronLeft, LuChevronRight, LuSearch, LuX } from 'react-icons/lu';
type WorkRecord = {
  date: string;
  day: string;
  checkIn: string;
  checkOut: string;
  mealBreak: string;
  workHours: string;
  overtime: string;
};

const EmployeeWork = () => {
  const [records] = useState<WorkRecord[]>([
    {
      date: '13 Oct, 2023',
      day: 'Fri',
      checkIn: '08:23 AM',
      checkOut: '07:00 PM',
      mealBreak: '1.00 Hrs',
      workHours: '8.00 Hrs',
      overtime: '0.00 Hrs',
    },
    {
      date: '12 Oct, 2023',
      day: 'Thu',
      checkIn: '08:28 AM',
      checkOut: '05:46 PM',
      mealBreak: '0.45 Hrs',
      workHours: '8.00 Hrs',
      overtime: '0.15 Hrs',
    },
    {
      date: '11 Oct, 2023',
      day: 'Wed',
      checkIn: '09:00 AM',
      checkOut: '06:00 PM',
      mealBreak: '0.50 Hrs',
      workHours: '8.00 Hrs',
      overtime: '0.35 Hrs',
    },
    {
      date: '10 Oct, 2023',
      day: 'Tue',
      checkIn: '09:15 AM',
      checkOut: '05:00 PM',
      mealBreak: '0.35 Hrs',
      workHours: '7.55 Hrs',
      overtime: '0.15 Hrs',
    },
    {
      date: '09 Oct, 2023',
      day: 'Mon',
      checkIn: '08:28 AM',
      checkOut: '05:46 PM',
      mealBreak: '0.45 Hrs',
      workHours: '8.00 Hrs',
      overtime: '0.15 Hrs',
    },
    {
      date: '06 Oct, 2023',
      day: 'Fri',
      checkIn: '09:00 AM',
      checkOut: '06:00 PM',
      mealBreak: '0.50 Hrs',
      workHours: '8.00 Hrs',
      overtime: '0.35 Hrs',
    },
    {
      date: '05 Oct, 2023',
      day: 'Thu',
      checkIn: '08:28 AM',
      checkOut: '05:46 PM',
      mealBreak: '0.45 Hrs',
      workHours: '8.00 Hrs',
      overtime: '0.15 Hrs',
    },
    {
      date: '04 Oct, 2023',
      day: 'Wed',
      checkIn: '08:28 AM',
      checkOut: '05:46 PM',
      mealBreak: '0.45 Hrs',
      workHours: '8.00 Hrs',
      overtime: '0.15 Hrs',
    },
    {
      date: '03 Oct, 2023',
      day: 'Tue',
      checkIn: '08:23 AM',
      checkOut: '07:00 PM',
      mealBreak: '1.00 Hrs',
      workHours: '8.00 Hrs',
      overtime: '0.00 Hrs',
    },
    {
      date: '02 Oct, 2023',
      day: 'Mon',
      checkIn: '09:15 AM',
      checkOut: '05:00 PM',
      mealBreak: '0.35 Hrs',
      workHours: '7.55 Hrs',
      overtime: '0.15 Hrs',
    },
  ]);

  return (
    <div className="card">
      <div className="card-header">
        <div className="flex gap-3 items-center">
          <div className="relative">
            <input
              type="email"
              className="ps-11 form-input form-input-sm"
              placeholder="Search for...."
            />
            <div className="absolute inset-y-0 start-0 flex items-center pointer-events-none ps-4">
              <LuSearch className="size-3.5 flex items-center text-default-500" />
            </div>
          </div>

          <Flatpickr
            options={{
              mode: 'range',
              dateFormat: 'd M, Y',
            }}
            className="form-input form-input-sm"
            placeholder="Select Date"
          />
        </div>

        <div className="flex gap-3 items-center">
          <button
            type="button"
            className="border btn btn-sm border-dashed border-danger text-danger bg-transparent ease-linear hover:bg-red-50"
          >
            Reject All
          </button>

          <button type="button" className="btn btn-sm bg-primary text-white">
            Approve All
          </button>
        </div>
      </div>

      <div className="flex flex-col">
        <div className="overflow-x-auto">
          <div className="min-w-full inline-block align-middle">
            <div className="overflow-hidden">
              <table className="min-w-full divide-y divide-default-200">
                <thead className="bg-default-100 font-normal whitespace-nowrap">
                  <tr className="text-sm text-default-800">
                    <th className="px-3.5 py-3 font-medium text-start">Date</th>
                    <th className="px-3.5 py-3 font-medium text-start">Check In</th>
                    <th className="px-3.5 py-3 font-medium text-start">Check Out</th>
                    <th className="px-3.5 py-3 font-medium text-start">Meal Break</th>
                    <th className="px-3.5 py-3 font-medium text-start">Work Hours</th>
                    <th className="px-3.5 py-3 font-medium text-start">Overtime</th>
                    <th className="px-3.5 py-3 font-medium text-start">Action</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-default-200">
                  {records.map((record, index) => (
                    <tr key={index} className="text-default-800 font-normal whitespace-nowrap">
                      <td className="px-3.5 py-3 text-sm">
                        {record.date}
                        <span className="py-0.5 px-2.5 border border-default-200 text-default-600 rounded ms-2">
                          {record.day}
                        </span>
                      </td>
                      <td className="px-3.5 py-3 text-sm">{record.checkIn}</td>
                      <td className="px-3.5 py-3 text-sm">{record.checkOut}</td>
                      <td className="px-3.5 py-3 text-sm">{record.mealBreak}</td>
                      <td className="px-3.5 py-3 text-sm">{record.workHours}</td>
                      <td className="px-3.5 py-3 text-sm">{record.overtime}</td>
                      <td className="px-3.5 py-3">
                        <div className="flex items-center gap-2">
                          <button className="btn size-8 bg-success/10 hover:bg-success hover:text-white text-success">
                            <LuCheck className="size-4" />
                          </button>
                          <button className="btn size-8 bg-danger/10 hover:bg-danger hover:text-white text-danger">
                            <LuX className="size-4" />
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </div>

        <div className="card-footer">
          <p className="text-default-500 text-sm">
            Showing <b>{records.length}</b> of <b>15</b> Results
          </p>
          <nav className="flex items-center gap-2" aria-label="Pagination">
            <button
              type="button"
              className="btn btn-sm border bg-transparent border-default-200 text-default-600 hover:bg-primary/10 hover:text-primary hover:border-primary/10"
            >
              <LuChevronLeft className="size-4 me-1" /> Prev
            </button>

            <button
              type="button"
              className="btn size-7.5 bg-transparent border border-default-200 text-default-600 hover:bg-primary/10 hover:text-primary hover:border-primary/10"
            >
              1
            </button>

            <button type="button" className="btn size-7.5 bg-primary text-white">
              2
            </button>

            <button
              type="button"
              className="btn size-7.5 bg-transparent border border-default-200 text-default-600 hover:bg-primary/10 hover:text-primary hover:border-primary/10"
            >
              3
            </button>

            <button
              type="button"
              className="btn btn-sm border bg-transparent border-default-200 text-default-600 hover:bg-primary/10 hover:text-primary hover:border-primary/10"
            >
              Next <LuChevronRight className="size-4 ms-1" />
            </button>
          </nav>
        </div>
      </div>
    </div>
  );
};

export default EmployeeWork;
