import React from 'react';
import { LuSquareCheck } from 'react-icons/lu';

type Feature = {
  label: React.ReactNode;
};

type Plan = {
  id: number;
  title: string;
  price: string;
  period: string;
  color: string;
  buttonColor: string;
  features: Feature[];
};

const plans: Plan[] = [
  {
    id: 1,
    title: 'Personal Plan',
    price: '29.99',
    period: 'Per Month',
    color: 'bg-primary/10 text-primary',
    buttonColor: 'bg-blue-600 text-white',
    features: [
      {
        label: (
          <>
            <b>3</b> Projects
          </>
        ),
      },
      {
        label: (
          <>
            <b>299</b> Customers
          </>
        ),
      },
      { label: 'Scalable Bandwidth' },
      {
        label: (
          <>
            <b>0</b> No Team Account
          </>
        ),
      },
      {
        label: (
          <>
            <b>3</b> Projects
          </>
        ),
      },
      {
        label: (
          <>
            <b>299</b> Customers
          </>
        ),
      },
    ],
  },
  {
    id: 2,
    title: 'Enterprise Plan',
    price: '49.99',
    period: 'Per Month',
    color: 'bg-purple-500/20 text-purple-600',
    buttonColor: 'bg-purple-600 text-white',
    features: [
      {
        label: (
          <>
            <b>3</b> Projects
          </>
        ),
      },
      {
        label: (
          <>
            <b>299</b> Customers
          </>
        ),
      },
      { label: 'Scalable Bandwidth' },
      {
        label: (
          <>
            <b>0</b> No Team Account
          </>
        ),
      },
      {
        label: (
          <>
            <b>3</b> Projects
          </>
        ),
      },
      {
        label: (
          <>
            <b>299</b> Customers
          </>
        ),
      },
      { label: 'Scalable Bandwidth' },
      {
        label: (
          <>
            <b>0</b> No Team Account
          </>
        ),
      },
    ],
  },
];

const HorizontalPricing = () => {
  return (
    <>
      <h5 className="mt-2 mb-4 underline text-lg font-semibold text-default-700">
        Horizontal Pricing
      </h5>

      <div className="grid lg:grid-cols-2 gap-5">
        {plans.map(plan => (
          <div key={plan.id} className="card">
            <div className="card-body">
              <h5 className="text-lg mb-2 font-semibold text-default-800">{plan.title}</h5>

              <div className="grid lg:grid-cols-3 gap-5">
                <div className="lg:col-span-2">
                  <p className="relative before:content-[''] before:absolute before:border-b before:border-default-200 before:bottom-2 before:start-0 before:end-0">
                    <span className="pe-2 bg-card relative text-default-500 text-sm">
                      Everything Includes
                    </span>
                  </p>

                  <div className="grid md:grid-cols-2 md:gap-5">
                    {[0, 1].map(col => (
                      <div key={col}>
                        <ul className="mt-5 flex flex-col gap-3 text-sm">
                          {plan.features
                            .slice(
                              col * Math.ceil(plan.features.length / 2),
                              (col + 1) * Math.ceil(plan.features.length / 2)
                            )
                            .map((feature, i) => (
                              <li key={i} className="flex items-center gap-2">
                                <LuSquareCheck className="size-4 text-success" />
                                <span className="text-default-900">{feature.label}</span>
                              </li>
                            ))}
                        </ul>
                      </div>
                    ))}
                  </div>
                </div>

                <div className="lg:col-span-1">
                  <div className={`p-5 rounded-lg ${plan.color.split(' ')[0]}`}>
                    <div>
                      <p className={`text-sm mb-4 ${plan.color.split(' ')[1]}`}>{plan.period}</p>
                      <p className="text-2xl font-bold mb-4 text-default-800">${plan.price}</p>
                      <button
                        type="button"
                        className={`py-1.5 px-4 w-full rounded-md ${plan.buttonColor}`}
                      >
                        Buy Now
                      </button>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        ))}
      </div>
    </>
  );
};

export default HorizontalPricing;
