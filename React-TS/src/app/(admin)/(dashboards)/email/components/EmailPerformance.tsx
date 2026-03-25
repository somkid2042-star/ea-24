import { LuChevronLeft, LuChevronRight, LuDownload, LuSearch } from 'react-icons/lu';
type EmailStats = {
  email: string;
  createDate: string;
  openRate: string;
  clickThrough: string;
  clickRate: string;
  unsubscribed: string;
  bounce: string;
  tSpam: string;
};
const EmailPerformance = () => {
  const emailStatsData: EmailStats[] = [
    {
      email: 'Adverting & Marketing Agencies',
      createDate: '05 Aug, 2023',
      openRate: '18.65%',
      clickThrough: '2.66%',
      clickRate: '14.14%',
      unsubscribed: '0.19%',
      bounce: '1.29%',
      tSpam: '0.03%',
    },
    {
      email: 'Automotive & Aerospace',
      createDate: '20 Sep, 2023',
      openRate: '20.13%',
      clickThrough: '3.44%',
      clickRate: '18.03%',
      unsubscribed: '0.18%',
      bounce: '1.18%',
      tSpam: '0.00%',
    },
    {
      email: 'Education',
      createDate: '04 Jun, 2023',
      openRate: '18.74%',
      clickThrough: '2.80%',
      clickRate: '14.94%',
      unsubscribed: '0.17%',
      bounce: '1.35%',
      tSpam: '0.02%',
    },
    {
      email: 'Financial Services',
      createDate: '11 Feb, 2023',
      openRate: '18.23%',
      clickThrough: '2.72%',
      clickRate: '14.79%',
      unsubscribed: '0.16%',
      bounce: '1.30%',
      tSpam: '0.00%',
    },
    {
      email: 'Food & Beverage',
      createDate: '26 Nov, 2023',
      openRate: '15.48%',
      clickThrough: '1.69%',
      clickRate: '10.69%',
      unsubscribed: '0.11%',
      bounce: '0.63%',
      tSpam: '0.00%',
    },
    {
      email: 'Healthcare Services',
      createDate: '19 Jul, 2023',
      openRate: '19.12%',
      clickThrough: '2.98%',
      clickRate: '15.11%',
      unsubscribed: '0.17%',
      bounce: '1.08%',
      tSpam: '0.00%',
    },
    {
      email: 'Professional Services',
      createDate: '14 Jun, 2023',
      openRate: '18.14%',
      clickThrough: '2.39%',
      clickRate: '12.92%',
      unsubscribed: '0.17%',
      bounce: '1.10%',
      tSpam: '0.00%',
    },
    {
      email: 'Logistics & Wholesale',
      createDate: '03 Dec, 2023',
      openRate: '18.50%',
      clickThrough: '0.20%',
      clickRate: '14.84%',
      unsubscribed: '0.15%',
      bounce: '1.40%',
      tSpam: '0.00%',
    },
    {
      email: 'Real Estate Agents & Brokers',
      createDate: '03 Dec, 2023',
      openRate: '18.06%',
      clickThrough: '2.02%',
      clickRate: '11.51%',
      unsubscribed: '0.22%',
      bounce: '1.18%',
      tSpam: '0.00%',
    },
    {
      email: 'Nonprofit',
      createDate: '03 Dec, 2023',
      openRate: '20.39%',
      clickThrough: '2.66%',
      clickRate: '12.99%',
      unsubscribed: '0.17%',
      bounce: '1.09%',
      tSpam: '0.01%',
    },
    {
      email: 'Retail',
      createDate: '03 Dec, 2023',
      openRate: '14.98%',
      clickThrough: '2.25%',
      clickRate: '14.82%',
      unsubscribed: '0.12%',
      bounce: '0.69%',
      tSpam: '0.01%',
    },
  ];

  return (
    <div className="card">
      <div className="card-header">
        <h6 className="card-title">Email Performance</h6>

        <div className="flex gap-3 items-center">
          <div className="relative">
            <input
              type="email"
              className="form-input form-input-sm ps-9"
              placeholder="Search for...."
            />
            <div className="absolute inset-y-0 start-0 flex items-center ps-3">
              <LuSearch className="size-3.5  text-default-500" />
            </div>
          </div>

          <button className="btn btn-sm bg-primary text-white">
            <LuDownload className="size-4" />
            Export
          </button>
        </div>
      </div>

      <div className="flex flex-col">
        <div className="overflow-x-auto">
          <div className="min-w-full inline-block align-middle">
            <div className="overflow-hidden">
              <table className="min-w-full divide-y divide-default-200">
                <thead className="bg-default-150">
                  <tr className="text-sm font-normal text-default-500 whitespace-nowrap">
                    <th scope="col" className="py-3 px-4 pe-0 text-start">
                      <input type="checkbox" className="form-checkbox" />
                    </th>
                    <th className="px-3.5 py-3 text-start">Email</th>
                    <th className="px-3.5 py-3 text-start">Create Date</th>
                    <th className="px-3.5 py-3 text-start">Open Rate (%)</th>
                    <th className="px-3.5 py-3 text-start">Click Through (%)</th>
                    <th className="px-3.5 py-3 text-start">Click Rate (%)</th>
                    <th className="px-3.5 py-3 text-start">Unsubscribed (%)</th>
                    <th className="px-3.5 py-3 text-start">Bounce (%)</th>
                    <th className="px-3.5 py-3 text-start">TSpam (%)</th>
                  </tr>
                </thead>

                <tbody className="divide-y divide-default-200">
                  {emailStatsData.map((row, idx) => (
                    <tr key={idx} className="text-default-800 font-normal">
                      <td className="py-2.5 ps-4">
                        <input type="checkbox" className="form-checkbox" />
                      </td>
                      <td className="px-3.5 py-2.5 whitespace-nowrap text-sm">{row.email}</td>
                      <td className="px-3.5 py-2.5 whitespace-nowrap text-sm">{row.createDate}</td>
                      <td className="px-3.5 py-2.5 whitespace-nowrap text-sm">{row.openRate}</td>
                      <td className="px-3.5 py-2.5 whitespace-nowrap text-sm">
                        {row.clickThrough}
                      </td>
                      <td className="px-3.5 py-2.5 whitespace-nowrap text-sm">{row.clickRate}</td>
                      <td className="px-3.5 py-2.5 whitespace-nowrap text-sm">
                        {row.unsubscribed}
                      </td>
                      <td className="px-3.5 py-2.5 whitespace-nowrap text-sm">{row.bounce}</td>
                      <td className="px-3.5 py-2.5 whitespace-nowrap text-sm">{row.tSpam}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </div>
        <div className="card-footer">
          <p className="text-default-500 text-sm">
            Showing <b>07</b> of <b>19</b> Results
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
              <LuChevronRight className="size-4 ms-1" />
            </button>
          </nav>
        </div>
      </div>
    </div>
  );
};

export default EmailPerformance;
