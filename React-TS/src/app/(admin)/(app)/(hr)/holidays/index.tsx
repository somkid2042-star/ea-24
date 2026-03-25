import PageBreadcrumb from '@/components/PageBreadcrumb';
import PageMeta from '@/components/PageMeta';
import HolidaysLeaveDeleteModal from './components/HolidaysLeaveDeleteModal';
import HoliyDays from './components/HoliyDays';
import HoliydaysAdd from './components/HoliydaysAdd';

const Index = () => {
  return (
    <>
      <PageMeta title="Holidays" />
      <main>
        <PageBreadcrumb title="Holidays" subtitle="Menu" />
        <HoliyDays />
      </main>
      <HolidaysLeaveDeleteModal />
      <HoliydaysAdd />
    </>
  );
};

export default Index;
