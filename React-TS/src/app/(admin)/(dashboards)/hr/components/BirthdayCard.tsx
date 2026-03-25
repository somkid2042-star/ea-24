import birthdayImg from '@/assets/images/birthday.png';
import dashboardBg from '@/assets/images/hr-dashboard.png';
import avatar6 from '@/assets/images/user/avatar-6.png';

const BirthdayCard = () => {
  return (
    <div className="relative mb-5 bg-gradient-to-r to-primary/50 from-transparent rounded-md shadow-md">
      <div className="absolute inset-0 opacity-30">
        <img src={dashboardBg} alt="Dashboard background" className="object-cover" />
      </div>

      <div className="relative card-body">
        <div className="flex gap-3 mb-4">
          <div className="bg-purple-500/10 rounded-full size-10 overflow-hidden">
            <img
              src={avatar6}
              alt="Nakisha Short"
              width={40}
              height={40}
              className="h-10 w-10 rounded-full"
            />
          </div>

          <div>
            <h6 className="mb-1 text-sm text-default-800">Nakisha Short</h6>
            <p className="text-default-600">Her Birthday Today</p>
          </div>
        </div>

        <button type="button" className="btn btn-sm bg-primary text-white">
          Wish Her
        </button>
      </div>

      <div className="absolute bottom-0 right-0">
        <img src={birthdayImg} alt="Birthday" />
      </div>
    </div>
  );
};

export default BirthdayCard;
