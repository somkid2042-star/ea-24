import dashboardImg from '@/assets/images/email-dashboard.png';
import { Link } from 'react-router';

const ComposeEmail = () => {
  return (
    <div className="col-span-1">
      <div className="card">
        <div className="card-body">
          <h4 className="mb-3.5 text-default-800 text-xl leading-relaxed font-semibold">
            Experience Our Fresh Email Composition Interface
          </h4>
          <p className="mb-5 text-default-500">
            A local-part, the symbol @, and a domain, which may be a domain name or an IP address
            enclosed in brackets.
          </p>
          <Link to="/mailbox" className="mb-3 btn bg-primary text-white transition-all">
            Compose Email
          </Link>

          <div className="flex justify-end">
            <img src={dashboardImg} alt="" className="-scale-x-100 h-48" />
          </div>
        </div>
      </div>
    </div>
  );
};

export default ComposeEmail;
