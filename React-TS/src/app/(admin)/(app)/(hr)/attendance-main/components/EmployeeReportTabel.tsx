import Flatpickr from 'react-flatpickr';
import { LuCalendar, LuCheck, LuSearch, LuX } from 'react-icons/lu';

const EmployeeReportTabel = () => {
  return (
    <div className="card">
      <div className="card-header">
        <div className="relative">
          <input
            type="email"
            className="ps-11 form-input form-input-sm"
            placeholder="Search for...."
          />
          <div className="absolute inset-y-0 start-0 flex items-center ps-3">
            <LuSearch className="size-3.5 flex items-center text-default-500" />
          </div>
        </div>

        <div className="relative">
          <Flatpickr
            options={{
              mode: 'range',
              dateFormat: 'd M, Y',
            }}
            className="form-input form-input-sm ps-10"
            placeholder="Select Date"
          />
          <LuCalendar className="absolute top-1.5 start-3 size-4 flex items-center text-default-500" />
        </div>
      </div>

      <div className="flex flex-col">
        <div className="overflow-x-auto">
          <div className="min-w-full inline-block align-middle">
            <div className="overflow-hidden">
              <table className="min-w-full divide-y divide-default-200">
                <thead className="bg-default-100 font-normal whitespace-nowrap">
                  <tr className="text-sm  text-default-800">
                    <th scope="col" className="px-3.5 py-3 font-medium">
                      Employee Name
                    </th>
                    <th scope="col" className="px-3.5 py-3 font-medium">
                      01
                    </th>
                    <th scope="col" className="px-3.5 py-3 font-medium">
                      02
                    </th>
                    <th scope="col" className="px-3.5 py-3 font-medium">
                      03
                    </th>
                    <th scope="col" className="px-3.5 py-3 font-medium">
                      04
                    </th>
                    <th scope="col" className="px-3.5 py-3 font-medium">
                      05
                    </th>
                    <th scope="col" className="px-3.5 py-3 font-medium">
                      06
                    </th>
                    <th scope="col" className="px-3.5 py-3 font-medium">
                      07
                    </th>
                    <th scope="col" className="px-3.5 py-3 font-medium">
                      08
                    </th>
                    <th scope="col" className="px-3.5 py-3 font-medium">
                      09
                    </th>
                    <th scope="col" className="px-3.5 py-3 font-medium">
                      10
                    </th>
                    <th scope="col" className="px-3.5 py-3 font-medium">
                      11
                    </th>
                    <th scope="col" className="px-3.5 py-3 font-medium">
                      12
                    </th>
                    <th scope="col" className="px-3.5 py-3 font-medium">
                      13
                    </th>
                    <th scope="col" className="px-3.5 py-3 font-medium">
                      14
                    </th>
                    <th scope="col" className="px-3.5 py-3 font-medium">
                      15
                    </th>
                    <th scope="col" className="px-3.5 py-3 font-medium">
                      16
                    </th>
                    <th scope="col" className="px-3.5 py-3 font-medium">
                      17
                    </th>
                    <th scope="col" className="px-3.5 py-3 font-medium">
                      18
                    </th>
                    <th scope="col" className="px-3.5 py-3 font-medium">
                      19
                    </th>
                    <th scope="col" className="px-3.5 py-3 font-medium">
                      20
                    </th>
                    <th scope="col" className="px-3.5 py-3 font-medium">
                      21
                    </th>
                    <th scope="col" className="px-3.5 py-3 font-medium">
                      22
                    </th>
                    <th scope="col" className="px-3.5 py-3 font-medium">
                      23
                    </th>
                    <th scope="col" className="px-3.5 py-3 font-medium">
                      24
                    </th>
                    <th scope="col" className="px-3.5 py-3 font-medium">
                      25
                    </th>
                    <th scope="col" className="px-3.5 py-3 font-medium">
                      26
                    </th>
                    <th scope="col" className="px-3.5 py-3 font-medium">
                      27
                    </th>
                    <th scope="col" className="px-3.5 py-3 font-medium">
                      28
                    </th>
                    <th scope="col" className="px-3.5 py-3 font-medium">
                      29
                    </th>
                    <th scope="col" className="px-3.5 py-3 font-medium">
                      30
                    </th>
                  </tr>
                </thead>

                <tbody className="divide-y divide-default-200">
                  <tr className="text-default-800 font-normal whitespace-nowrap">
                    <td className="px-3.5 py-3 text-sm">Patricia Garcia</td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuX className="size-4 text-danger" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuX className="size-4 text-danger" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">-</td>
                    <td className="px-3.5 py-3 text-sm">-</td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuX className="size-4 text-danger" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">-</td>
                    <td className="px-3.5 py-3 text-sm">-</td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuX className="size-4 text-danger" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">-</td>
                    <td className="px-3.5 py-3 text-sm">-</td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuX className="size-4 text-danger" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>

                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">-</td>
                    <td className="px-3.5 py-3 text-sm">-</td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>

                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                  </tr>

                  <tr className="text-default-800 font-normal whitespace-nowrap">
                    <td className="px-3.5 py-3 text-sm">Tonya Johnson</td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">-</td>
                    <td className="px-3.5 py-3 text-sm">-</td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuX className="size-4 text-danger" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">-</td>
                    <td className="px-3.5 py-3 text-sm">-</td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuX className="size-4 text-danger" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">-</td>
                    <td className="px-3.5 py-3 text-sm">-</td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuX className="size-4 text-danger" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">-</td>
                    <td className="px-3.5 py-3 text-sm">-</td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuX className="size-4 text-danger" />
                    </td>
                  </tr>

                  <tr className="text-default-800 font-normal whitespace-nowrap">
                    <td className="px-3.5 py-3 text-sm">Willie Torres</td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuX className="size-4 text-danger" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">-</td>
                    <td className="px-3.5 py-3 text-sm">-</td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuX className="size-4 text-danger" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuX className="size-4 text-danger" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">-</td>
                    <td className="px-3.5 py-3 text-sm">-</td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">-</td>
                    <td className="px-3.5 py-3 text-sm">-</td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">-</td>
                    <td className="px-3.5 py-3 text-sm">-</td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuX className="size-4 text-danger" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                  </tr>

                  <tr className="text-default-800 font-normal whitespace-nowrap">
                    <td className="px-3.5 py-3 text-sm">Jose White</td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">-</td>
                    <td className="px-3.5 py-3 text-sm">-</td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuX className="size-4 text-danger" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">-</td>
                    <td className="px-3.5 py-3 text-sm">-</td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">-</td>
                    <td className="px-3.5 py-3 text-sm">-</td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuX className="size-4 text-danger" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">-</td>
                    <td className="px-3.5 py-3 text-sm">-</td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                  </tr>

                  <tr className="text-default-800 font-normal whitespace-nowrap">
                    <td className="px-3.5 py-3 text-sm">Jose White</td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuX className="size-4 text-danger" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">-</td>
                    <td className="px-3.5 py-3 text-sm">-</td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">-</td>
                    <td className="px-3.5 py-3 text-sm">-</td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuX className="size-4 text-danger" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuX className="size-4 text-danger" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">-</td>
                    <td className="px-3.5 py-3 text-sm">-</td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">-</td>
                    <td className="px-3.5 py-3 text-sm">-</td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                  </tr>

                  <tr className="text-default-800 font-normal whitespace-nowrap">
                    <td className="px-3.5 py-3 text-sm">Jonas Frederiksen</td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">-</td>
                    <td className="px-3.5 py-3 text-sm">-</td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuX className="size-4 text-danger" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuX className="size-4 text-danger" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuX className="size-4 text-danger" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">-</td>
                    <td className="px-3.5 py-3 text-sm">-</td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuX className="size-4 text-danger" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">-</td>
                    <td className="px-3.5 py-3 text-sm">-</td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">-</td>
                    <td className="px-3.5 py-3 text-sm">-</td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuX className="size-4 text-danger" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                  </tr>

                  <tr className="text-default-800 font-normal whitespace-nowrap">
                    <td className="px-3.5 py-3 text-sm">Kim Broberg</td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">-</td>
                    <td className="px-3.5 py-3 text-sm">-</td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>

                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuX className="size-4 text-danger" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">-</td>
                    <td className="px-3.5 py-3 text-sm">-</td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuX className="size-4 text-danger" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">-</td>
                    <td className="px-3.5 py-3 text-sm">-</td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuX className="size-4 text-danger" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">-</td>
                    <td className="px-3.5 py-3 text-sm">-</td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                  </tr>

                  <tr className="text-default-800 font-normal whitespace-nowrap">
                    <td className="px-3.5 py-3 text-sm">Nancy Reynolds</td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">-</td>
                    <td className="px-3.5 py-3 text-sm">-</td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuX className="size-4 text-danger" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>

                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">-</td>
                    <td className="px-3.5 py-3 text-sm">-</td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuX className="size-4 text-danger" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">-</td>
                    <td className="px-3.5 py-3 text-sm">-</td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">-</td>
                    <td className="px-3.5 py-3 text-sm">-</td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                  </tr>

                  <tr className="text-default-800 font-normal whitespace-nowrap">
                    <td className="px-3.5 py-3 text-sm">Thomas Hatfield</td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuX className="size-4 text-danger" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">-</td>
                    <td className="px-3.5 py-3 text-sm">-</td>

                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>

                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuX className="size-4 text-danger" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">-</td>
                    <td className="px-3.5 py-3 text-sm">-</td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>

                    <td className="px-3.5 py-3 text-sm">
                      <LuX className="size-4 text-danger" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">-</td>
                    <td className="px-3.5 py-3 text-sm">-</td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuX className="size-4 text-danger" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">-</td>
                    <td className="px-3.5 py-3 text-sm">-</td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuX className="size-4 text-danger" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                  </tr>

                  <tr className="text-default-800 font-normal whitespace-nowrap">
                    <td className="px-3.5 py-3 text-sm">Holly Kavanaugh</td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">-</td>
                    <td className="px-3.5 py-3 text-sm">-</td>

                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>

                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>

                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuX className="size-4 text-danger" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">-</td>
                    <td className="px-3.5 py-3 text-sm">-</td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuX className="size-4 text-danger" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>

                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">-</td>
                    <td className="px-3.5 py-3 text-sm">-</td>

                    <td className="px-3.5 py-3 text-sm">
                      <LuX className="size-4 text-danger" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuX className="size-4 text-danger" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">-</td>
                    <td className="px-3.5 py-3 text-sm">-</td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuX className="size-4 text-danger" />
                    </td>
                    <td className="px-3.5 py-3 text-sm">
                      <LuCheck className="size-4 text-success" />
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default EmployeeReportTabel;
