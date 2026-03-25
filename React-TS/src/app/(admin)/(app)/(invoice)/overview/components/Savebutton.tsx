import { LuSave } from 'react-icons/lu';

const Savebutton = () => {
  return (
    <button
      className="bg-primary text-nowrap text-white btn hover:bg-blue-600"
      onClick={() => window.print()}
    >
      <LuSave className="size-4 text-white" />
      Save & Draft
    </button>
  );
};

export default Savebutton;
