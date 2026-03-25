import User1 from '@/assets/images/user/user-1.jpg';
import User2 from '@/assets/images/user/user-2.jpg';
import User3 from '@/assets/images/user/user-3.jpg';
import User4 from '@/assets/images/user/user-4.jpg';

import {
  LuChevronLeft,
  LuChevronRight,
  LuEye,
  LuPlus,
  LuSquarePen,
  LuTrash2,
} from 'react-icons/lu';
import { Link } from 'react-router';

type Employee = {
  id: string;
  name: string;
  image: string;
  designation: string;
  email: string;
  phone: string;
  location: string;
  experience: string;
  joiningDate: string;
};

const employees: Employee[] = [
  {
    id: '#TWE1001528',
    name: 'Willie Torres',
    image: User1,
    designation: 'Nuxt JS Developer',
    email: 'willie@tailwick.com',
    phone: '070 3715 3689',
    location: 'United States',
    experience: '3 Year',
    joiningDate: '05 Feb, 2020',
  },
  {
    id: '#TWE1001524',
    name: 'Patricia Garcia',
    image: User2,
    designation: 'ASP.Net Developer',
    email: 'PatriciaJGarcia@tailwick.com',
    phone: '077 7317 7572',
    location: 'Brazil',
    experience: '0.5 Year',
    joiningDate: '12 Aug, 2023',
  },
  {
    id: '#TWE1001506',
    name: 'Tonya Johnson',
    image: User3,
    designation: 'Project Manager',
    email: 'TonyaEJohnson@tailwick.com',
    phone: '079 2383 2340',
    location: 'Denmark',
    experience: '0 Year',
    joiningDate: '11 Nov, 2023',
  },
  {
    id: '#TWE1001502',
    name: 'Jose White',
    image: User4,
    designation: 'React Developer',
    email: 'ameida@tailwick.com',
    phone: '03476 56 14 12',
    location: 'Philippines',
    experience: '1.5 Year',
    joiningDate: '09 Jun, 2022',
  },
  {
    id: '#TWE1001503',
    name: 'Juliette Fecteau',
    image: User1,
    designation: 'Sr. Angular Developer',
    email: 'JulietteFecteau@tailwick.com',
    phone: '07231 96 25 88',
    location: 'Belgium',
    experience: '1.9 Year',
    joiningDate: '11 May, 2021',
  },
  {
    id: '#TWE1001504',
    name: 'Jonas Frederiksen',
    image: User2,
    designation: 'Team Leader',
    email: 'jonas@tailwick.com',
    phone: '61 53 62 05',
    location: 'France',
    experience: '2.9 Year',
    joiningDate: '18 Jan, 2019',
  },
  {
    id: '#TWE1001505',
    name: 'Kim Broberg',
    image: User4,
    designation: 'UI / UX Designer',
    email: 'KimBroberg@tailwick.com',
    phone: '040 382 2096',
    location: 'Finland',
    experience: '1.2 Year',
    joiningDate: '23 April, 2021',
  },
];

