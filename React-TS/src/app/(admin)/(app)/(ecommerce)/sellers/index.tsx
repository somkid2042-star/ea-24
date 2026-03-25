import PageBreadcrumb from '@/components/PageBreadcrumb';
import { LuChevronLeft, LuPlus, LuSearch } from 'react-icons/lu';
import Modal from './components/Modal';
import Sallers from './components/Sallers';
import PageMeta from '@/components/PageMeta';

const Index = () => {
  return (
    <>
      <PageMeta title="Sellers" />
      <main>
        <PageBreadcrumb title="Sellers" subtitle="Menu" />
        <div className="flex justify-between gap-3 flex-wrap items-center mb-5">
          <div className="relative">
            <input type="email" className="ps-11 form-input" placeholder="Search for..." />
            <div className="absolute inset-y-0 start-0 flex items-center ps-3">
              <LuSearch className="size-4 flex items-center text-default-500" />
            </div>
          </div>

          <button
            type="button"
            className="btn  bg-primary text-white"
            aria-haspopup="dialog"
            aria-expanded="false"
            aria-controls="ecommerce-sellers-add"
            data-hs-overlay="#ecommerce-sellers-add"
          >
            <LuPlus className="size-4 ms-1" />
            Add Seller
          </button>
        </div>

        <Sallers />
        <div className="flex flex-wrap justify-center md:justify-between items-center md:gap-0 gap-4 mt-5 text-default-500">
          <p className="text-default-500 text-sm">
            Showing <b>12</b> of <b>44</b> Results
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
              <LuChevronLeft className="size-4 ms-1" />
            </button>
          </nav>
        </div>
        <Modal />
      </main>
    </>
  );
};

export default Index;
