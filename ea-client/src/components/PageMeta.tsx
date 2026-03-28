type Pagedata = {
  title: string;
};
const PageMeta = ({ title }: Pagedata) => {
  return (
    <title>
      {title
        ? `${title} | EA-24 Trading System`
        : 'EA-24 Trading System'}
    </title>
  );
};

export default PageMeta;