const EmployeeDetails = () => {
  return (
    <div className="card">
      <div className="card-header flex justify-between items-center">
        <h6 className="card-title">Employee ({employees.length})</h6>
        <button className="btn btn-sm bg-primary text-white flex items-center gap-1">
          <LuPlus className="size-4" /> Add Employee
        </button>
      </div>

      <div className="flex flex-col">
        <div className="overflow-x-auto">
          <div className="min-w-full inline-block align-middle">
            <div className="overflow-hidden">
              <table className="min-w-full divide-y divide-default-200">
                <thead className="bg-default-100 font-normal whitespace-nowrap">
                  <tr className="text-sm text-default-800">
                    <th className="px-3.5 py-3 font-medium text-start">Employee ID</th>
                    <th className="px-3.5 py-3 font-medium text-start">Name</th>
                    <th className="px-3.5 py-3 font-medium text-start">Designation</th>
                    <th className="px-3.5 py-3 font-medium text-start">Email Id</th>
                    <th className="px-3.5 py-3 font-medium text-start">Phone Number</th>
                    <th className="px-3.5 py-3 font-medium text-start">Location</th>
                    <th className="px-3.5 py-3 font-medium text-start">Experience</th>
                    <th className="px-3.5 py-3 font-medium text-start">Joining Date</th>
                    <th className="px-3.5 py-3 font-medium text-start">Action</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-default-200">
                  {employees.map(emp => (
                    <tr key={emp.id} className="text-default-800 font-normal whitespace-nowrap">
                      <td className="px-3.5 py-3 text-sm text-primary">{emp.id}</td>
                      <td className="px-3.5 py-3 text-sm">
                        <Link to="#" className="flex gap-3 items-center">
                          <img
                            src={emp.image}
                            alt={emp.name}
                            className="h-6 rounded-full"
                            width={24}
                          />
                          <h6 className="text-heading font-medium">{emp.name}</h6>
                        </Link>
                      </td>
                      <td className="px-3.5 py-3 text-sm">{emp.designation}</td>
                      <td className="px-3.5 py-3 text-sm">{emp.email}</td>
                      <td className="px-3.5 py-3 text-sm">{emp.phone}</td>
                      <td className="px-3.5 py-3 text-sm">{emp.location}</td>
                      <td className="px-3.5 py-3 text-sm">{emp.experience}</td>
                      <td className="px-3.5 py-3 text-sm">{emp.joiningDate}</td>
                      <td className="px-3.5 py-3">
                        <div className="flex items-center gap-2">
                          <Link
                            className="flex size-8 bg-default-200 rounded-md items-center justify-center hover:bg-primary/10 hover:text-primary transition-all text-default-600"
                            to="#"
                          >
                            <LuEye className="size-3" />
                          </Link>
                          <Link
                            className="flex size-8 bg-default-200 rounded-md items-center justify-center hover:bg-primary/10 hover:text-primary transition-all text-default-600"
                            to="#"
                            aria-haspopup="dialog"
                            aria-expanded="false"
                            aria-controls="employeeEdit"
                            data-hs-overlay="#employeeEdit"
                          >
                            <LuSquarePen className="size-4" />
                          </Link>
                          <Link
                            className="flex size-8 bg-default-200 rounded-md items-center justify-center hover:bg-primary/10 hover:text-primary transition-all text-default-600"
                            to="#"
                            aria-haspopup="dialog"
                            aria-expanded="false"
                            aria-controls="employeeDelete"
                            data-hs-overlay="#employeeDelete"
                          >
                            <LuTrash2 className="size-4" />
                          </Link>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </div>

        <div className="card-footer flex justify-between items-center">
          <p className="text-default-500 text-sm">
            Showing <b>{employees.length}</b> of <b>38</b> Results
          </p>
          <nav className="flex items-center gap-2" aria-label="Pagination">
            <button className="btn btn-sm border bg-transparent border-default-200 text-default-600 hover:bg-primary/10 hover:text-primary hover:border-primary/10 flex items-center gap-1">
              <LuChevronLeft className="size-4" /> Prev
            </button>
            <button className="btn size-7.5 bg-transparent border border-default-200 text-default-600 hover:bg-primary/10 hover:text-primary hover:border-primary/10">
              1
            </button>
            <button className="btn size-7.5 bg-primary text-white">2</button>
            <button className="btn size-7.5 bg-transparent border border-default-200 text-default-600 hover:bg-primary/10 hover:text-primary hover:border-primary/10">
              3
            </button>
            <button className="btn btn-sm border bg-transparent border-default-200 text-default-600 hover:bg-primary/10 hover:text-primary hover:border-primary/10 flex items-center gap-1">
              Next <LuChevronRight className="size-4" />
            </button>
          </nav>
        </div>
      </div>
    </div>
  );
};

export default EmployeeDetails;
