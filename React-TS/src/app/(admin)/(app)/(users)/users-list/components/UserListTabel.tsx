import avatar1 from '@/assets/images/user/avatar-1.png';
import avatar2 from '@/assets/images/user/avatar-2.png';
import avatar5 from '@/assets/images/user/avatar-5.png';
import avatar7 from '@/assets/images/user/avatar-7.png';

import { Link } from 'react-router';
import {
  LuChevronLeft,
  LuChevronRight,
  LuCircleCheck,
  LuCircleX,
  LuDownload,
  LuEllipsis,
  LuEye,
  LuLoader,
  LuPlus,
  LuSearch,
  LuSlidersHorizontal,
  LuSquarePen,
  LuTrash2,
} from 'react-icons/lu';

type User = {
  id: string;
  name: string;
  role: string;
  location: string;
  email: string;
  phone: string;
  joiningDate: string;
  status: 'Verified' | 'Waiting' | 'Rejected';
  avatar?: string;
  initials?: string;
};

const UserListTabel = () => {
  const users: User[] = [
    {
      id: '#TW1500001',
      name: 'Marie Prohaska',
      role: 'Graphic Designer',
      location: 'United Kingdom',
      email: 'prohaska@tailwick.com',
      phone: '853 565 9802',
      joiningDate: '04 Jan, 2023',
      status: 'Verified',
      avatar: avatar2,
    },
    {
      id: '#TW1500002',
      name: 'Jaqueline Hammes',
      role: 'ASP.Net Developer',
      location: 'Brazil',
      email: 'jaqueline@tailwick.com',
      phone: '546 6334 586',
      joiningDate: '18 Jan, 2023',
      status: 'Waiting',
      avatar: avatar1,
    },
    {
      id: '#TW1500003',
      name: 'Marlene Hirthe',
      role: 'Angular Developer',
      location: 'Spain',
      email: 'marlene@tailwick.com',
      phone: '141 654 9876',
      joiningDate: '04 Feb, 2023',
      status: 'Verified',
      avatar: avatar2,
    },
    {
      id: '#TW1500004',
      name: 'Darien Romaguera',
      role: 'PHP Developer',
      location: 'United Kingdom',
      email: 'darien@tailwick.com',
      phone: '687 1345 935',
      joiningDate: '18 May, 2023',
      status: 'Verified',
      avatar: avatar5,
    },
    {
      id: '#TW1500005',
      name: 'Jessika McKenzie',
      role: 'UI/UX Designer',
      location: 'France',
      email: 'jessika@tailwick.com',
      phone: '546 8745 235',
      joiningDate: '14 Jul, 2023',
      status: 'Rejected',
      avatar: avatar7,
    },
    {
      id: '#TW1500006',
      name: 'Domenic Tromp',
      role: 'Team Leader',
      location: 'Germany',
      email: 'domenic@tailwick.com',
      phone: '612 6088 735',
      joiningDate: '27 Oct, 2023',
      status: 'Verified',
      initials: 'DT',
    },
    {
      id: '#TW1500007',
      name: 'Chandler Erdman',
      role: 'React Developer',
      location: 'Japan',
      email: 'chandler@tailwick.com',
      phone: '687 1345 935',
      joiningDate: '21 Nov, 2023',
      status: 'Waiting',
      initials: 'CE',
    },
    {
      id: '#TW1500008',
      name: 'Lavada Muller',
      role: 'Laravel Developer',
      location: 'United States',
      email: 'lavada@tailwick.com',
      phone: '141 654 9876',
      joiningDate: '05 Dec, 2023',
      status: 'Rejected',
      initials: 'LM',
    },
    {
      id: '#TW1500009',
      name: 'Ambrose Hills',
      role: 'Python Developer',
      location: 'China',
      email: 'ambrose@tailwick.com',
      phone: '697 4563 453',
      joiningDate: '25 Dec, 2023',
      status: 'Verified',
      initials: 'AH',
    },
    {
      id: '#TW1500010',
      name: 'Dameon Watsica',
      role: 'Team Leader',
      location: 'France',
      email: 'dameon@tailwick.com',
      phone: '141 654 9876',
      joiningDate: '14 Jan, 2024',
      status: 'Verified',
      initials: 'DW',
    },
  ];

  return (
    <div className="card">
      <div className="card-header">
        <h6 className="card-title">Users List</h6>
        <button className="btn btn-sm bg-primary text-white">
          <LuPlus className="size-4 me-1" />
          Add user
        </button>
      </div>

      <div className="card-header">
        <div className="md:flex items-center md:space-y-0 space-y-4 gap-3">
          <div className="relative">
            <input
              type="email"
              className="form-input form-input-sm ps-9"
              placeholder="Search for name,email"
            />
            <div className="absolute inset-y-0 start-0 flex items-center ps-3">
              <LuSearch className="size-3.5 flex items-center text-default-500 fill-default-100" />
            </div>
          </div>

          <select className="form-input form-input-sm">
            <option defaultValue="">select status</option>
            <option>Hidden</option>
            <option>Rejected</option>
            <option>Verified</option>
            <option>Waiting</option>
          </select>
        </div>

        <div className="flex gap-2 items-center flex-wrap">
          <button
            type="button"
            className="btn btn-sm bg-transparent border border-dashed border-primary  text-primary hover:bg-primary/10"
          >
            <LuDownload className="size-4" />
            Import
          </button>

          <button
            type="button"
            className="btn btn-sm size-7.5 bg-default-100 text-default-500 hover:bg-default-1500  hover:text-white"
          >
            <LuSlidersHorizontal className="size-4" />
          </button>
        </div>
      </div>

      <div className="flex flex-col">
        <div className="overflow-x-auto">
          <div className="min-w-full inline-block align-middle">
            <div className="overflow-hidden">
              <table className="min-w-full divide-y divide-default-200">
                <thead className="bg-default-150">
                  <tr className="text-sm font-normal text-default-700 whitespace-nowrap">
                    <th className="ps-4 text-start">
                      <input id="checkbox-all" type="checkbox" className="form-checkbox" />
                    </th>
                    <th className="px-3.5 py-3 text-start">User ID</th>
                    <th className="px-3.5 py-3 text-start">Name</th>
                    <th className="px-3.5 py-3 text-start">Location</th>
                    <th className="px-3.5 py-3 text-start">Email</th>
                    <th className="px-3.5 py-3 text-start">Phone Number</th>
                    <th className="px-3.5 py-3 text-start">Joining Date</th>
                    <th className="px-3.5 py-3 text-start">Status</th>
                    <th className="px-3.5 py-3 text-start">Action</th>
                  </tr>
                </thead>
                <tbody>
                  {users.map(user => (
                    <tr
                      key={user.id}
                      className="text-default-800 font-normal text-sm whitespace-nowrap"
                    >
                      <td className="py-3 ps-4">
                        <input type="checkbox" className="form-checkbox" />
                      </td>
                      <td className="px-3.5 py-3 text-primary">{user.id}</td>
                      <td className="flex py-3 px-3.5 items-center gap-3">
                        {user.avatar ? (
                          <img
                            src={user.avatar}
                            alt={user.name}
                            className="w-10 h-10 rounded-full"
                          />
                        ) : (
                          <div className="w-10 h-10 flex items-center justify-center rounded-full bg-default-200 font-semibold">
                            {user.initials}
                          </div>
                        )}
                        <div>
                          <h6 className="mb-1.5 font-semibold">
                            <Link to="#" className="text-default-800">
                              {user.name}
                            </Link>
                          </h6>
                          <p className="text-default-500">{user.role}</p>
                        </div>
                      </td>
                      <td className="py-3 px-3.5">{user.location}</td>
                      <td className="py-3 px-3.5">{user.email}</td>
                      <td className="py-3 px-3.5">{user.phone}</td>
                      <td className="py-3 px-3.5">{user.joiningDate}</td>
                      <td className="px-3.5 py-3">
                        {user.status === 'Verified' && (
                          <span className="py-0.5 px-2.5 inline-flex items-center gap-x-1 text-xs font-medium bg-success/10 text-success rounded">
                            <LuCircleCheck className="size-3" />
                            Verified
                          </span>
                        )}
                        {user.status === 'Waiting' && (
                          <span className="py-0.5 px-2.5 inline-flex items-center gap-x-1 text-xs font-medium bg-default-200 text-default-600 rounded">
                            <LuLoader className="size-3" />
                            Waiting
                          </span>
                        )}
                        {user.status === 'Rejected' && (
                          <span className="py-0.5 px-2.5 inline-flex items-center gap-x-1 text-xs font-medium bg-danger/10 text-danger rounded">
                            <LuCircleX className="size-3" />
                            Rejected
                          </span>
                        )}
                      </td>
                      <td className="px-3.5 py-3">
                        <div className="hs-dropdown relative inline-flex">
                          <button
                            type="button"
                            className="hs-dropdown-toggle btn size-7.5 bg-default-200 hover:bg-default-600 text-default-500"
                          >
                            <LuEllipsis className="size-4" />
                          </button>
                          <div className="hs-dropdown-menu" role="menu">
                            <Link
                              to="#"
                              className="flex items-center gap-1.5 py-1.5 px-3 text-default-500 hover:bg-default-150 rounded"
                            >
                              <LuEye className="size-3" /> Overview
                            </Link>
                            <Link
                              to="#"
                              className="flex items-center gap-1.5 py-1.5 px-3 text-default-500 hover:bg-default-150 rounded"
                            >
                              <LuSquarePen className="size-3" /> Edit
                            </Link>
                            <Link
                              to="#"
                              className="flex items-center gap-1.5 py-1.5 px-3 text-default-500 hover:bg-default-150 rounded"
                            >
                              <LuTrash2 className="size-3" /> Delete
                            </Link>
                          </div>
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
            Showing <b>10</b> of <b>58</b> Results
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
              Next
              <LuChevronRight className="size-4 ms-1" />
            </button>
          </nav>
        </div>
      </div>
    </div>
  );
};

export default UserListTabel;
