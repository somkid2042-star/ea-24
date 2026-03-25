type Pagedata = {
  title: string;
};
const PageMeta = ({ title }: Pagedata) => {
  return (
    <title>
      {title
        ? `${title} | Tailwick - Tailwind CSS 3 Admin Layout & UI Kit Template`
        : ' Tailwick - Tailwind CSS 3 Admin Layout & UI Kit Template'}
    </title>
  );
};

export default PageMeta;
