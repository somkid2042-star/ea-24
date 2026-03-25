import {
  LuChevronLeft,
  LuChevronRight,
  LuCircleCheck,
  LuCircleX,
  LuDownload,
  LuSearch,
} from 'react-icons/lu';

type ProductStatus = 'Active' | 'Unactive';

type Product = {
  id: number;
  name: string;
  price: string;
  income: string;
  sales: string;
  views: string;
  clicks: string;
  clickRate: string;
  status: ProductStatus;
};

const products: Product[] = [
  {
    id: 1,
    name: 'SmartTech Pro-4K Ultra HD TV',
    price: '$1,542.99',
    income: '$12.36k',
    sales: '3,217',
    views: '21,451',
    clicks: '16,287',
    clickRate: '39.56%',
    status: 'Active',
  },
  {
    id: 2,
    name: 'LuxeLeather Vintage Messenger Bag',
    price: '$699.99',
    income: '$22.88k',
    sales: '7,321',
    views: '32,151',
    clicks: '27,485',
    clickRate: '87.33%',
    status: 'Active',
  },
  {
    id: 3,
    name: 'InfinityGlow LED Desk Lamp',
    price: '$324.77',
    income: '$21.10k',
    sales: '8,245',
    views: '33,415',
    clicks: '25,430',
    clickRate: '91.43%',
    status: 'Unactive',
  },
  {
    id: 4,
    name: 'PowerPulse Wireless Earbuds',
    price: '$99.00',
    income: '$374',
    sales: '2,987',
    views: '41,123',
    clicks: '46,963',
    clickRate: '79.21%',
    status: 'Active',
  },
  {
    id: 5,
    name: 'AdventureQuest Outdoor Backpack',
    price: '$107.00',
    income: '$8.22',
    sales: '2,541',
    views: '14,789',
    clicks: '12,584',
    clickRate: '39.04%',
    status: 'Unactive',
  },
  {
    id: 6,
    name: 'FitLifePro Fitness Tracker',
    price: '$111.99',
    income: '$42.2k',
    sales: '44,201',
    views: '40,888',
    clicks: '14,520',
    clickRate: '68.41%',
    status: 'Active',
  },
  {
    id: 7,
    name: 'ChefMaster Pro Cookware Set',
    price: '$107.00',
    income: '$8.22',
    sales: '2,541',
    views: '14,789',
    clicks: '12,584',
    clickRate: '39.04%',
    status: 'Unactive',
  },
  {
    id: 8,
    name: 'PetPalace Pet Accessories',
    price: '$1,542.99',
    income: '$12.36k',
    sales: '3,217',
    views: '21,451',
    clicks: '16,287',
    clickRate: '39.56%',
    status: 'Active',
  },
  {
    id: 9,
    name: 'TravelSavvy Luggage Collection',
    price: '$1,542.99',
    income: '$12.36k',
    sales: '3,217',
    views: '21,451',
    clicks: '16,287',
    clickRate: '39.56%',
    status: 'Active',
  },
  {
    id: 10,
    name: 'MusicMuse Premium Headphones',
    price: '$99.00',
    income: '$374',
    sales: '2,987',
    views: '41,123',
    clicks: '46,963',
    clickRate: '79.21%',
    status: 'Active',
  },
  {
    id: 11,
    name: 'WellnessWonders Yoga Mat',
    price: '$324.77',
    income: '$21.10k',
    sales: '8,245',
    views: '33,415',
    clicks: '25,430',
    clickRate: '91.43%',
    status: 'Unactive',
  },
];

