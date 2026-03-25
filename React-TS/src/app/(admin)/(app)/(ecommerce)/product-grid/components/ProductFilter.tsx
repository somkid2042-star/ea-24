import { Link } from 'react-router';
import { LuChevronDown, LuChevronUp, LuSearch } from 'react-icons/lu';

type FilterOption = {
  id: string;
  label?: string;
  isColor?: boolean;
};

type FilterSection = {
  id: string;
  title: string;
  options: FilterOption[];
};

const filterConfig: FilterSection[] = [
  {
    id: 'color',
    title: 'Color',
    options: [
      { id: 'color1', isColor: true },
      { id: 'color2', isColor: true },
      { id: 'color3', isColor: true },
      { id: 'color4', isColor: true },
      { id: 'color5', isColor: true },
      { id: 'color6', isColor: true },
      { id: 'color7', isColor: true },
      { id: 'color8', isColor: true },
      { id: 'color9', isColor: true },
      { id: 'color10', isColor: true },
      { id: 'color11', isColor: true },
    ],
  },
  {
    id: 'price',
    title: 'Price',
    options: [
      { id: 'priceAll', label: 'All' },
      { id: 'price1', label: '$0.00 – $110.00' },
      { id: 'price2', label: '$110.00 – $220.00' },
      { id: 'price3', label: '$220 - $330' },
      { id: 'price4', label: '$330 - $550' },
      { id: 'price5', label: '$550+' },
      { id: 'price6', label: 'Low to High' },
      { id: 'price7', label: 'High to Low' },
    ],
  },
  {
    id: 'category',
    title: 'Product Category',
    options: [
      { id: 'categoryAll', label: 'All' },
      { id: 'category1', label: 'Mobiles, Computers' },
      { id: 'category2', label: 'TV, Appliances, Electronics' },
      { id: 'category3', label: "Men's Fashion" },
      { id: 'category4', label: "Women's Fashion" },
      { id: 'category5', label: 'Home, Kitchen, Pets' },
      { id: 'category6', label: 'Beauty, Health, Grocery' },
      { id: 'category7', label: 'Books' },
    ],
  },
  {
    id: 'rating',
    title: 'Rating',
    options: [
      { id: 'ratingAll', label: 'All' },
      { id: 'rating5', label: '5 Rating' },
      { id: 'rating4', label: '4 Rating and Up' },
      { id: 'rating3', label: '3 Rating and Up' },
      { id: 'rating2', label: '2 Rating and Up' },
      { id: 'rating1', label: '1 Rating and Up' },
      { id: 'rating0', label: '0 Rating' },
    ],
  },
  {
    id: 'gender',
    title: 'Gender',
    options: [
      { id: 'genderAll', label: 'All' },
      { id: 'gendermal', label: 'Male' },
      { id: 'genderFemal', label: 'Female' },
      { id: 'genderOthers', label: 'Other' },
    ],
  },
];

const colorClasses: Record<string, string> = {
  color1: 'border border-primary bg-primary checked:bg-primary checked:border-primary',
  color2: 'border border-red-300 bg-red-300 checked:bg-red-300 checked:border-red-300',
  color3: 'border border-green-300 bg-green-300 checked:bg-green-300 checked:border-green-300',
  color4:
    'border border-default-500 bg-default-500 checked:bg-default-500 checked:border-default-500',
  color5: 'border border-purple-500 bg-purple-500 checked:bg-purple-500 checked:border-purple-500',
  color6: 'border border-sky-500 bg-sky-500 checked:bg-sky-500 checked:border-sky-500',
  color7: 'border border-yellow-500 bg-yellow-500 checked:bg-yellow-500 checked:border-yellow-500',
  color8: 'border border-green-500 bg-green-500 checked:bg-green-500 checked:border-green-500',
  color9:
    'border border-default-800 bg-default-800 checked:bg-default-800 checked:border-default-800',
  color10:
    'border border-default-200 bg-default-200 checked:bg-default-200 checked:border-default-200',
  color11:
    'border border-emerald-300 bg-emerald-300 checked:bg-emerald-300 checked:border-emerald-300',
};

const ProductFilter = () => {
  return (
    <div className="card">
      <div className="card-body">
        <div className="flex items-center justify-between gap-3">
          <h6 className="card-title">Filter</h6>
          <div className="shrink-0">
            <Link
              to="#"
              className="underline transition-all duration-200 text-default-700 text-sm ease-linear hover:text-primary"
            >
              Clear All
            </Link>
          </div>
        </div>

        <div className="mt-4">
          <div className="relative">
            <input
              type="text"
              className="ps-9 form-input form-input-sm w-full"
              placeholder="Search for..."
            />
            <div className="absolute inset-y-0 start-0 flex items-center z-20 ps-3">
              <LuSearch className="size-3.5 text-default-600" />
            </div>
          </div>
        </div>

        <div className="mt-4 hs-accordion-group" data-hs-accordion-always-open="">
          {filterConfig.map(section => (
            <div
              key={section.id}
              className="hs-accordion active mt-4"
              id={`hs-accordion-${section.id}`}
            >
              <button
                className="hs-accordion-toggle underline inline-flex items-center justify-between gap-x-3 w-full font-semibold text-start text-default-800 rounded-lg text-sm"
                aria-expanded="true"
                aria-controls={`hs-collapse-${section.id}`}
              >
                {section.title}
                <LuChevronDown size={16} className="text-base hs-accordion-active:hidden block" />
                <LuChevronUp size={16} className="text-base hs-accordion-active:block hidden" />
              </button>

              <div
                id={`hs-collapse-${section.id}`}
                className="hs-accordion-content w-full overflow-hidden transition-[height] duration-300"
                role="region"
                aria-labelledby={`hs-accordion-${section.id}`}
              >
                <div className={`mt-4 flex ${section.id === 'color' ? 'gap-2' : 'flex-col gap-2'}`}>
                  {section.options.map(opt =>
                    opt.isColor ? (
                      <input
                        key={opt.id}
                        id={opt.id}
                        type="checkbox"
                        className={`size-5 cursor-pointer rounded-sm focus:ring-0 ${colorClasses[opt.id]}`}
                      />
                    ) : (
                      <div key={opt.id} className="flex gap-2 items-center">
                        <input
                          type="checkbox"
                          className="form-checkbox checked:bg-primary"
                          id={opt.id}
                        />
                        <label
                          htmlFor={opt.id}
                          className="text-sm text-default-800 align-middle cursor-pointer"
                        >
                          {opt.label}
                        </label>
                      </div>
                    )
                  )}
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

export default ProductFilter;
