import avatar1 from '@/assets/images/user/avatar-1.png';
import avatar10 from '@/assets/images/user/avatar-10.png';
import avatar5 from '@/assets/images/user/avatar-5.png';
import avatar8 from '@/assets/images/user/avatar-8.png';
import user1 from '@/assets/images/user/user-1.jpg';
import user2 from '@/assets/images/user/user-2.jpg';
import user3 from '@/assets/images/user/user-3.jpg';
import user4 from '@/assets/images/user/user-4.jpg';

import { Link } from 'react-router';
import { LuPlus, LuSearch } from 'react-icons/lu';

type Chat = {
  id: number;
  name: string;
  message: string;
  time?: string;
  image?: string;
  initials?: string;
  status: 'online' | 'offline' | 'busy' | 'away' | 'default';
  type: 'recent' | 'all';
};

const chats: Chat[] = [
  {
    id: 1,
    name: 'Marie Prohaska',
    message: 'I will purchase it for support',
    time: '2min ago',
    image: avatar5,
    status: 'online',
    type: 'recent',
  },
  {
    id: 2,
    name: 'Kara Miller',
    message: "Hey, how's it going?",
    time: '02:57 PM',
    image: user1,
    status: 'busy',
    type: 'recent',
  },
  {
    id: 3,
    name: 'Mark Walton',
    message: "Hey, how's it going?",
    time: 'Yesterday',
    image: avatar1,
    status: 'online',
    type: 'recent',
  },
  {
    id: 4,
    name: 'Aurore Maggio',
    message: 'React Developer',
    image: user2,
    status: 'default',
    type: 'all',
  },
  {
    id: 5,
    name: 'Mark Walton',
    message: 'UI / UX Designer',
    initials: 'LP',
    status: 'online',
    type: 'all',
  },
  {
    id: 6,
    name: 'Daniel Miller',
    message: 'ASP.Net Developer',
    image: avatar5,
    status: 'busy',
    type: 'all',
  },
  {
    id: 7,
    name: 'Jaqueline Hammes',
    message: 'Angular Developer',
    image: user3,
    status: 'offline',
    type: 'all',
  },
  {
    id: 8,
    name: 'Andrea Pesina',
    message: 'Laravel Developer',
    image: avatar8,
    status: 'offline',
    type: 'all',
  },
  {
    id: 9,
    name: 'Bernard Pereira',
    message: 'Web Designer',
    image: avatar10,
    status: 'online',
    type: 'all',
  },
  {
    id: 10,
    name: 'William Jones',
    message: 'Project Manager',
    image: user4,
    status: 'offline',
    type: 'all',
  },
];
const statusColor: Record<Chat['status'], string> = {
  online: 'bg-green-500',
  offline: 'bg-default-950',
  busy: 'bg-danger',
  away: 'bg-default-500',
  default: 'bg-default-500',
};

const Chats = () => {
  return (
    <div className="w-80">
      <div className="card-body">
        <div className="flex justify-between">
          <div className="flex gap-3 items-center">
            <h6 className="card-title">Chats</h6>
          </div>

          <button className="size-8 btn bg-default-150">
            <LuPlus className="size-4 text-default-500 hover:text-primary" />
          </button>
        </div>

        <div className="mt-5 relative">
          <input
            type="email"
            className="ps-11 block w-full form-input form-input-sm"
            placeholder="Search for...."
          />
          <div className="absolute inset-y-0 start-0 flex items-center ps-4">
            <LuSearch className="size-3.5 flex items-center text-default-500" />
          </div>
        </div>
      </div>

      <div className="lg:h-[calc(100vh-310px)] h-[calc(100vh-125px)]" data-simplebar>
        <div className="px-5 mb-1">
          <p className="mb-1 text-default-500 text-sm">Recent Chats</p>
        </div>

        {chats
          .filter(chat => chat.type === 'recent')
          .map(chat => (
            <Link
              key={chat.id}
              to="#"
              className={`flex gap-3 py-2 px-4 ${
                chat.id === 1 ? 'bg-default-200' : 'hover:bg-default-150'
              }`}
            >
              <div className="relative flex items-center justify-center font-semibold rounded-full size-9 bg-default-200">
                {chat.image ? (
                  <img
                    src={chat.image}
                    alt={chat.name}
                    width={36}
                    height={36}
                    className="rounded-full w-9 h-9"
                  />
                ) : (
                  chat.initials
                )}
                <span
                  className={`absolute bottom-0 right-0 w-2.5 h-2.5 border-2 border-default-50 rounded-full ${statusColor[chat.status]}`}
                ></span>
              </div>

              <div className="flex-grow">
                <h6 className="mb-1 text-default-800 font-semibold text-sm">{chat.name}</h6>
                <p className="text-xs truncate text-default-500">{chat.message}</p>
              </div>

              {chat.time && <small className="text-xs text-default-500">{chat.time}</small>}
            </Link>
          ))}

        <div className="px-5 pt-2">
          <p className="mb-1 text-default-500 text-sm">All Conversion</p>
        </div>

        {chats
          .filter(chat => chat.type === 'all')
          .map(chat => (
            <Link key={chat.id} to="#" className="flex gap-3 py-2 px-4 hover:bg-default-150">
              <div className="relative flex items-center justify-center font-semibold rounded-full size-9 bg-default-200">
                {chat.image ? (
                  <img
                    src={chat.image}
                    alt={chat.name}
                    width={36}
                    height={36}
                    className="rounded-full w-9 h-9"
                  />
                ) : (
                  chat.initials
                )}
                <span
                  className={`absolute bottom-0 right-0 w-2.5 h-2.5 border-2 border-default-50 rounded-full ${statusColor[chat.status]}`}
                ></span>
              </div>

              <div>
                <h6 className="mb-1 text-default-800 font-semibold text-sm">{chat.name}</h6>
                <p className="text-xs truncate text-default-500">{chat.message}</p>
              </div>
            </Link>
          ))}
      </div>
    </div>
  );
};

export default Chats;
