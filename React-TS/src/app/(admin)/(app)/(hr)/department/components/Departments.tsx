import { LuChevronLeft, LuChevronRight, LuPencil, LuPlus, LuTrash2 } from 'react-icons/lu';
import { Link } from 'react-router';

type Department = {
  id: number;
  name: string;
  head: string;
  phone: string;
  email: string;
  employees: number;
};

const departmentsData: Department[] = [
  {
    id: 1,
    name: 'Web Development',
    head: 'Patricia Garcia',
    phone: '077 7317 7572',
    email: 'PatriciaJGarcia@tailwick.com',
    employees: 15,
  },
  {
    id: 2,
    name: 'IOS Application Development',
    head: 'Frederiksen',
    phone: '61 53 62 05',
    email: 'jonas@tailwick.com',
    employees: 9,
  },
  {
    id: 3,
    name: 'Designing',
    head: 'Juliette Fecteau',
    phone: '07231 96 25 88',
    email: 'JulietteFecteau@tailwick.com',
    employees: 11,
  },
  {
    id: 4,
    name: 'HR Management',
    head: 'Thomas Hatfield',
    phone: '0911 47 65 49',
    email: 'thomas@tailwick.com',
    employees: 3,
  },
  {
    id: 5,
    name: 'Accounts Management',
    head: 'Holly Kavanaugh',
    phone: '819 947 5846',
    email: 'HollyKavanaugh@tailwick.com',
    employees: 2,
  },
];

const Departments = () => {
  return (
    <div className="card">
      <div className="card-header flex justify-between items-center">
        <h6 className="card-title">Departments</h6>
        <button className="btn btn-sm bg-primary text-white flex items-center gap-1">
          <LuPlus className="size-4" /> Add Department
        </button>
      </div>

      <div className="flex flex-col">
        <div className="overflow-x-auto">
          <div className="min-w-full inline-block align-middle">
            <div className="overflow-hidden">
              <table className="min-w-full divide-y divide-default-200">
                <thead className="font-semibold whitespace-nowrap">
                  <tr className="text-sm text-default-800 divide-x divide-default-200">
                    <th className="px-3.5 py-3 text-start">#</th>
                    <th className="px-3.5 py-3 text-start">Department Name</th>
                    <th className="px-3.5 py-3 text-start">Head of Dep.</th>
                    <th className="px-3.5 py-3 text-start">Phone Number</th>
                    <th className="px-3.5 py-3 text-start">Email</th>
                    <th className="px-3.5 py-3 text-start">Employee</th>
                    <th className="px-3.5 py-3 text-start">Action</th>
                  </tr>
                </thead>

                <tbody className="divide-y divide-default-200">
                  {departmentsData.map(dept => (
                    <tr
                      key={dept.id}
                      className="text-default-800 font-normal whitespace-nowrap divide-x divide-default-200"
                    >
                      <td className="px-3.5 py-3 text-sm">{dept.id}</td>
                      <td className="px-3.5 py-3 text-sm">{dept.name}</td>
                      <td className="px-3.5 py-3 text-sm">{dept.head}</td>
                      <td className="px-3.5 py-3 text-sm">{dept.phone}</td>
                      <td className="px-3.5 py-3 text-sm">{dept.email}</td>
                      <td className="px-3.5 py-3 text-sm">
                        {dept.employees.toString().padStart(2, '0')}
                      </td>
                      <td className="px-3.5 py-3">
                        <div className="flex items-center gap-2">
                          <Link
                            to="#"
                            className="btn size-8 bg-default-200 hover:bg-primary/10 hover:text-primary text-default-600"
                            aria-haspopup="dialog"
                            aria-expanded="false"
                            aria-controls="department-edit-modal"
                            data-hs-overlay="#department-edit-modal"
                          >
                            <LuPencil className="size-4" />
                          </Link>

                          <Link
                            to="#"
                            className="btn size-8 bg-default-200 hover:bg-primary/10 hover:text-primary text-default-600"
                            aria-haspopup="dialog"
                            aria-expanded="false"
                            aria-controls="department-delete-modal"
                            data-hs-overlay="#department-delete-modal"
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
            Showing <b>{departmentsData.length}</b> of <b>8</b> Results
          </p>
          <nav className="flex items-center gap-2" aria-label="Pagination">
            <button
              type="button"
              className="btn btn-sm border bg-transparent border-default-200 text-default-600 hover:bg-primary/10 hover:text-primary hover:border-primary/10 flex items-center"
            >
              <LuChevronLeft className="size-4 me-1" /> Prev
            </button>
            <button className="btn size-7.5 bg-transparent border border-default-200 text-default-600 hover:bg-primary/10 hover:text-primary">
              1
            </button>
            <button className="btn size-7.5 bg-primary text-white">2</button>
            <button className="btn size-7.5 bg-transparent border border-default-200 text-default-600 hover:bg-primary/10 hover:text-primary">
              3
            </button>
            <button
              type="button"
              className="btn btn-sm border bg-transparent border-default-200 text-default-600 hover:bg-primary/10 hover:text-primary hover:border-primary/10 flex items-center"
            >
              Next <LuChevronRight className="size-4 ms-1" />
            </button>
          </nav>
        </div>
      </div>
    </div>
  );
};

export default Departments;
