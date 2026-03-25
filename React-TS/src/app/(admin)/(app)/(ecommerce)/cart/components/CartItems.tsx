import product01 from '@/assets/images/product/img-01.png';
import product04 from '@/assets/images/product/img-04.png';
import product08 from '@/assets/images/product/img-08.png';
import { useState } from 'react';
import { LuMinus, LuPlus, LuTrash2 } from 'react-icons/lu';
import { Link } from 'react-router';

type CartItem = {
  id: number;
  name: string;
  category: string;
  color: string;
  size: string;
  img: string;
  price: number;
  oldPrice?: number;
  quantity: number;
};

const initialCartItems: CartItem[] = [
  {
    id: 1,
    name: 'Roar Twill Blue Baseball Cap',
    category: "Men's Fashion",
    color: 'White/Blue',
    size: 'L',
    img: product08,
    price: 149.99,
    oldPrice: 299.99,
    quantity: 2,
  },
  {
    id: 2,
    name: 'Mesh Ergonomic Green Chair',
    category: 'Home, Kitchen, Pets',
    color: 'Green/Blue',
    size: 'M',
    img: product04,
    price: 362.21,
    oldPrice: 599.99,
    quantity: 2,
  },
  {
    id: 3,
    name: 'Smartest Printed T-shirt',
    category: 'Unisex Fashion',
    color: 'Black/Blue',
    size: 'M',
    img: product01,
    price: 89.99,
    quantity: 2,
  },
];

const CartItems = () => {
  const [cartItems, setCartItems] = useState(initialCartItems);

  const updateQuantity = (id: number, change: number) => {
    setCartItems(items =>
      items.map(item =>
        item.id === id ? { ...item, quantity: Math.max(1, item.quantity + change) } : item
      )
    );
  };

  return (
    <div className="lg:col-span-3 col-span-1">
      <div className="flex justify-between gap-5 items-center mb-5">
        <h5 className="text-base text-default-800 font-semibold underline">
          Shopping Cart ({cartItems.length})
        </h5>

        <button className="flex items-center gap-1.25 text-danger">
          <LuTrash2 className="size-4" />
          <span className="text-sm">Delete All</span>
        </button>
      </div>

      {cartItems.map(item => (
        <div key={item.id} className="card p-5 mb-5">
          <div className="grid lg:grid-cols-12 grid-cols-1 gap-5">
            <div className="lg:col-span-2 col-span-1">
              <div className="p-4 rounded-md bg-default-150 flex justify-center">
                <img src={item.img} alt={item.name} />
              </div>
            </div>

            <div className="lg:col-span-3 col-span-1 flex flex-col justify-between">
              <div>
                <h5 className="mb-1 text-base text-default-800 font-semibold">
                  <Link to="/product-overviewp">{item.name}</Link>
                </h5>
                <p className="mb-2 text-default-500 text-sm">
                  <Link to="#">{item.category}</Link>
                </p>
                <p className="mb-1 text-default-500 text-sm">
                  Color: <span className="text-default-800">{item.color}</span>
                </p>
                <p className="mb-3 text-default-500 text-sm">
                  Size: <span className="text-default-800">{item.size}</span>
                </p>
              </div>

              <div className="flex items-center gap-2">
                <div className="inline-flex p-2 text-center border border-default-200 rounded">
                  <button
                    type="button"
                    className="size-7 btn bg-default-200"
                    onClick={() => updateQuantity(item.id, -1)}
                  >
                    <LuMinus className="size-4 text-default-500" />
                  </button>

                  <input
                    className="text-center w-15 h-7 border-0 ring-0 bg-transparent"
                    value={item.quantity}
                    readOnly
                  />

                  <button
                    type="button"
                    className="size-7 btn bg-default-200"
                    onClick={() => updateQuantity(item.id, 1)}
                  >
                    <LuPlus className="size-4 text-default-500" />
                  </button>
                </div>

                <button
                  type="button"
                  className="size-9.5 rounded bg-danger/15 justify-center items-center inline-flex text-danger hover:bg-danger hover:text-white transition-all duration-300"
                  aria-haspopup="dialog"
                  aria-expanded="false"
                  aria-controls="cart-item-delete-modal"
                  data-hs-overlay="#cart-item-delete-modal"
                >
                  <LuTrash2 className="size-4" />
                </button>
              </div>
            </div>

            <div className="lg:col-span-7 col-span-1 flex lg:justify-end">
              <div className="flex lg:flex-col flex-row w-full justify-between">
                <h6 className="text-base text-end text-default-800 font-semibold">
                  ${item.price.toFixed(2)}{' '}
                  {item.oldPrice && (
                    <small className="font-normal line-through text-default-500">
                      ${item.oldPrice.toFixed(2)}
                    </small>
                  )}
                </h6>

                <h6 className="text-base text-end text-default-800 font-semibold">
                  ${(item.price * item.quantity).toFixed(2)}
                </h6>
              </div>
            </div>
          </div>
        </div>
      ))}
    </div>
  );
};

export default CartItems;