const ProductsStatistics = () => {
  return (
    <div className="grid grid-cols-1 gap-5 mb-5">
      <div className="card">
        <div className="card-header">
          <h6 className="card-title">Products Statistics</h6>

          <div className="flex gap-3 items-center">
            <div className="relative">
              <input
                type="text"
                className="form-input form-input-sm ps-9"
                placeholder="Search for...."
              />
              <div className="absolute inset-y-0 start-0 flex items-center ps-3">
                <LuSearch className="size-3.5 text-default-500" />
              </div>
            </div>

            <button className="btn btn-sm bg-transparent text-primary border border-dashed border-primary hover:bg-primary/20">
              <LuDownload className="size-4 me-1" />
              Export
            </button>
          </div>
        </div>

        <div className="overflow-x-auto">
          <div className="min-w-full inline-block align-middle">
            <div className="overflow-hidden">
              <table className="min-w-full divide-y divide-default-200">
                <thead className="bg-default-150">
                  <tr className="text-default-600">
                    <th className="py-3 text-start ps-4">
                      <input type="checkbox" className="form-checkbox" />
                    </th>
                    <th className="px-3.5 py-3 text-start text-sm font-medium">Products</th>
                    <th className="px-3.5 py-3 text-start text-sm font-medium">Price</th>
                    <th className="px-3.5 py-3 text-start text-sm font-medium">Income</th>
                    <th className="px-3.5 py-3 text-start text-sm font-medium">Sales</th>
                    <th className="px-3.5 py-3 text-start text-sm font-medium">View</th>
                    <th className="px-3.5 py-3 text-start text-sm font-medium">Click</th>
                    <th className="px-3.5 py-3 text-start text-sm font-medium whitespace-nowrap">
                      Click (%)
                    </th>
                    <th className="px-3.5 py-3 text-start text-sm font-medium">Status</th>
                  </tr>
                </thead>

                <tbody className="divide-y divide-default-200">
                  {products.map(product => (
                    <tr key={product.id} className="text-default-800">
                      <td className="py-2.5 ps-4">
                        <input type="checkbox" className="form-checkbox" />
                      </td>
                      <td className="px-3.5 py-2.5 text-sm whitespace-nowrap">{product.name}</td>
                      <td className="px-3.5 py-2.5 text-sm">{product.price}</td>
                      <td className="px-3.5 py-2.5 text-sm">{product.income}</td>
                      <td className="px-3.5 py-2.5 text-sm">{product.sales}</td>
                      <td className="px-3.5 py-2.5 text-sm">{product.views}</td>
                      <td className="px-3.5 py-2.5 text-sm">{product.clicks}</td>
                      <td className="px-3.5 py-2.5 text-sm">{product.clickRate}</td>
                      <td className="px-3.5 py-2.5">
                        <span
                          className={`py-0.5 px-2.5 inline-flex items-center gap-x-1 text-xs font-medium rounded ${
                            product.status === 'Active'
                              ? 'bg-success/15 text-success'
                              : 'bg-danger/15 text-danger'
                          }`}
                        >
                          {product.status === 'Active' ? (
                            <LuCircleCheck className="size-3 text-green-500" />
                          ) : (
                            <LuCircleX className="size-3 text-red-500" />
                          )}
                          {product.status}
                        </span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </div>

        <div className="card-footer">
          <p className="text-default-500 text-sm">
            Showing <b>07</b> of <b>11</b> Results
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
              className="btn size-7.5 bg-transparent  border border-default-200 text-default-600 hover:bg-primary/10 hover:text-primary hover:border-primary/10"
            >
              1
            </button>

            <button type="button" className="btn size-7.5 bg-primary text-white">
              2
            </button>

            <button
              type="button"
              className="btn size-7.5 bg-transparent  border border-default-200 text-default-600 hover:bg-primary/10 hover:text-primary hover:border-primary/10"
            >
              3
            </button>

            <button
              type="button"
              className="btn btn-sm border bg-transparent border-default-200 text-default-600 hover:bg-primary/10 hover:text-primary hover:border-primary/10"
            >
              Next
              <LuChevronRight className="size-4 ms-1" />
            </button>
          </nav>
        </div>
      </div>
    </div>
  );
};

export default ProductsStatistics;
