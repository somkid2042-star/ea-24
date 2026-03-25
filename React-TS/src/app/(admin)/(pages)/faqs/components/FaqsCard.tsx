import faq from '@/assets/images/faq.png';
import { LuSearch } from 'react-icons/lu';

const FaqsCard = () => {
  return (
    <div className="card relative overflow-hidden mb-6">
      <div className="card-body">
        <div className="grid lg:grid-cols-3 gap-5">
          <div className="lg:col-span-2">
            <div className="md:w-2xl">
              <h4 className="mb-3 text-xl font-semibold text-default-800">
                Explore support options for our products, fundamental knowledge, and beyond
              </h4>
              <p className="mb-5 text-default-500 text-sm">
                Open the door to a wealth of resources and expert guidance, allowing you to gain a
                deeper understanding of our products and access a treasure trove of additional
                knowledge.
              </p>
              <div className="relative">
                <input
                  type="email"
                  className="form-input form-input-lg"
                  placeholder="Ask a question"
                />
                <div className="absolute inset-y-0 end-4 flex items-center pointer-events-none ps-4 peer-disabled:opacity-50 peer-disabled:pointer-events-none">
                  <LuSearch className="size-4 flex items-center text-default-500" />
                </div>
              </div>
            </div>

            <div className="flex flex-wrap gap-2.5 mt-3">
              <span className="py-0.5 px-2.5 bg-default-200 text-default-600 text-xs font-semibold rounded">
                Install Vite
              </span>
              <span className="py-0.5 px-2.5 bg-default-200 text-default-600 text-xs font-semibold rounded">
                React
              </span>
              <span className="py-0.5 px-2.5 bg-default-200 text-default-600 text-xs font-semibold rounded">
                Angular
              </span>
              <span className="py-0.5 px-2.5 bg-default-200 text-default-600 text-xs font-semibold rounded">
                Vue
              </span>
            </div>
          </div>

          <div className="lg:col-span-1 lg:block hidden">
            <img
              src={faq}
              alt=""
              className="absolute  end-8 -top-28 -rotate-45 h-125"
              width={300}
            />
          </div>
        </div>
      </div>
    </div>
  );
};

export default FaqsCard;
