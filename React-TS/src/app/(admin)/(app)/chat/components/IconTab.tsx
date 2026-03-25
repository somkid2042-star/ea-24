import logoSm from '@/assets/images/logo-sm.png';
import avatar01 from '@/assets/images/user/avatar-1.png';
import {
  LuBot,
  LuMessagesSquare,
  LuScrollText,
  LuSettings,
  LuSquareUser,
  LuUser,
} from 'react-icons/lu';
import { Link } from 'react-router';

const IconTab = () => {
  return (
    <div className="card-body flex flex-col justify-between">
      <Link to="#">
        <img src={logoSm} alt="logo" className="h-8 mx-auto" width={32} />
      </Link>

      <div className="flex flex-col items-center gap-6 pt-10">
        <button className="btn size-9 hover:bg-primary/10 hover:text-primary transition-all">
          <LuMessagesSquare className="size-5" />
        </button>
        <button className="btn size-9 hover:bg-primary/10 hover:text-primary transition-all">
          <LuSquareUser className="size-5" />
        </button>
        <button className="btn size-9 hover:bg-primary/10 hover:text-primary transition-all">
          <LuBot className="size-5" />
        </button>
        <button className="btn size-9 hover:bg-primary/10 hover:text-primary transition-all">
          <LuUser className="size-5" />
        </button>
        <button className="btn size-9 hover:bg-primary/10 hover:text-primary transition-all">
          <LuScrollText className="size-5" />
        </button>
      </div>

      <div className="flex flex-col items-center gap-4">
        <button className="btn size-9 hover:bg-primary/10 hover:text-primary transition-all">
          <LuSettings className="size-5" />
        </button>

        <div className="hs-dropdown relative">
          <button
            type="button"
            className="hs-dropdown-toggle flex justify-center items-center"
            aria-haspopup="menu"
            aria-expanded="false"
            aria-label="Dropdown"
            hs-dropdown-placement="top-end"
          >
            <img
              src={avatar01}
              alt="avatar"
              className="rounded-md bg-pink-500/10 size-12 object-cover"
            />
          </button>

          <div className="hs-dropdown-menu" role="menu">
            <Link
              className="flex items-center gap-x-3.5 py-1.5 font-medium px-3 text-sm text-default-600 hover:bg-default-150 rounded"
              to="#"
            >
              Logout
            </Link>

            <Link
              className="flex items-center gap-x-3.5 py-1.5 font-medium px-3 text-sm text-default-600 hover:bg-default-150 rounded"
              to="#"
            >
              Switch Account
            </Link>
          </div>
        </div>
      </div>
    </div>
  );
};

export default IconTab;
