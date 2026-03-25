import img16 from '@/assets/images/landing/img-16.png';
import img17 from '@/assets/images/landing/img-17.png';
import img18 from '@/assets/images/landing/img-18.png';
import img19 from '@/assets/images/landing/img-19.png';
import { LuStar } from 'react-icons/lu';

type ProductItem = {
  id: number;
  name: string;
  price: number;
  rating: number;
  image: string;
};

const products: ProductItem[] = [
  {
    id: 1,
    name: 'Green Sneakers Skate',
    price: 299.99,
    rating: 4.8,
    image: img16,
  },
  {
    id: 2,
    name: 'Nike Running Shoes',
    price: 129.49,
    rating: 4.4,
    image: img17,
  },
  {
    id: 3,
    name: 'Nike Air Max Sneakers Shoe',
    price: 149.99,
    rating: 4.9,
    image: img18,
  },
  {
    id: 4,
    name: 'Dunk Sneakers Skate Shoe',
    price: 174.65,
    rating: 4.6,
    image: img19,
  },
];

const Product = () => {
  return (
    <section id="product" className="relative lg:py-32 py-20">
      <div className="container">
        <div className="lg:w-3xl mx-auto text-center">
          <h1 className="leading-normal capitalize text-4xl font-semibold text-default-800">
            Our Latest Product
          </h1>
        </div>

        <div className="grid lg:grid-cols-4 md:grid-cols-2 grid-cols-1 gap-5 mt-12">
          {products.map(product => (
            <div
              key={product.id}
              className="card bg-gradient-to-b from-default-100 to-default-50/40 shadow-none rounded-md"
            >
              <div className="card-body">
                <img
                  src={product.image}
                  alt={product.name}
                  className="mx-auto h-52 object-contain"
                />

                <div className="mt-3">
                  <p className="mb-3 flex items-center gap-1 text-sm">
                    <LuStar className="text-amber-500 size-4" />({product.rating})
                  </p>

                  <h5 className="text-lg font-semibold text-default-800">{product.name}</h5>

                  <div className="flex justify-between items-center mt-3">
                    <h6 className="text-base font-semibold text-default-800">
                      ${product.price.toFixed(2)}
                    </h6>
                    <button type="button" className="btn btn-sm bg-primary text-white">
                      Add to Cart
                    </button>
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
};

export default Product;
