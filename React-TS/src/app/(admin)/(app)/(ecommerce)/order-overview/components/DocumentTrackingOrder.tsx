import delivery01 from '@/assets/images/brand/delivery-1.png';
import { Link } from 'react-router';

const DocumentTrackingOrder = () => {
  return (
    <div className="col-span-1">
      <div className="card mb-5">
        <div className="card-body">
          <h6 className="mb-3 card-title">Documents</h6>

          <div className="overflow-x-auto">
            <table className="w-full">
              <tbody>
                <tr>
                  <td className="pe-3.5 py-2 text-default-500 text-sm">Invoice No.</td>
                  <td className="ps-3.5 py-2 text-sm">
                    <Link to="/invoice-overview" className="text-primary">
                      #TWI154203
                    </Link>
                  </td>
                </tr>

                <tr>
                  <td className="pe-3.5 py-2 text-sm text-default-500">Shipping No</td>
                  <td className="ps-3.5 py-2 text-sm">
                    <Link to="#" className="text-primary">
                      #TWS987102301
                    </Link>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <div className="card">
        <div className="card-body">
          <div className="flex items-center justify-between gap-3 mb-4">
            <h6 className="card-title">Logistics Details</h6>
            <Link to="#" className="underline text-primary">
              Track Order
            </Link>
          </div>

          <div className="gap-4 flex">
            <img src={delivery01} alt="" className="h-10" width={40} />

            <div>
              <h6 className="mb-1 card-title">Express Delivery</h6>
              <p className="text-default-500 text-sm">ID: EDTW1400457854</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default DocumentTrackingOrder;
