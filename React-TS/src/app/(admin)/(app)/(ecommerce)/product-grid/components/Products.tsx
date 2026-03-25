import product01 from '@/assets/images/product/img-01.png';
import product02 from '@/assets/images/product/img-02.png';
import product03 from '@/assets/images/product/img-03.png';
import product04 from '@/assets/images/product/img-04.png';
import product05 from '@/assets/images/product/img-05.png';
import product06 from '@/assets/images/product/img-06.png';
import product08 from '@/assets/images/product/img-08.png';
import product10 from '@/assets/images/product/img-10.png';

import {
  LuChevronDown,
  LuChevronLeft,
  LuChevronRight,
  LuEllipsis,
  LuEye,
  LuHeart,
  LuLayoutGrid,
  LuList,
  LuShoppingCart,
  LuSquarePen,
  LuStar,
  LuStarHalf,
  LuTrash2,
  LuX,
} from 'react-icons/lu';
import { Link } from 'react-router';

type Product = {
  id: number;
  name: string;
  image: string;
  rating: number;
  reviews: number;
  price: number;
  originalPrice: number | null;
  isFavorite: boolean;
};

const Products = () => {
  const products: Product[] = [
    {
      id: 1,
      name: 'Mesh Ergonomic Black Chair',
      image: product02,
      rating: 4.5,
      reviews: 198,
      price: 674.12,
      originalPrice: 784.09,
      isFavorite: true,
    },
    {
      id: 2,
      name: 'Fastcolors Typography Men',
      image: product03,
      rating: 4.5,
      reviews: 1150,
      price: 341.99,
      originalPrice: 784.09,
      isFavorite: false,
    },
    {
      id: 3,
      name: 'Mesh Ergonomic Green Chair',
      image: product04,
      rating: 3.5,
      reviews: 29,
      price: 362.2,
      originalPrice: 599.99,
      isFavorite: false,
    },
    {
      id: 4,
      name: 'Techel Black Bluetooth Sound.',
      image: product05,
      rating: 4.5,
      reviews: 1324,
      price: 249.99,
      originalPrice: 399.99,
      isFavorite: true,
    },
    {
      id: 5,
      name: 'Bovet Fleurier AIFSQ029',
      image: product06,
      rating: 4.5,
      reviews: 1324,
      price: 496.16,
      originalPrice: null,
      isFavorite: false,
    },
    {
      id: 6,
      name: 'Roar Twill Blue Baseball Cap',
      image: product08,
      rating: 2.5,
      reviews: 485,
      price: 674.12,
      originalPrice: 784.99,
      isFavorite: true,
    },
    {
      id: 7,
      name: 'Smartest Printed T-shirt',
      image: product01,
      rating: 3.5,
      reviews: 5321,
      price: 89.99,
      originalPrice: null,
      isFavorite: false,
    },
    {
      id: 8,
      name: 'Crop tops for Women western.',
      image: product10,
      rating: 4.5,
      reviews: 1551,
      price: 145,
      originalPrice: 299.99,
      isFavorite: true,
    },
  ];

  const renderStars = (rating: number) => {
    const stars = [];
    const fullStars = Math.floor(rating);
    const hasHalfStar = rating % 1 !== 0;

    for (let i = 1; i <= 5; i++) {
      if (i <= fullStars) {
        stars.push(<LuStar key={i} className="size-4 fill-yellow-500 text-yellow-500" />);
      } else if (i === fullStars + 1 && hasHalfStar) {
        stars.push(<LuStarHalf key={i} className="size-4 fill-yellow-500 text-yellow-500" />);
      } else {
        stars.push(<LuStar key={i} className="size-4 text-yellow-500" />);
      }
    }

    return stars;
  };
  return (
    <div className="lg:col-span-3 col-span-1">
      <div className="flex justify-between gap-2 flex-wrap items-center">
        <p className="text-default-700 text-sm">
          Showing all <b>7,410</b> items results
        </p>

        <div className="flex gap-2 items-center">
          <div className="hs-dropdown relative inline-flex">
            <button
              type="button"
              className="hs-dropdown-toggle inline-flex items-center btn btn-sm bg-transparent border border-primary text-primary transition-all duration-300 hover:bg-primary hover:text-white"
              aria-haspopup="menu"
              aria-expanded="false"
              aria-label="Dropdown"
            >
              Sort by: <b className="font-medium ml-1">Highest Price</b>
              <LuChevronDown className="size-4 ms-2" />
            </button>
            <div
              className="hs-dropdown-menu transition-[opacity,margin] duration hs-dropdown-open:opacity-100 opacity-0 hidden min-w-40 card z-30 mt-2 p-2 text-sm"
              role="menu"
            >
              <Link
                className="flex items-center gap-x-3.5 py-2 font-medium px-4 text-default-600 hover:bg-default-150 rounded"
                to=""
              >
                Lowest Price
              </Link>
              <Link
                className="flex items-center gap-x-3.5 py-2 font-medium px-4 text-default-600 hover:bg-default-150 rounded"
                to=""
              >
                Highest Price
              </Link>
              <Link
                className="flex items-center gap-x-3.5 py-2 font-medium px-4 text-default-600 hover:bg-default-150 rounded"
                to=""
              >
                High to Low
              </Link>
              <hr className="border-t border-default-200 my-2 -mx-2" />
              <Link
                className="flex items-center gap-x-3.5 py-2 font-medium px-4 text-default-600 hover:bg-default-150 rounded"
                to=""
              >
                Low to High
              </Link>
            </div>
          </div>

          <nav
            className="flex gap-x-1"
            aria-label="Tabs"
            role="tablist"
            aria-orientation="horizontal"
          >
            <button
              type="button"
              className="hs-tab-active:font-semibold hs-tab-active:bg-sky-600 hs-tab-active:text-white btn size-7.5 bg-sky-100 text-sky-500 hover:text-white hover:bg-sky-600"
              id="items-1"
              aria-selected="false"
              data-hs-tab="item-1"
              aria-controls="item-1"
              role="tab"
            >
              <LuList className="size-4" />
            </button>

            <button
              type="button"
              className="hs-tab-active:font-semibold hs-tab-active:bg-sky-600 hs-tab-active:text-white btn size-7.5 bg-sky-100 text-sky-500 hover:text-white hover:bg-sky-600 active"
              id="items-2"
              aria-selected="true"
              data-hs-tab="#item-2"
              aria-controls="item-2"
              role="tab"
            >
              <LuLayoutGrid className="size-4" />
            </button>
          </nav>
        </div>
      </div>

      <div className="flex items-center mt-3 gap-3">
        <span className="flex items-center gap-1 rounded-full px-2.5 py-0.75 border border-default-200 text-xs">
          High to Low
          <Link to="#" className="align-middle transition-al duration-300">
            <LuX className="size-3" />
          </Link>
        </span>

        <span className="flex items-center gap-1 rounded-full px-2.5 py-0.75 border border-default-200 text-xs">
          New
          <Link to="#" className="align-middle transition-al duration-300">
            <LuX className="size-3" />
          </Link>
        </span>

        <Link
          to="#"
          className="py-0.75 px-2.5 text-xs rounded-md transition-all duration-300 hover:bg-default-150"
        >
          All Clear
        </Link>
      </div>

      <div className="grid lg:grid-cols-4 md:grid-cols-2 grid-cols-1 gap-5 mt-5">
        {products.map(product => (
          <div key={product.id} className="card">
            <div className="card-body relative">
              <img src={product.image} alt={product.name} />
              <LuHeart
                className={`size-5 absolute top-6 end-6 ${product.isFavorite ? 'text-danger fill-danger/15' : 'text-default-500 fill-default-100'}`}
              />
            </div>

            <div className="pb-5 px-5">
              <h6 className="text-base text-default-800 font-semibold hover:text-primary transition-all mb-2">
                <Link to="#">{product.name}</Link>
              </h6>

              <div className="flex items-center gap-1">
                <div className="flex items-center gap-0.25">{renderStars(product.rating)}</div>
                <span className="text-default-500">({product.reviews})</span>
              </div>

              <h5 className="mt-4 text-base font-semibold text-default-800">
                ${product.price.toFixed(2)}
                {product.originalPrice && (
                  <small className="line-through font-medium text-default-500 ml-1">
                    {product.originalPrice.toFixed(2)}
                  </small>
                )}
              </h5>

              <div className="flex items-center gap-2 mt-4">
                <button className="border border-default-600 w-full text-default-500 border-dashed btn">
                  <LuShoppingCart className="size-3 mr-1" />
                  Add to Cart
                </button>

                <div className="hs-dropdown relative inline-flex">
                  <button
                    type="button"
                    className="hs-dropdown-toggle btn size-9 bg-default-200 hover:bg-default-600 text-default-500 hover:text-white"
                    aria-haspopup="menu"
                    aria-expanded="false"
                    aria-label="Dropdown"
                  >
                    <LuEllipsis className="size-4" />
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

      <div className="flex flex-wrap md:justify-between justify-center md:gap-0 gap-4 mt-5">
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
            Next <LuChevronRight className="size-4 ms-1" />
          </button>
        </nav>
      </div>
    </div>
  );
};

export default Products;
