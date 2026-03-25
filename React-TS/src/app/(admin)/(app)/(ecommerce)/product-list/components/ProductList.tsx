import img01 from '@/assets/images/product/img-01.png';
import img03 from '@/assets/images/product/img-03.png';
import img06 from '@/assets/images/product/img-06.png';
import img07 from '@/assets/images/product/img-07.png';
import img08 from '@/assets/images/product/img-08.png';
import img09 from '@/assets/images/product/img-09.png';
import { Link } from 'react-router';
import Flatpickr from 'react-flatpickr';
import {
  LuChevronLeft,
  LuChevronRight,
  LuEllipsis,
  LuEye,
  LuPlus,
  LuSearch,
  LuSquarePen,
  LuTrash2,
} from 'react-icons/lu';

type Product = {
  id: string;
  code: string;
  name: string;
  image: string;
  category: string;
  price: number;
  stock: number;
  revenue: string;
  status: 'Publish' | 'Scheduled';
};

const ProductList = () => {
  const products: Product[] = [
    {
      id: '1',
      code: '#TAD-232100071',
      name: 'Smartest Printed T-shirt',
      image: img01,
      category: 'Fashion',
      price: 79.99,
      stock: 500,
      revenue: '$24,365',
      status: 'Scheduled',
    },
    {
      id: '2',
      code: '#TAD-232100074',
      name: 'Techel Black Bluetooth Soundbar',
      image: img06,
      category: 'Electronics',
      price: 452.99,
      stock: 300,
      revenue: '$49,234',
      status: 'Publish',
    },
    {
      id: '3',
      code: '#TAD-232100075',
      name: 'Bovet Fleurier AIFSQ029',
      image: img07,
      category: 'Home Decor',
      price: 119.99,
      stock: 240,
      revenue: '$20,784',
      status: 'Publish',
    },
    {
      id: '4',
      code: '#TAD-232100077',
      name: 'Roar Twill Blue Baseball Cap',
      image: img09,
      category: 'Fashion',
      price: 49.99,
      stock: 470,
      revenue: '$19,321',
      status: 'Publish',
    },
    {
      id: '5',
      code: '#TAD-232100080',
      name: 'Aahwan Solid Women Beige Baggy Shorts',
      image: img08,
      category: 'Fashion',
      price: 64.7,
      stock: 150,
      revenue: '$13,987',
      status: 'Publish',
    },
    {
      id: '6',
      code: '#TAD-232100072',
      name: 'Mesh Ergonomic Black Chair',
      image: img03,
      category: 'Furniture',
      price: 214.47,
      stock: 400,
      revenue: '$1,24,365',
      status: 'Publish',
    },
    {
      id: '7',
      code: '#TAD-232100071',
      name: 'Smartest Printed T-shirt',
      image: img01,
      category: 'Fashion',
      price: 79.99,
      stock: 500,
      revenue: '$24,365',
      status: 'Scheduled',
    },
  ];
  return (
    <div className="grid grid-cols-1 gap-5 mb-5">
      <div className="card">
        <div className="card-header">
          <div className="md:flex md:space-y-0 space-y-3.5 gap-3 items-center">
            <div className="relative">
              <input
                type="email"
                className="ps-11 form-input form-input-sm w-full"
                placeholder="Search for...."
              />
              <div className="absolute inset-y-0 start-0 flex items-center ps-3">
                <LuSearch className="size-3.5 flex items-center text-default-500" />
              </div>
            </div>

            <Flatpickr
              options={{
                mode: 'range',
                dateFormat: 'd M, Y',
              }}
              className="form-input form-input-sm w-full"
              placeholder="Select Date"
            />
          </div>

          <button className="btn btn-sm bg-primary text-white">
            <LuPlus className="size-4 me-1" />
            Add Product
          </button>
        </div>

        <div className="flex flex-col">
          <div className="overflow-x-auto">
            <div className="min-w-full inline-block align-middle">
              <div className="overflow-hidden">
                <table className="min-w-full divide-y divide-default-200">
                  <thead className="bg-default-150">
                    <tr className="text-sm font-normal text-default-700">
                      <th className="px-3.5 py-3 text-start">Product Code</th>
                      <th className="px-3.5 py-3 text-start">Product Name</th>
                      <th className="px-3.5 py-3 text-start">Category</th>
                      <th className="px-3.5 py-3 text-start">Price</th>
                      <th className="px-3.5 py-3 text-start">Stock</th>
                      <th className="px-3.5 py-3 text-start">Revenue</th>
                      <th className="px-3.5 py-3 text-start">Status</th>
                      <th className="px-3.5 py-3 text-start">Action</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-default-200">
                    {products.map((product: Product) => (
                      <tr key={product.id} className="text-default-800 font-normal">
                        <td className="px-3.5 py-2.5 whitespace-nowrap text-sm text-primary">
                          {product.code}
                        </td>

                        <td className="px-3.5 py-2.5 whitespace-nowrap text-sm">
                          <div className="flex items-center gap-2">
                            <img
                              src={product.image}
                              alt={product.name}
                              width={24}
                              height={24}
                              className="h-6 w-6 object-cover"
                            />
                            <h6 className="text-default-800">{product.name}</h6>
                          </div>
                        </td>

                        <td className="px-3.5 py-2.5 whitespace-nowrap text-sm">
                          <div className="inline-flex py-0.5 px-2.5 rounded text-xs font-normal bg-default-100 border border-default-200 text-default-500">
                            {product.category}
                          </div>
                        </td>

                        <td className="px-3.5 py-2.5 whitespace-nowrap text-sm">
                          ${product.price.toFixed(2)}
                        </td>

                        <td className="px-3.5 py-2.5 whitespace-nowrap text-sm">{product.stock}</td>

                        <td className="px-3.5 py-2.5 whitespace-nowrap text-sm">
                          {product.revenue}
                        </td>

                        <td className="px-3.5 py-2.5 whitespace-nowrap">
                          {product.status === 'Publish' ? (
                            <span className="inline-flex items-center gap-x-1.5 py-0.5 px-2.5 rounded text-xs font-medium bg-success/15 text-success">
                              {product.status}
                            </span>
                          ) : (
                            <span className="inline-flex items-center gap-x-1.5 py-0.5 px-2.5 rounded text-xs font-medium bg-danger/15 text-danger">
                              {product.status}
                            </span>
                          )}
                        </td>

                        <td className="px-3.5 py-2.5">
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
                Next
                <LuChevronRight className="size-4 ms-1" />
              </button>
            </nav>
          </div>
        </div>
      </div>
    </div>
  );
};

export default ProductList;
