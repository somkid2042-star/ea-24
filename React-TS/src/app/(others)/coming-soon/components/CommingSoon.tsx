import AuthBgDark from '@/assets/images/auth-bg-dark.jpg';
import AuthBg from '@/assets/images/auth-bg.jpg';
import LogoDark from '@/assets/images/logo-dark.png';
import LogoLight from '@/assets/images/logo-light.png';
import Countdown, { type CountdownRenderProps } from 'react-countdown';
import { Link } from 'react-router';

const CountdownRenderer = ({ days, hours, minutes, seconds, completed }: CountdownRenderProps) => {
  if (completed) {
    return <span id="end">00:00:00:00</span>;
  }
  return (
    <div className="flex items-center justify-between mt-14 w-full gap-4">
      <div className="p-6 bg-default-150/75 rounded flex items-center justify-center">
        <div className="text-center">
          <span className="text-2xl">{days}</span>
          <p>Days</p>
        </div>
      </div>
      <div className="p-6 bg-default-150/75 rounded flex items-center justify-center">
        <div className="text-center">
          <span className="text-2xl">{hours}</span>
          <p>Hours</p>
        </div>
      </div>
      <div className="p-6 bg-default-150/75 rounded flex items-center justify-center">
        <div className="text-center">
          <span className="text-2xl">{minutes}</span>
          <p>Minutes</p>
        </div>
      </div>
      <div className="p-6 bg-default-150/75 rounded flex items-center justify-center">
        <div className="text-center">
          <span className="text-2xl">{seconds}</span>
          <p>Seconds</p>
        </div>
      </div>
    </div>
  );
};

const CommingSoon = () => {
  const targetDate = new Date('June 30, 2026 16:37:52');

  return (
    <div className="relative h-screen w-full flex justify-center items-center">
      <div className="absolute inset-0">
        <div className="block dark:hidden h-full w-full">
          <img src={AuthBg} alt="background" className="object-cover" />
        </div>
        <div className="hidden dark:block h-full w-full">
          <img src={AuthBgDark} alt="background dark" className="object-cover" />
        </div>
      </div>

      <div className="relative z-10 bg-default-100/50 rounded-lg w-lg">
        <div className="text-center px-10 py-12">
          <div id="countDownText">
            <Link to="/index" className="flex justify-center">
              <div className="block dark:hidden h-6 relative w-auto">
                <img src={LogoDark} alt="logo dark" className="object-contain" width={111} />
              </div>
              <div className="hidden dark:block h-6 relative w-auto">
                <img src={LogoLight} alt="logo light" className="object-contain" width={111} />
              </div>
            </Link>

            <div className="mt-8 text-center">
              <h4 className="mb-2 text-purple-500 text-xl font-semibold">Coming Soon ...</h4>
              <p className="mb-6 text-base text-default-500">We'll be here in a brief moment.</p>
            </div>

            <Countdown date={targetDate} renderer={CountdownRenderer} />

            <div className="mt-10 text-center">
              <h5 className="text-lg font-semibold text-default-800 mb-2">
                Be alerted when our launch happens.
              </h5>
              <p className="mb-5 text-base text-default-500">
                Don't worry, we won't inundate your inbox 😊
              </p>

              <form action="#">
                <div className="flex w-full relative mb-6 lg:mt-0 mt-4">
                  <input
                    type="email"
                    placeholder="Enter your email"
                    className="form-input bg-default-50"
                  />
                  <button
                    type="button"
                    className="absolute right-0 m-1 top-0 btn bg-primary text-white btn-sm"
                  >
                    Send
                  </button>
                </div>
              </form>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default CommingSoon;
