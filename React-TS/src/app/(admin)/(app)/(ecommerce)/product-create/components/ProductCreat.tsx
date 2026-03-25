import React, { useState } from 'react';
import { LuCloudUpload } from 'react-icons/lu';

const ProductCreat = () => {
  const [files, setFiles] = useState<File[]>([]);

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files) {
      setFiles(Array.from(e.target.files));
    }
  };
  const handleRemove = (index: number) => {
    setFiles(prev => prev.filter((_, i) => i !== index));
  };

  return (
    <div className="lg:col-span-9 col-span-1">
      <div className="card">
        <div className="card-body">
          <h6 className="mb-4 card-title">Create Product</h6>

          <div className="grid lg:grid-cols-2 grid-cols-1 gap-5 mb-5">
            <div>
              <label
                htmlFor="productNameInput"
                className="inline-block mb-2 text-sm text-default-800 font-medium"
              >
                Product Title
              </label>
              <input
                id="productNameInput"
                type="text"
                className="form-input"
                placeholder="Product Title"
                required
              />
              <p className="mt-1 text-default-400">
                Do not exceed 20 characters when entering the product name.
              </p>
            </div>

            <div>
              <label
                htmlFor="productCodeInput"
                className="inline-block mb-2 text-sm text-default-800 font-medium"
              >
                Product Code
              </label>
              <input
                id="productCodeInput"
                type="text"
                className="form-input"
                placeholder="Product Code"
                value="TWT145015"
                disabled
              />
              <p className="mt-1 text-default-400">Code will be generated automatically</p>
            </div>
          </div>

          <div className="grid lg:grid-cols-3 grid-cols-1 gap-5 mb-5">
            <div>
              <label
                htmlFor="qualityInput"
                className="inline-block mb-2 text-sm text-default-800 font-medium"
              >
                Quantity
              </label>
              <input
                type="number"
                id="qualityInput"
                className="form-input"
                placeholder="Quantity"
                required
              />
            </div>

            <div>
              <label
                htmlFor="skuInput"
                className="inline-block mb-2 text-sm text-default-800 font-medium"
              >
                SKU
              </label>
              <input
                type="text"
                id="skuInput"
                className="form-input"
                placeholder="TWT-LP-ALU-08"
                required
              />
            </div>

            <div>
              <label
                htmlFor="brandInput"
                className="inline-block mb-2 text-sm text-default-800 font-medium"
              >
                Brand
              </label>
              <input
                type="text"
                id="brandInput"
                className="form-input"
                placeholder="Brand"
                required
              />
            </div>

            <div>
              <label className="inline-block mb-2 text-sm text-default-800 font-medium">
                Category
              </label>
              <select className="form-input">
                <option value="Beauty,Health,Grocery">Beauty, Health, Grocery</option>
                <option value="Books">Books</option>
                <option value="Home,kichen,Pets">Home, Kitchen, Pets</option>
                <option value="Men's Fashion">Men's Fashion</option>
                <option value="Mobile,Computers">Mobile, Computers</option>
                <option value="TV,Appliances,Electronics">TV, Appliances, Electronics</option>
                <option value="Women's Fashion">Women's Fashion</option>
              </select>
            </div>

            <div>
              <label className="inline-block mb-2 text-sm text-default-800 font-medium">
                Product Type
              </label>
              <select className="form-input">
                <option value="Boxed">Boxed</option>
                <option value="Single">Single</option>
                <option value="Unit">Unit</option>
              </select>
            </div>

            <div>
              <label className="inline-block mb-2 text-sm text-default-800 font-medium">
                Gender
              </label>
              <select className="form-input">
                <option value="Female">Female</option>
                <option value="Male">Male</option>
                <option value="Unisex">Unisex</option>
              </select>
            </div>
          </div>

          <div className="grid lg:grid-cols-2 grid-cols-1 gap-5 mb-5">
            <div>
              <label className="inline-block mb-2 text-sm text-default-800 font-medium">
                Colors Variant
              </label>
              <div className="flex gap-2 items-center flex-wrap">
                <input type="checkbox" className="form-checkbox text-primary" />
                <input type="checkbox" className="form-checkbox text-success" />
                <input type="checkbox" className="form-checkbox text-info" />
                <input type="checkbox" className="form-checkbox text-warning" />
                <input type="checkbox" className="form-checkbox text-danger" />
                <input type="checkbox" className="form-checkbox text-black" />
              </div>
            </div>

            <div>
              <label className="inline-block mb-2 text-sm text-default-800 font-medium">Size</label>
              <div className="flex gap-2 items-center">
                {['XS', 'S', 'M', 'L', 'XL', '2XL'].map(size => (
                  <button
                    key={size}
                    className="size-7.5 text-xs text-default-500 btn border border-default-200 hover:bg-primary/10 hover:border-primary"
                  >
                    {size}
                  </button>
                ))}
              </div>
            </div>
          </div>

          <div className="grid grid-cols-1 mb-5">
            <h6 className="mb-2 font-semibold text-sm text-default-800">Product Images</h6>

            <label
              htmlFor="fileUpload"
              className="flex flex-col items-center justify-center bg-transparent border border-dashed rounded-md cursor-pointer border-default-300 p-6 hover:bg-default-100 transition"
            >
              <LuCloudUpload className="size-12 text-default-500 mb-2" />
              <h5 className="mb-0 font-normal text-base text-default-500">
                Drag and drop your files or <span className="text-primary underline">browse</span>
              </h5>
              <input
                id="fileUpload"
                type="file"
                className="hidden"
                multiple
                accept="image/*"
                onChange={handleFileChange}
              />
            </label>

            <ul className="flex flex-wrap gap-5 mt-5">
              {files.map((file, index) => (
                <li key={index} className="border rounded border-default-200 p-3 w-32 text-center">
                  <div className="p-2 mx-auto rounded-md size-20 bg-default-200 flex items-center justify-center overflow-hidden">
                    <img
                      src={URL.createObjectURL(file)}
                      alt={file.name}
                      className="w-full h-full object-cover rounded-md"
                    />
                  </div>
                  <div className="pt-2">
                    <h5 className="text-xs truncate">{file.name}</h5>
                    <p className="text-xs text-default-500">{(file.size / 1024).toFixed(1)} KB</p>
                  </div>
                  <button
                    onClick={() => handleRemove(index)}
                    className="mt-2 px-2 py-1 text-xs text-white bg-danger rounded hover:bg-red-600"
                  >
                    Delete
                  </button>
                </li>
              ))}
            </ul>
          </div>

          <div className="grid grid-cols-1 gap-2 mb-5">
            <h6 className="font-semibold text-default-800 text-sm">Description</h6>
            <textarea className="form-input" placeholder="Enter Description" rows={5}></textarea>
          </div>

          <div className="grid lg:grid-cols-3 grid-cols-1 gap-5 mb-5">
            <div className="col-span-1">
              <label
                htmlFor="productPrice"
                className="inline-block mb-2 text-sm text-default-800 font-medium"
              >
                Price
              </label>
              <input
                type="number"
                id="productPrice"
                className="form-input"
                placeholder="$0.00"
                required
              />
            </div>

            <div className="col-span-1">
              <label
                htmlFor="productDiscounts"
                className="inline-block mb-2 text-sm text-default-800 font-medium"
              >
                Discounts
              </label>
              <input
                type="number"
                id="productDiscounts"
                className="form-input"
                placeholder="0%"
                required
              />
            </div>

            <div className="col-span-1">
              <label
                htmlFor="brandInput"
                className="inline-block mb-2 text-sm text-default-800 font-medium"
              >
                TAX Applicable
              </label>
              <select className="form-input">
                <option defaultValue="Entertainment">Entertainment</option>
                <option value="Exclusive">Exclusive </option>
                <option value="none">none</option>
                <option value="Professional">Professional</option>
              </select>
            </div>

            <div className="col-span-1">
              <label
                htmlFor="publishDateTime"
                className="inline-block mb-2 text-sm text-default-800 font-medium"
              >
                Publish Date &amp; Time
              </label>
              sales-paymentssales-paymentssales-payments
            </div>

            <div className="col-span-1">
              <label
                htmlFor="brandInput"
                className="inline-block mb-2 text-sm text-default-800 font-medium"
              >
                Status
              </label>
              <select className="form-input">
                <option value="Draft">Draft</option>
                <option value="Entertainment">Entertainment</option>
                <option value="Published">Published</option>
                <option value="Scheduled"> Scheduled</option>
              </select>
            </div>

            <div className="col-span-1">
              <label
                htmlFor="brandInput"
                className="inline-block mb-2 text-sm text-default-800 font-medium"
              >
                Visibility
              </label>
              <select className="form-input">
                <option value="Hidden">Hidden</option>
                <option value="Publice">Publice</option>
              </select>
            </div>

            <div>
              <div>
                <label
                  htmlFor="productTag"
                  className="inline-block mb-2 text-sm text-default-800 font-medium"
                >
                  Product Tag
                </label>
                <input
                  className="form-input"
                  id="productTag"
                  data-choices
                  data-choices-text-unique-true
                  type="text"
                  defaultValue="Fashion, Clothes, Headphones"
                />
              </div>
            </div>
          </div>

          <div className="mt-4 flex gap-2 md:justify-end">
            <button className="bg-transparent text-danger btn border-0 hover:bg-danger/15">
              Reset
            </button>
            <button className="text-white btn bg-primary">Create Product</button>
            <button className="bg-teal-600 text-white btn hover:bg-teal-700">
              Draft & Preview
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default ProductCreat;
