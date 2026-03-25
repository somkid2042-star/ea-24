import avatar11 from '@/assets/images/user/avatar-11.png';
import avatar02 from '@/assets/images/user/avatar-2.png';
import avatar5 from '@/assets/images/user/avatar-5.png';
import avatar8 from '@/assets/images/user/avatar-8.png';

import { Link } from 'react-router';
import {
  LuEllipsis,
  LuSquarePen,
  LuStar,
  LuStarHalf,
  LuThumbsDown,
  LuThumbsUp,
  LuTrash2,
} from 'react-icons/lu';

type RatingBar = {
  stars: number;
  percentage: number;
  count: number;
  color: string;
};

type Review = {
  id: number;
  name: string;
  avatar: string;
  date: string;
  rating: number;
  text: string;
  likes: number;
  dislikes: number;
  bgColor: string;
};

const Ratings = () => {
  const averageRating = 4.8;
  const totalRatings = 4213;

  const ratingBars: RatingBar[] = [
    { stars: 5, percentage: 79, count: 1210, color: 'bg-success' },
    { stars: 4, percentage: 66, count: 1174, color: 'bg-secondary' },
    { stars: 3, percentage: 45, count: 762, color: 'bg-info' },
    { stars: 2, percentage: 22, count: 274, color: 'bg-warning' },
    { stars: 1, percentage: 5, count: 32, color: 'bg-danger' },
  ];

  const reviews: Review[] = [
    {
      id: 1,
      name: 'Aubrey Beer',
      avatar: avatar02,
      date: '14 Jan, 2024',
      rating: 4.5,
      text: 'Nice product good quality and looking',
      likes: 15,
      dislikes: 3,
      bgColor: 'bg-sky-50',
    },
    {
      id: 2,
      name: 'Theodora Jones',
      avatar: avatar11,
      date: '20 July, 2023',
      rating: 4,
      text: 'Amazing! Fast, to the point, professional and really amazing to work with them!!!',
      likes: 77,
      dislikes: 26,
      bgColor: 'bg-default-200',
    },
    {
      id: 3,
      name: 'Jordane Dare',
      avatar: avatar5,
      date: '07 Dec, 2023',
      rating: 5,
      text: 'Very nice design. Clean Code and easy customizable',
      likes: 31,
      dislikes: 9,
      bgColor: 'bg-yellow-100',
    },
    {
      id: 4,
      name: 'Avern Ratke',
      avatar: avatar8,
      date: '10 Aug, 2023',
      rating: 4.5,
      text: 'The best templates which is supported multiple programming languages with beautiful templates. thank you for the valuable template.',
      likes: 49,
      dislikes: 17,
      bgColor: 'bg-green-100',
    },
  ];

  const renderStars = (rating: number) => {
    const stars = [];
    for (let i = 1; i <= 5; i++) {
      if (i <= Math.floor(rating)) {
        stars.push(<LuStar key={i} className="size-3.5 fill-yellow-500" />);
      } else if (i - 0.5 === rating) {
        stars.push(<LuStarHalf key={i} className="size-3.5 fill-yellow-500" />);
      } else {
        stars.push(<LuStar key={i} className="size-3.5 text-default-300" />);
      }
    }
    return stars;
  };

  return (
    <>
      <h6 className="mt-5 mb-3 card-title">Ratings & Reviews</h6>
      <div className="grid lg:grid-cols-3 grid-cols-1 gap-5">
        <div className="col-span-1">
          <div className="card-body border border-dashed border-default-200 rounded-md">
            <div className="text-center">
              <h5 className="mb-2 text-base font-semibold text-default-800">Customer Ratings</h5>
              <span className="px-3.5 py-1.5 text-default-500 inline-flex gap-3 text-xs font-medium rounded-full border bg-default-100 border-default-200">
                <span className="flex items-center gap-2 text-yellow-500">
                  {renderStars(averageRating)}
                </span>
                ({averageRating} out of 5)
              </span>
              <p className="mt-2 text-[13px] text-default-500">{totalRatings} total ratings</p>
            </div>

            <div className="flex flex-col gap-3 mt-4">
              {ratingBars.map((bar, idx) => (
                <div key={idx} className="flex items-center gap-3">
                  <div className="flex items-center text-default-800 text-[13px]">
                    {bar.stars}{' '}
                    <LuStar className="size-3.25 fill-yellow-500 ms-1 text-yellow-500" />
                  </div>
                  <div className="w-full h-1.5 rounded-full bg-default-200">
                    <div
                      className={`h-1.5 rounded-full ${bar.color}`}
                      style={{ width: `${bar.percentage}%` }}
                    ></div>
                  </div>
                  <div className="text-end w-10 text-default-800 text-[13px]">{bar.count}</div>
                </div>
              ))}
            </div>
          </div>
        </div>

        <div className="lg:col-span-2 col-span-1 flex flex-col gap-4">
          <div className="flex justify-between items-center gap-5">
            <h6 className="text-default-800 font-semibold text-[15px]">Reviews</h6>
            <button className="text-white btn btn-sm btn-primary">Add Review</button>
          </div>

          {reviews.map(review => (
            <div key={review.id} className="mt-3 pt-3 border-t border-default-200">
              <div className="flex justify-between items-center gap-5">
                <div className="flex gap-3 items-center">
                  <div className={`${review.bgColor} rounded-full`}>
                    <img
                      src={review.avatar}
                      alt={review.name}
                      className="h-10 rounded-full"
                      width={40}
                    />
                  </div>
                  <div>
                    <h6 className="card-title">
                      <Link to="#">{review.name}</Link>
                    </h6>
                    <p className="text-[13px] text-default-500">{review.date}</p>
                  </div>
                </div>

                <div className="hs-dropdown relative inline-flex">
                  <button
                    type="button"
                    className="hs-dropdown-toggle flex justify-center items-center size-7.5 text-sm font-semibold rounded-md bg-default-100 hover:bg-default-600 text-default-500 hover:text-white"
                    aria-haspopup="menu"
                    aria-expanded="false"
                    aria-label="Dropdown"
                    hs-dropdown-placement="bottom-end"
                  >
                    <LuEllipsis className="size-4" />
                  </button>
                  <div className="hs-dropdown-menu" role="menu">
                    <Link
                      className="flex items-center gap-1.5 py-1.5 font-medium px-3 text-sm text-default-500 hover:bg-default-150 rounded"
                      to="#"
                    >
                      <LuSquarePen className="size-3" /> Edit
                    </Link>
                    <Link
                      className="flex items-center gap-1.5 py-1.5 font-medium px-3 text-sm text-default-500 hover:bg-default-150 rounded"
                      to="#"
                    >
                      <LuTrash2 className="size-3" /> Delete
                    </Link>
                  </div>
                </div>
              </div>

              <div className="flex items-center gap-2 mt-4 mb-2 text-yellow-500">
                {renderStars(review.rating)}
              </div>
              <p className="text-default-500 text-sm">"{review.text}"</p>

              <div className="flex items-center gap-3 mt-3">
                <Link to="#" className="text-success flex items-center gap-1.25">
                  <LuThumbsUp className="size-3" />
                  <span className="text-sm">{review.likes}</span>
                </Link>

                <Link to="#" className="text-danger flex items-center gap-1.25">
                  <LuThumbsDown className="size-3" />
                  <span className="text-sm">{review.dislikes}</span>
                </Link>
              </div>
            </div>
          ))}
        </div>
      </div>
    </>
  );
};

export default Ratings;
