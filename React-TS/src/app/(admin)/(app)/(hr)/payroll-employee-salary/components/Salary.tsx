import user10 from '@/assets/images/user/avatar-10.png';
import user11 from '@/assets/images/user/avatar-11.png';
import user03 from '@/assets/images/user/avatar-3.png';
import user04 from '@/assets/images/user/avatar-4.png';
import user05 from '@/assets/images/user/avatar-5.png';
import user06 from '@/assets/images/user/avatar-6.png';
import user07 from '@/assets/images/user/avatar-7.png';
import user08 from '@/assets/images/user/avatar-8.png';
import user09 from '@/assets/images/user/avatar-9.png';
import user01 from '@/assets/images/user/user-1.jpg';

import { Link } from 'react-router';
import React from 'react';
import Flatpickr from 'react-flatpickr';
import { LuEllipsis, LuEye, LuPlus, LuSearch, LuSquarePen, LuTrash2 } from 'react-icons/lu';

type Employee = {
  id: string;
  joinDate: string;
  name: string;
  designation: string;
  email: string;
  phone: string;
  salary: string;
  bonus: string;
  image: string;
};

const employees: Employee[] = [
  {
    id: '#TWE1001501',
    joinDate: '05 Feb, 2020',
    name: 'Willie Torres',
    designation: 'Nuxt JS Developer',
    email: 'willie@tailwick.com',
    phone: '070 3715 3689',
    salary: '$8,500',
    bonus: '$500',
    image: user01,
  },
  {
    id: '#TWE1001524',
    joinDate: '12 Aug, 2023',
    name: 'Patricia Garcia',
    designation: 'ASP.Net Developer',
    email: 'PatriciaJGarcia@tailwick.com',
    phone: '077 7317 7572',
    salary: '$3,800',
    bonus: '-',
    image: user03,
  },
  {
    id: '#TWE1001531',
    joinDate: '15 Dec, 2018',
    name: 'Carlos Reed',
    designation: 'React Developer',
    email: 'carlos@tailwick.com',
    phone: '071 2351 4789',
    salary: '$7,200',
    bonus: '$300',
    image: user04,
  },
  {
    id: '#TWE1001548',
    joinDate: '03 Mar, 2021',
    name: 'Sophia Martinez',
    designation: 'UI/UX Designer',
    email: 'sophia@tailwick.com',
    phone: '072 4823 9812',
    salary: '$5,600',
    bonus: '-',
    image: user05,
  },
  {
    id: '#TWE1001556',
    joinDate: '20 Jul, 2019',
    name: 'James Anderson',
    designation: 'PHP Developer',
    email: 'james@tailwick.com',
    phone: '073 9132 5627',
    salary: '$6,400',
    bonus: '$250',
    image: user06,
  },
  {
    id: '#TWE1001573',
    joinDate: '10 Nov, 2022',
    name: 'Emma Johnson',
    designation: 'Project Manager',
    email: 'emma@tailwick.com',
    phone: '074 1289 4455',
    salary: '$9,500',
    bonus: '$800',
    image: user07,
  },
  {
    id: '#TWE1001589',
    joinDate: '18 May, 2020',
    name: 'Liam Wilson',
    designation: 'Laravel Developer',
    email: 'liam@tailwick.com',
    phone: '075 4578 3321',
    salary: '$6,900',
    bonus: '-',
    image: user08,
  },
  {
    id: '#TWE1001602',
    joinDate: '25 Sep, 2021',
    name: 'Olivia Brown',
    designation: 'HR Executive',
    email: 'olivia@tailwick.com',
    phone: '076 9134 2288',
    salary: '$4,300',
    bonus: '-',
    image: user09,
  },
  {
    id: '#TWE1001620',
    joinDate: '07 Jan, 2017',
    name: 'Noah Davis',
    designation: 'Java Developer',
    email: 'noah@tailwick.com',
    phone: '078 3214 9012',
    salary: '$8,200',
    bonus: '$600',
    image: user10,
  },
  {
    id: '#TWE1001635',
    joinDate: '14 Apr, 2023',
    name: 'Isabella Miller',
    designation: 'Content Writer',
    email: 'isabella@tailwick.com',
    phone: '079 1423 7789',
    salary: '$3,200',
    bonus: '-',
    image: user11,
  },
];

