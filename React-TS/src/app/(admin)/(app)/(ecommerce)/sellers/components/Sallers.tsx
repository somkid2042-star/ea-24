import IconifyIcon from '@/components/client-wrapper/IconifyIcon';
import { LuEllipsis, LuEye, LuHeart, LuSquarePen, LuTrash2 } from 'react-icons/lu';
import { Link } from 'react-router';

type Seller = {
  name: string;
  owner: string;
  sales: string;
  products: number;
  revenue: string;
  heartColor: 'warning' | 'default';
  iconifyIcon: string;
};

const sellers: Seller[] = [
  {
    name: 'Themesdesign',
    owner: 'Paula Keenan',
    sales: '4.5k',
    products: 310,
    revenue: '$235.3k',
    heartColor: 'warning',
    iconifyIcon: 'logos:google-adwords',
  },
  {
    name: 'Nazox Fashion',
    owner: 'Kara Miller',
    sales: '2.3k',
    products: 67,
    revenue: '$235.3k',
    heartColor: 'warning',
    iconifyIcon: 'logos:apple-app-store',
  },
  {
    name: '4xM Infotech',
    owner: 'Daniel Miller',
    sales: '7.1k',
    products: 138,
    revenue: '$465.9k',
    heartColor: 'default',
    iconifyIcon: 'logos:google-gmail',
  },
  {
    name: 'Extra Fashion',
    owner: 'Mark Walton',
    sales: '1.9k',
    products: 49,
    revenue: '$198.3k',
    heartColor: 'warning',
    iconifyIcon: 'logos:android',
  },
  {
    name: 'Nesta Technologies',
    owner: 'William Heineman',
    sales: '4.8k',
    products: 172,
    revenue: '$746.1k',
    heartColor: 'default',
    iconifyIcon: 'logos:figma',
  },
  {
    name: 'Digitech Galaxy',
    owner: 'David Biggs',
    sales: '9.2k',
    products: 674,
    revenue: '$14.4m',
    heartColor: 'default',
    iconifyIcon: 'logos:meta',
  },
  {
    name: 'Zoetic Fashion',
    owner: 'Jaqueline Hammes',
    sales: '1.8k',
    products: 112,
    revenue: '$132.4k',
    heartColor: 'default',
    iconifyIcon: 'logos:google',
  },
  {
    name: 'Force Medicines',
    owner: 'Ashley Uilson',
    sales: '4.1k',
    products: 243,
    revenue: '$861.7k',
    heartColor: 'default',
    iconifyIcon: 'logos:telegram',
  },
];

const Sallers = () => {
  return (
    <div className="grid lg:grid-cols-4 md:grid-cols-2 grid-cols-1 gap-5">
      {sellers.map((seller, index) => (
        <div key={index} className="card">
          <div className="card-body">
            <div className="flex justify-between gap-5 items-center mb-4">
              <LuHeart
                className={`size-5 ${
                  seller.heartColor === 'warning'
                    ? 'text-warning fill-warning/10'
                    : 'text-default-500 fill-default-100'
                }`}
              />

              <div className="hs-dropdown relative inline-flex">
                <button
                  type="button"
                  className="hs-dropdown-toggle btn size-7.5 bg-default-200 hover:bg-default-600 text-default-500 hover:text-white"
                  aria-haspopup="menu"
                  aria-expanded="false"
                  aria-label="Dropdown"
                  hs-dropdown-placement="bottom-end"
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

            <div className="flex items-center justify-center mx-auto rounded-full size-16 bg-default-100 outline outline-default-100 outline-offset-4">
              <IconifyIcon icon={seller.iconifyIcon} width="40" height="40" />
            </div>

            <div className="mt-4 mb-6 text-center">
              <h6 className="text-base text-default-800 font-semibold">{seller.name}</h6>
              <p className="text-default-500 text-sm">{seller.owner}</p>
            </div>

            <div className="grid grid-cols-3">
              <div className="text-center p-2 text-sm">
                <h6 className="mb-1 text-default-800 font-semibold">{seller.sales}</h6>
                <p className="text-default-500">Sales</p>
              </div>

              <div className="text-center p-2 border-e border-s border-dashed border-default-200 text-sm">
                <h6 className="mb-1 text-default-800 font-semibold">{seller.products}</h6>
                <p className="text-default-500">Product</p>
              </div>

              <div className="text-center p-2 text-sm">
                <h6 className="mb-1 text-default-800 font-semibold">{seller.revenue}</h6>
                <p className="text-default-500">Revenue</p>
              </div>
            </div>
          </div>
        </div>
      ))}
    </div>
  );
};

export default Sallers;
