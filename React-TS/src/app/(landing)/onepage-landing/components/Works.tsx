import { Link } from 'react-router';
import chat from '@/assets/images/landing/chat.jpg';
import email from '@/assets/images/landing/email.jpg';
import order from '@/assets/images/landing/order-overview.jpg';
import { LuMoveRight } from 'react-icons/lu';

type WorkCard = {
  id: number;
  image: string;
  tag: string;
  tagColor: string;
  title: string;
  description: string;
  link: string;
};

type StatItem = {
  id: number;
  value: number | string;
  suffix?: string;
  label: string;
};

const workCards: WorkCard[] = [
  {
    id: 1,
    image: chat,
    tag: 'Popular Apps',
    tagColor: 'border-primary/30 bg-primary/15 text-primary',
    title: 'Chat with Client & Employee',
    description:
      'A chat UI, or user interface, is one of the first things users see when using a web or mobile application to communicate.',
    link: '#',
  },
  {
    id: 2,
    image: email,
    tag: 'Email Apps',
    tagColor: 'border-secondary/30 bg-secondary/15 text-secondary',
    title: 'Exciting New Features Await You',
    description:
      'A chat UI, or user interface, is one of the first things users see when using a web or mobile application to communicate.',
    link: '#',
  },
  {
    id: 3,
    image: order,
    tag: 'HR Management',
    tagColor: 'border-danger/20 bg-danger/15 text-danger',
    title: 'Unleash Your Creativity with Our Latest Tools',
    description:
      'A chat UI, or user interface, is one of the first things users see when using a web or mobile application to communicate.',
    link: '#',
  },
];

const stats: StatItem[] = [
  { id: 1, value: 4, suffix: '+', label: 'Multiple Layouts' },
  { id: 2, value: 12, suffix: '+', label: 'Multi Languages' },
  { id: 3, value: 7, suffix: '+', label: 'Apps & Dashboard' },
  { id: 4, value: 4, suffix: '+', label: 'Multiple Modes' },
  { id: 5, value: 36500, suffix: '+', label: 'Happy Customers' },
];

const Works = () => {
  return (
    <section className="relative z-20 pb-32 bg-default-100 dark:bg-default-950">
      <div className="container">
        <div className="grid lg:grid-cols-3 gap-6">
          {workCards.map((card, index) => (
            <div
              key={card.id}
              className={`card rounded-md shadow-md transition-all duration-300 hover:-translate-y-2 ${
                index === 0 ? '-mt-36' : 'lg:-mt-36'
              }`}
            >
              <div className="card-body">
                <div className="flex flex-col gap-y-6">
                  <img
                    src={card.image}
                    alt={card.title}
                    width={400}
                    height={250}
                    className="rounded-md shadow"
                  />
                  <div>
                    <span
                      className={`inline-flex items-center py-0.5 px-2.5 rounded text-xs font-medium border ${card.tagColor}`}
                    >
                      {card.tag}
                    </span>

                    <h6 className="text-lg font-semibold mt-3 mb-2 text-default-800">
                      <Link to={card.link}>{card.title}</Link>
                    </h6>

                    <p className="mb-3 text-base text-default-500">{card.description}</p>

                    <Link
                      to={card.link}
                      className="text-primary text-base flex items-center gap-1.5"
                    >
                      Read More
                      <LuMoveRight className="size-4" />
                    </Link>
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>

        <div className="p-10 rounded-md mt-20 bg-default-900 dark:bg-default-900">
          <div className="grid lg:grid-cols-5 md:grid-cols-2 gap-6">
            {stats.map(stat => (
              <div key={stat.id} className="text-center">
                <h3 className="mb-2 text-white text-2xl font-semibold">
                  <span>{stat.value}</span>
                  {stat.suffix}
                </h3>
                <p className="text-base text-default-500">{stat.label}</p>
              </div>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
};

export default Works;
