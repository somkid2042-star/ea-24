import avatar1 from '@/assets/images/user/avatar-1.png';
import avatar2 from '@/assets/images/user/avatar-2.png';
import avatar3 from '@/assets/images/user/avatar-3.png';
import avatar4 from '@/assets/images/user/avatar-4.png';
import avatar5 from '@/assets/images/user/avatar-5.png';
import avatar6 from '@/assets/images/user/avatar-6.png';
import avatar7 from '@/assets/images/user/avatar-7.png';
import avatar8 from '@/assets/images/user/avatar-8.png';

import { Link } from 'react-router';
import {
  LuChevronLeft,
  LuChevronRight,
  LuEllipsis,
  LuEye,
  LuMessagesSquare,
  LuPlus,
  LuSearch,
  LuSlidersHorizontal,
  LuSquarePen,
  LuTrash2,
} from 'react-icons/lu';

type User = {
  id: number;
  name: string;
  role: string;
  username: string;
  address: string;
  avatar?: string;
  initials?: string;
  status: 'success' | 'danger';
};

const UserGrid = () => {
  const users: User[] = [
    {
      id: 1,
      name: 'Paula Keenan',
      role: '@Admin',
      username: 'Admin',
      address: '748 Luettgen Plain Suite South Winstonfort, NM',
      avatar: avatar1,
      status: 'success',
    },
    {
      id: 2,
      name: 'Marie Prohaska',
      role: '@Subscriber',
      username: 'Subscriber',
      address: '125 Ortiz Camp Suite 471 Rippinport, US',
      avatar: avatar2,
      status: 'success',
    },
    {
      id: 3,
      name: 'Jaqueline Hammes',
      role: '@Editor',
      username: 'Editor',
      address: '8716 Dell Manors New Ahmedmouth, WI',
      avatar: avatar3,
      status: 'success',
    },
    {
      id: 4,
      name: 'Angus Bergstrom',
      role: '@Developer',
      username: 'Developer',
      address: '617 Powlowski Crossroad Apt. 716 New Victoria',
      initials: 'AB',
      status: 'success',
    },
    {
      id: 5,
      name: 'Aurore Maggio',
      role: '@Subscriber',
      username: 'Subscriber',
      address: '8751 Boyer Courts Suite 532 West Fletcherside',
      avatar: avatar4,
      status: 'danger',
    },
    {
      id: 6,
      name: 'Andrea Pesina',
      role: '@Editor',
      username: 'Editor',
      address: '32 Maidstone Road WELLSBOROUGH',
      initials: 'AP',
      status: 'success',
    },
    {
      id: 7,
      name: 'Daniel Miller',
      role: '@Subscriber',
      username: 'Subscriber',
      address: '431 Elk Rd Little Ticonderoga, NY',
      avatar: avatar5,
      status: 'danger',
    },
    {
      id: 8,
      name: 'Ashley Wilson',
      role: '@Subscriber',
      username: 'Subscriber',
      address: '0816 Bradford Alley Lake Adamfort, ME',
      avatar: avatar6,
      status: 'success',
    },
    {
      id: 9,
      name: 'William Heineman',
      role: '@Author',
      username: 'Author',
      address: '99614 Pollich Extension Apt. 938 South Alf, GA',
      avatar: avatar7,
      status: 'success',
    },
    {
      id: 10,
      name: 'Kara Miller',
      role: '@Subscriber',
      username: 'Subscriber',
      address: '755 Kody Plaza Apt. 138 East Reinholdberg, AR',
      avatar: avatar8,
      status: 'success',
    },
    {
      id: 11,
      name: 'Mark Walton',
      role: '@Author',
      username: 'Author',
      address: '895 Camylle Tunnel Lake Chasity, SC',
      initials: 'MW',
      status: 'success',
    },
    {
      id: 12,
      name: 'David Biggs',
      role: '@Subscriber',
      username: 'Subscriber',
      address: '75, Deccan Gymkhana, Alwar',
      initials: 'DB',
      status: 'danger',
    },
  ];

  return (
    <>
      <div className="flex justify-between gap-3 flex-wrap items-center mb-5">
        <div className="relative">
          <input
            type="email"
            className="form-input form-input-sm ps-9"
            placeholder="Search for name,email,phone number etc..."
          />
          <div className="absolute inset-y-0 start-4 flex items-center">
            <LuSearch className="size-3.5 flex items-center text-default-500" />
          </div>
        </div>

        <div className="flex gap-3 items-center">
          <button
            type="button"
            className="btn btn-sm bg-primary text-white"
            aria-haspopup="dialog"
            aria-expanded="false"
            aria-controls="addUserModal"
            data-hs-overlay="#addUserModal"
          >
            <LuPlus className="size-4 ms-1" />
            Add User
          </button>

          <button
            type="button"
            className="btn size-7.5 bg-default-500 text-white hover:bg-default-600   "
          >
            <LuSlidersHorizontal className="size-4" />
          </button>
        </div>
      </div>

      <div className="grid lg:grid-cols-4 md:grid-cols-2 grid-cols-1 gap-5 mb-5">
        {users.map(user => (
          <div key={user.id} className="card">
            <div className="card-body">
              <div className="relative flex items-center justify-center mx-auto text-lg rounded-full size-16 bg-default-100">
                {user.avatar ? (
                  <img src={user.avatar} alt={user.name} className="rounded-full size-16" />
                ) : (
                  <span>{user.initials}</span>
                )}
                <span
                  className={`absolute ${
                    user.status === 'success' ? 'bg-success' : 'bg-danger'
                  } border-2 border-white rounded-full size-3 end-0 bottom-1`}
                ></span>
              </div>

              <div className="mt-4 text-center text-default-500">
                <h5 className="mb-1 text-base text-default-800 font-semibold">
                  <Link to="/account">{user.name}</Link>
                </h5>
                <p className="mb-3 text-sm text-default-500">{user.role}</p>
                <p className="text-sm text-default-500">{user.address}</p>
              </div>

              <div className="flex gap-2 mt-5">
                <Link
                  to="/chat"
                  className="btn border-primary text-primary hover:bg-primary hover:text-white flex-grow"
                >
                  <LuMessagesSquare size={14} />
                  <span className="align-middle">Send Message</span>
                </Link>

                <div className="hs-dropdown relative inline-flex">
                  <button
                    type="button"
                    className="hs-dropdown-toggle btn bg-primary size-9 text-white"
                    aria-haspopup="menu"
                    aria-expanded="false"
                    aria-label="Dropdown"
                    hs-dropdown-placement="bottom-end"
                  >
                    <LuEllipsis className="iconify lucide--ellipsis size-4" />
                  </button>
                  <div className="hs-dropdown-menu" role="menu">
                    <Link
                      className="flex items-center gap-1.5 py-1.5 font-medium px-3 text-default-500 hover:bg-default-150 rounded"
                      to="#"
                    >
                      <LuEye className="size-3" />
                      Overview
                    </Link>
                    <Link
                      className="flex items-center gap-1.5 py-1.5 font-medium px-3 text-default-500 hover:bg-default-150 rounded"
                      to="#"
                    >
                      <LuSquarePen className="size-3" />
                      Edit
                    </Link>
                    <Link
                      className="flex items-center gap-1.5 py-1.5 font-medium px-3 text-default-500 hover:bg-default-150 rounded"
                      to="#"
                    >
                      <LuTrash2 className="size-3" />
                      Delete
                    </Link>
                  </div>
                </div>
              </div>
            </div>
          </div>
        ))}
      </div>

      <div className="flex flex-wrap md:justify-between justify-center items-centermd:gap-0 gap-4 my-5 text-default-500">
        <p className="text-default-500 text-sm">
          Showing <b>07</b> of <b>19</b> Results
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
    </>
  );
};

export default UserGrid;