const EmployeeRow: React.FC<{ emp: Employee }> = ({ emp }) => (
  <tr className="text-default-800 font-normal">
    <td className="px-3.5 py-2.5 whitespace-nowrap text-sm text-primary">
      <Link to="#">{emp.id}</Link>
    </td>
    <td className="px-3.5 py-2.5 whitespace-nowrap text-sm">{emp.joinDate}</td>
    <td className="px-3.5 py-2.5 whitespace-nowrap text-sm">
      <Link to="#" className="flex items-center gap-3">
        <div className="rounded-full size-6 shrink-0 bg-default-100">
          <img src={emp.image} alt={emp.name} className="h-6 rounded-full" />
        </div>
        <h6 className="text-sm text-default-800">{emp.name}</h6>
      </Link>
    </td>
    <td className="px-3.5 py-2.5 whitespace-nowrap text-sm">{emp.designation}</td>
    <td className="px-3.5 py-2.5 whitespace-nowrap text-sm">{emp.email}</td>
    <td className="px-3.5 py-2.5 whitespace-nowrap text-sm">{emp.phone}</td>
    <td className="px-3.5 py-2.5 whitespace-nowrap text-sm">{emp.salary}</td>
    <td className="px-3.5 py-2.5 whitespace-nowrap text-sm">{emp.bonus}</td>
    <td className="px-3.5 py-2.5 whitespace-nowrap text-sm flex items-center gap-2">
      <Link
        to="/create-payslip"
        className="text-xs text-white bg-sky-500 transition-all duration-300 hover:bg-sky-600 rounded py-1.5 px-2"
      >
        Generate Slip
      </Link>
      <div className="hs-dropdown relative inline-flex">
        <button
          type="button"
          className="hs-dropdown-toggle btn size-7.5 bg-default-200 hover:bg-default-600 text-default-500 hover:text-white"
          aria-haspopup="menu"
          aria-expanded="false"
          aria-label="Dropdown"
          hs-dropdown-placement="bottom-end"
        >
          <LuEllipsis className="size-4" />
        </button>
        <div
          className="hs-dropdown-menu transition-[opacity,margin] duration hs-dropdown-open:opacity-100 opacity-0 hidden min-w-40 card z-30 mt-2 p-2"
          role="menu"
        >
          <Link
            className="flex items-center gap-1.5 py-1.5 font-medium px-3 text-sm text-default-500 hover:bg-default-150 rounded"
            to="#"
          >
            <LuEye className="size-3" /> Overview
          </Link>
          <Link
            className="flex items-center gap-1.5 py-1.5 font-medium px-3 text-sm text-default-500 hover:bg-default-150 rounded"
            to="#"
          >
            <LuSquarePen className="size-3" /> Edit
          </Link>
          <Link
            className="flex items-center gap-1.5 py-1.5 font-medium px-3 text-sm text-default-500 hover:bg-default-150 rounded"
            to="#"
          >
            <LuTrash2 className="size-3" /> Delete
          </Link>
        </div>
      </div>
    </td>
  </tr>
);

const Salary = () => {
  return (
    <div className="card">
      <div className="card-header">
        <div className="flex gap-3">
          <div className="relative">
            <input
              type="text"
              className="form-input form-input-sm ps-9"
              placeholder="Search for..."
            />
            <div className="absolute inset-y-0 start-0 flex items-center ps-3">
              <LuSearch className="size-4 flex items-center text-default-500" />
            </div>
          </div>

          <Flatpickr
            options={{
              mode: 'range',
              enableTime: true,
              dateFormat: 'Y-m-d',
            }}
            className="form-input form-input-sm lg:w-52 w-full"
            placeholder="Select Date"
          />
        </div>

        <Link to="/create-payslip" className="btn btn-sm bg-primary text-white">
          <LuPlus className="size-4 me-1" />
          Create Salary
        </Link>
      </div>

      <div className="flex flex-col">
        <div className="overflow-x-auto">
          <div className="min-w-full inline-block align-middle">
            <div className="overflow-hidden">
              <table className="min-w-full divide-y divide-default-200">
                <thead className="bg-default-150">
                  <tr className="text-sm font-normal text-default-500">
                    <th className="px-3.5 py-3 text-start">Employee ID</th>
                    <th className="px-3.5 py-3 text-start">Joining Date</th>
                    <th className="px-3.5 py-3 text-start">Name</th>
                    <th className="px-3.5 py-3 text-start">Designation</th>
                    <th className="px-3.5 py-3 text-start">Email Id</th>
                    <th className="px-3.5 py-3 text-start">Phone Number</th>
                    <th className="px-3.5 py-3 text-start">Salary</th>
                    <th className="px-3.5 py-3 text-start">Bonus</th>
                    <th className="px-3.5 py-3 text-start">Action</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-default-200">
                  {employees.map(emp => (
                    <EmployeeRow key={emp.id} emp={emp} />
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Salary;
