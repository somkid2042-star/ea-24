type ShippingDetail = {
  value: string;
  label: string;
  status?: boolean;
  statusClass?: string;
};

const shippingData: ShippingDetail[] = [
  { value: '#TWT5015100366', label: 'Order ID' },
  { value: '02 Nov, 2023', label: 'Order Date' },
  { value: '09 Nov, 2023', label: 'Delivery Date' },
  { value: '$843.49', label: 'Order Amount' },
  {
    value: 'Shipping',
    label: 'Order Status',
    status: true,
    statusClass:
      'py-0.5 px-2.5 font-semibold uppercase border border-secondary/30 text-secondary rounded inline-block mb-2 text-xs bg-secondary/10',
  },
];

const ShippingDetails = () => {
  return (
    <div className="grid lg:grid-cols-5 md:grid-cols-2 grid-cols-1 gap-5 mb-5">
      {shippingData.map((item, idx) => (
        <div key={idx} className="card text-center">
          <div className="card-body">
            {item.status ? (
              <span className={item.statusClass}>{item.value}</span>
            ) : (
              <h6 className="mb-1 text-default-800 font-semibold text-sm">{item.value}</h6>
            )}
            <p className="uppercase text-default-500 text-sm">{item.label}</p>
          </div>
        </div>
      ))}
    </div>
  );
};

export default ShippingDetails;
