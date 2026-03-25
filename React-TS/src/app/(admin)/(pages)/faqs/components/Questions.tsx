import React from 'react';
import { LuChevronDown, LuChevronUp } from 'react-icons/lu';
type FAQItem = {
  id: string;
  question: string;
  answer: React.ReactNode;
};

const leftFaq: FAQItem[] = [
  {
    id: 'install',
    question: 'How to install Tailwind CSS in a project?',
    answer: (
      <>
        <p className="mb-3 text-sm">
          To install Tailwind CSS, you can use npm or yarn by running the following commands:
        </p>
        <ol className="flex flex-col gap-2 list-decimal list-inside">
          <li className="text-sm text-default-700">
            <b>Using npm</b>
            <div className="mt-2">
              <code>npm install tailwindcss</code>
            </div>
          </li>
          <div className="text-center">OR</div>
          <li className="text-sm text-default-700">
            <b>Using yarn</b>
            <div className="mt-2">
              <code>yarn add tailwindcss</code>
            </div>
          </li>
        </ol>
      </>
    ),
  },
  {
    id: 'darkmode',
    question: 'How to enable dark mode in Tailwind CSS?',
    answer: (
      <>
        <p className="mb-3 text-sm">
          To enable dark mode in Tailwind CSS, update your <code>tailwind.config.js</code> file with
          the <code>darkMode</code> option. You can choose between <code>media</code> or{' '}
          <code>class</code>.
        </p>
        <p className="mb-3 text-sm">
          Using <code>class</code>, the dark mode is enabled by adding a <code>.dark</code> class to
          an ancestor element of your components:
        </p>
        <pre className="text-sm bg-default-100 p-3 rounded-md">
          {`module.exports = {
  darkMode: 'class', // or 'media'
// ...
}`}
        </pre>
      </>
    ),
  },
  {
    id: 'plugins',
    question: 'How to use plugins in Tailwind CSS?',
    answer: (
      <pre className="text-sm bg-default-100 p-3 rounded-md">
        {`const plugin = require('tailwindcss/plugin')

module.exports = {
  plugins: [
    plugin(function({ addUtilities, addComponents, e, config }) {
      // Add your custom styles here
    }),
  ],
}`}
      </pre>
    ),
  },
];

const rightFaq: FAQItem[] = [
  {
    id: 'config',
    question: 'How to customize the configuration file in Tailwind CSS?',
    answer: (
      <>
        <p className="mb-3 text-sm">
          You can customize the <code>tailwind.config.js</code> file to override the default
          configuration options provided by Tailwind CSS:
        </p>
        <pre className="text-sm bg-default-100 p-3 rounded-md">
          {`module.exports = {
  purge: [],
  theme: {
    extend: {
      // ...
    },
  },
  variants: {},
  plugins: [],
}`}
        </pre>
      </>
    ),
  },
  {
    id: 'responsive',
    question: 'How to use responsive variants in Tailwind CSS?',
    answer: (
      <>
        <p className="mb-3 text-sm">
          Tailwind CSS generates responsive variants for most utilities. Default breakpoints are:
        </p>
        <ul className="flex flex-col gap-2 list-disc list-inside mb-2 text-sm">
          <li>
            <code>sm:</code> 640px
          </li>
          <li>
            <code>md:</code> 768px
          </li>
          <li>
            <code>lg:</code> 1024px
          </li>
          <li>
            <code>xl:</code> 1280px
          </li>
        </ul>
        <code className="text-sm mt-2 block">Your content here</code>
      </>
    ),
  },
];

const FAQAccordion = () => {
  const renderFaqs = (faqs: FAQItem[]) =>
    faqs.map(item => (
      <div key={item.id} className="hs-collapse-group">
        <button
          type="button"
          className="hs-collapse-toggle card px-4 mb-2 py-3 flex flex-row justify-between items-center w-full"
          data-hs-collapse={`#faq-${item.id}`}
        >
          {item.question}
          <LuChevronDown className="size-4 hs-collapse-open:hidden" />
          <LuChevronUp className="size-4 hidden hs-collapse-open:block" />
        </button>

        <div
          id={`faq-${item.id}`}
          className="hs-collapse hidden w-full card overflow-hidden transition-[height] duration-300 shadow-md rounded-md"
        >
          <div className="card-body">{item.answer}</div>
        </div>
      </div>
    ));

  return (
    <>
      <h5 className="mb-5 underline text-lg font-semibold text-default-800">
        Popular Ask Questions
      </h5>
      <div className="grid lg:grid-cols-2 gap-5 mb-6">
        <div className="space-y-3">{renderFaqs(leftFaq)}</div>
        <div className="space-y-3">{renderFaqs(rightFaq)}</div>
      </div>
    </>
  );
};

export default FAQAccordion;
