import avatar2 from '@/assets/images/user/avatar-2.png';
import avatar4 from '@/assets/images/user/avatar-4.png';
import avatar7 from '@/assets/images/user/avatar-7.png';
import avatar9 from '@/assets/images/user/avatar-9.png';
import { LuStar } from 'react-icons/lu';
import { Link } from 'react-router';
import { Autoplay, Navigation, Pagination } from 'swiper/modules';
import { Swiper, SwiperSlide } from 'swiper/react';

type Testimonial = {
  id: number;
  name: string;
  review: string;
  avatar: string;
  bgColor: string;
  rating: number;
};

const testimonials: Testimonial[] = [
  {
    id: 1,
    name: 'Anthony Hobbs',
    review:
      'ThemesDesign used Anydesk to fix the bug in Flask and Django version. I highly recommend this product!',
    avatar: avatar9,
    bgColor: 'bg-purple-500/10',
    rating: 5,
  },
  {
    id: 2,
    name: 'Angela Ulligan',
    review:
      'The best templates which support multiple programming languages with beautiful designs. Thank you for the valuable template.',
    avatar: avatar2,
    bgColor: 'bg-primary/10',
    rating: 5,
  },
  {
    id: 3,
    name: 'muratoztrkk01',
    review:
      'I encountered a few errors in the product detail page design in Angular. The support team fixed everything quickly.',
    avatar: avatar4,
    bgColor: 'bg-amber-500/10',
    rating: 5,
  },
  {
    id: 4,
    name: 'Christine Marbury',
    review:
      "This theme is very good. I really recommend it. It's optimized, elegant, and well documented.",
    avatar: avatar7,
    bgColor: 'bg-danger/10',
    rating: 5,
  },
];

const Customer = () => {
  return (
    <section id="Feedback" className="relative lg:pb-28 md:pb-18 pb-12">
      <div className="container">
        <div className="mx-auto md:mb-8 text-center lg:w-3xl">
          <h1 className="leading-normal capitalize md:text-4xl text-3xl font-semibold text-default-800">
            What Our Customer Says
          </h1>
        </div>

        <Swiper
          modules={[Navigation, Pagination, Autoplay]}
          slidesPerView={3}
          spaceBetween={30}
          loop={true}
          pagination={{
            el: '.swiper-pagination',
            clickable: true,
          }}
          navigation={{
            nextEl: '.swiper-button-next',
            prevEl: '.swiper-button-prev',
          }}
          autoplay={{
            delay: 2500,
            disableOnInteraction: false,
          }}
          breakpoints={{
            1440: {
              slidesPerView: 3,
              spaceBetween: 20,
            },
            768: {
              slidesPerView: 2,
              spaceBetween: 40,
            },
            375: {
              slidesPerView: 1,
              spaceBetween: 50,
            },
          }}
        >
          {testimonials.map(t => (
            <SwiperSlide key={t.id}>
              <div className="p-5 text-center" data-aos="fade-up" data-aos-easing="linear">
                <div className={`mx-auto rounded-full size-20 ${t.bgColor}`}>
                  <img src={t.avatar} alt={t.name} className="rounded-full size-20" />
                </div>

                <p className="mt-6 text-default-600 text-base">"{t.review}"</p>

                <h6 className="mt-4 mb-2 text-base text-default-900 font-semibold">
                  <Link to="#">{t.name}</Link>
                </h6>

                <div className="text-yellow-500 flex items-center justify-center gap-1">
                  {Array.from({ length: t.rating }).map((_, i) => (
                    <LuStar key={i} className="size-3.5 fill-yellow-500" />
                  ))}
                </div>
              </div>
            </SwiperSlide>
          ))}
        </Swiper>
        <div className="swiper-pagination"></div>
      </div>
    </section>
  );
};

export default Customer;
