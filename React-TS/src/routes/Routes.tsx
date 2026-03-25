import { lazy } from 'react';

// admin Ecommerce

const Cart = lazy(() => import('@/app/(admin)/(app)/(ecommerce)/cart'));
const Checkout = lazy(() => import('@/app/(admin)/(app)/(ecommerce)/checkout'));
const OrderOverview = lazy(() => import('@/app/(admin)/(app)/(ecommerce)/order-overview'));
const Orders = lazy(() => import('@/app/(admin)/(app)/(ecommerce)/orders'));
const ProductCreate = lazy(() => import('@/app/(admin)/(app)/(ecommerce)/product-create'));
const ProductGrid = lazy(() => import('@/app/(admin)/(app)/(ecommerce)/product-grid'));
const ProductList = lazy(() => import('@/app/(admin)/(app)/(ecommerce)/product-list'));
const ProductOverview = lazy(() => import('@/app/(admin)/(app)/(ecommerce)/product-overview'));
const Sellers = lazy(() => import('@/app/(admin)/(app)/(ecommerce)/sellers'));

// admin Hr

const Attendances = lazy(() => import('@/app/(admin)/(app)/(hr)/attendance'));
const AttemdanceMain = lazy(() => import('@/app/(admin)/(app)/(hr)/attendance-main'));
const CreateLeave = lazy(() => import('@/app/(admin)/(app)/(hr)/create-leave'));
const CreateLeaveEmployee = lazy(() => import('@/app/(admin)/(app)/(hr)/create-leave-employee'));
const CreatePayslip = lazy(() => import('@/app/(admin)/(app)/(hr)/create-payslip'));
const Department = lazy(() => import('@/app/(admin)/(app)/(hr)/department'));
const Employee = lazy(() => import('@/app/(admin)/(app)/(hr)/employee'));
const Holidays = lazy(() => import('@/app/(admin)/(app)/(hr)/holidays'));
const Leave = lazy(() => import('@/app/(admin)/(app)/(hr)/leave'));
const LeaveEmployee = lazy(() => import('@/app/(admin)/(app)/(hr)/leave-employee'));
const PayrollEmplyoeeSalary = lazy(
  () => import('@/app/(admin)/(app)/(hr)/payroll-employee-salary')
);
const PayRollSlip = lazy(() => import('@/app/(admin)/(app)/(hr)/payroll-payslip'));
const SalesEstimate = lazy(() => import('@/app/(admin)/(app)/(hr)/sales-estimates'));
const SalesExpense = lazy(() => import('@/app/(admin)/(app)/(hr)/sales-expenses'));
const SalePayment = lazy(() => import('@/app/(admin)/(app)/(hr)/sales-payments'));

// admin invoice

const InvoiceAddNew = lazy(() => import('@/app/(admin)/(app)/(invoice)/add-new'));
const InvoiceList = lazy(() => import('@/app/(admin)/(app)/(invoice)/list'));
const InvoiceOverview = lazy(() => import('@/app/(admin)/(app)/(invoice)/overview'));

// USers

const UserGrid = lazy(() => import('@/app/(admin)/(app)/(users)/users-grid'));
const UserList = lazy(() => import('@/app/(admin)/(app)/(users)/users-list'));

const Calender = lazy(() => import('@/app/(admin)/(app)/calendar'));
const Chat = lazy(() => import('@/app/(admin)/(app)/chat'));
const MailBox = lazy(() => import('@/app/(admin)/(app)/mailbox'));
const Notes = lazy(() => import('@/app/(admin)/(app)/notes'));

// dashboard
const Analytics = lazy(() => import('@/app/(admin)/(dashboards)/analytics'));
const Email = lazy(() => import('@/app/(admin)/(dashboards)/email'));
const Hr = lazy(() => import('@/app/(admin)/(dashboards)/hr'));
const Ecommerce = lazy(() => import('@/app/(admin)/(dashboards)/index'));

// layouts
const DarkMode = lazy(() => import('@/app/(admin)/(layouts)/dark-mode'));
const RTL = lazy(() => import('@/app/(admin)/(layouts)/rtl-mode'));
const SideNavCompact = lazy(() => import('@/app/(admin)/(layouts)/sidenav-compact'));
const SideNavDark = lazy(() => import('@/app/(admin)/(layouts)/sidenav-dark'));
const SideNavHidden = lazy(() => import('@/app/(admin)/(layouts)/sidenav-hidden'));
const SideNavHover = lazy(() => import('@/app/(admin)/(layouts)/sidenav-hover'));
const SideNavHoverActive = lazy(() => import('@/app/(admin)/(layouts)/sidenav-hover-active'));
const SideOffcanvas = lazy(() => import('@/app/(admin)/(layouts)/sidenav-offcanvas'));
const SideNavSmall = lazy(() => import('@/app/(admin)/(layouts)/sidenav-small'));

//Pages

const Faq = lazy(() => import('@/app/(admin)/(pages)/faqs'));
const Pricing = lazy(() => import('@/app/(admin)/(pages)/pricing'));
const Starter = lazy(() => import('@/app/(admin)/(pages)/starter'));
const Timeline = lazy(() => import('@/app/(admin)/(pages)/timeline'));

//auth
const BasicCreatePassword = lazy(() => import('@/app/(auth)/basic-create-password'));
const BasicLogin = lazy(() => import('@/app/(auth)/basic-login'));
const BasicRegister = lazy(() => import('@/app/(auth)/basic-register'));
const BasicResetPassword = lazy(() => import('@/app/(auth)/basic-reset-password'));
const BasicVerifyEmail = lazy(() => import('@/app/(auth)/basic-verify-email'));
const BasicLogout = lazy(() => import('@/app/(auth)/basic-logout'));
const BasicTwoStep = lazy(() => import('@/app/(auth)/basic-two-steps'));

const BoxedCreatePassword = lazy(() => import('@/app/(auth)/boxed-create-password'));
const BoxedLogin = lazy(() => import('@/app/(auth)/boxed-login'));
const BoxedRegister = lazy(() => import('@/app/(auth)/boxed-register'));
const BoxedResetPassword = lazy(() => import('@/app/(auth)/boxed-reset-password'));
const BoxedLogout = lazy(() => import('@/app/(auth)/boxed-logout'));
const BoxedTwoStep = lazy(() => import('@/app/(auth)/boxed-two-steps'));

const CoverCreatePassword = lazy(() => import('@/app/(auth)/cover-create-password'));
const CoverLogin = lazy(() => import('@/app/(auth)/cover-login'));
const CoverRegister = lazy(() => import('@/app/(auth)/cover-register'));
const CoverResetPassword = lazy(() => import('@/app/(auth)/cover-reset-password'));
const CoverLogout = lazy(() => import('@/app/(auth)/cover-logout'));
const CoverTwoStep = lazy(() => import('@/app/(auth)/cover-two-steps'));
const CoverVerifyEmail = lazy(() => import('@/app/(auth)/cover-verify-email'));

const ModernCreatePassword = lazy(() => import('@/app/(auth)/modern-create-password'));
const ModernLogin = lazy(() => import('@/app/(auth)/modern-login'));
const ModernRegister = lazy(() => import('@/app/(auth)/modern-register'));
const ModernResetPassword = lazy(() => import('@/app/(auth)/modern-reset-password'));
const ModernLogout = lazy(() => import('@/app/(auth)/modern-logout'));
const ModernTwoStep = lazy(() => import('@/app/(auth)/modern-two-steps'));
const ModernVerifyEmail = lazy(() => import('@/app/(auth)/modern-verify-email'));

//  landing

const OnePageLanding = lazy(() => import('@/app/(landing)/onepage-landing'));
const ProductLanding = lazy(() => import('@/app/(landing)/product-landing'));

//Other

const Error404 = lazy(() => import('@/app/(others)/404'));
const CommingSoon = lazy(() => import('@/app/(others)/coming-soon'));
const Maintenance = lazy(() => import('@/app/(others)/maintenance'));
const Offline = lazy(() => import('@/app/(others)/offline'));

export const layoutsRoutes = [
  { path: '/', name: 'Ecommerce', element: <Ecommerce /> },

  { path: '/index', name: 'Ecommerce', element: <Ecommerce /> },
  { path: '/cart', name: 'Cart', element: <Cart /> },
  { path: '/checkout', name: 'Checkout', element: <Checkout /> },
  { path: '/order-overview', name: 'OrderOverview', element: <OrderOverview /> },
  { path: '/orders', name: 'Orders', element: <Orders /> },
  { path: '/product-create', name: 'ProductCreate', element: <ProductCreate /> },
  { path: '/product-grid', name: 'ProductGrid', element: <ProductGrid /> },
  { path: '/product-list', name: 'ProductList', element: <ProductList /> },
  { path: '/product-overview', name: 'ProductOverview', element: <ProductOverview /> },
  { path: '/sellers', name: 'Sellers', element: <Sellers /> },

  { path: '/attendance', name: 'Attendances', element: <Attendances /> },
  { path: '/attendance-main', name: 'AttemdanceMain', element: <AttemdanceMain /> },
  { path: '/create-leave', name: 'CreateLeave', element: <CreateLeave /> },
  { path: '/create-leave-employee', name: 'CreateLeaveEmployee', element: <CreateLeaveEmployee /> },
  { path: '/create-payslip', name: 'CreatePayslip', element: <CreatePayslip /> },
  { path: '/department', name: 'Department', element: <Department /> },
  { path: '/employee', name: 'Employee', element: <Employee /> },
  { path: '/holidays', name: 'Holidays', element: <Holidays /> },
  { path: '/leave', name: 'Leave', element: <Leave /> },
  { path: '/leave-employee', name: 'LeaveEmployee', element: <LeaveEmployee /> },
  {
    path: '/payroll-employee-salary',
    name: 'PayrollEmplyoeeSalary',
    element: <PayrollEmplyoeeSalary />,
  },
  { path: '/payroll-payslip', name: 'PayRollSlip', element: <PayRollSlip /> },
  { path: '/sales-estimates', name: 'SalesEstimate', element: <SalesEstimate /> },
  { path: '/sales-expenses', name: 'SalesExpense', element: <SalesExpense /> },
  { path: '/sales-payments', name: 'SalePayment', element: <SalePayment /> },

  { path: '/add-new', name: 'InvoiceAddNew', element: <InvoiceAddNew /> },
  { path: '/list', name: 'InvoiceList', element: <InvoiceList /> },
  { path: '/overview', name: 'InvoiceOverview', element: <InvoiceOverview /> },

  { path: '/users-grid', name: 'UserGrid', element: <UserGrid /> },
  { path: '/users-list', name: 'UserList', element: <UserList /> },

  { path: '/calendar', name: 'Calender', element: <Calender /> },
  { path: '/chat', name: 'Chat', element: <Chat /> },
  { path: '/mailbox', name: 'MailBox', element: <MailBox /> },
  { path: '/notes', name: 'Notes', element: <Notes /> },

  { path: '/analytics', name: 'Analytics', element: <Analytics /> },
  { path: '/', name: 'Ecommerce', element: <Ecommerce /> },
  { path: '/email', name: 'Email', element: <Email /> },
  { path: '/hr', name: 'Hr', element: <Hr /> },

  { path: '/dark-mode', name: 'DarkMode', element: <DarkMode /> },
  { path: '/rtl-mode', name: 'RtlMode', element: <RTL /> },
  { path: '/sidenav-compact', name: 'SideNavCompact', element: <SideNavCompact /> },
  { path: '/sidenav-dark', name: 'SideNavDark', element: <SideNavDark /> },
  { path: '/sidenav-hidden', name: 'SideNavHidden', element: <SideNavHidden /> },
  { path: '/sidenav-hover', name: 'SideNavHover', element: <SideNavHover /> },
  { path: '/sidenav-offcanvas', name: 'SideNavOffcanvas', element: <SideOffcanvas /> },
  { path: '/sidenav-small', name: 'SideNavSmall', element: <SideNavSmall /> },
  { path: '/sidenav-hover-active', name: 'SideNavHoverActive', element: <SideNavHoverActive /> },

  { path: '/faqs', name: 'Faqs', element: <Faq /> },
  { path: '/pricing', name: 'Pricing', element: <Pricing /> },
  { path: '/starter', name: 'Starter', element: <Starter /> },
  { path: '/timeline', name: 'Timeline', element: <Timeline /> },
];

export const singlePageRoutes = [
  { path: '/basic-login', name: 'BasicLogin', element: <BasicLogin /> },
  { path: '/basic-register', name: 'BasicRegister', element: <BasicRegister /> },
  { path: '/basic-create-password', name: 'BasicCreatePassword', element: <BasicCreatePassword /> },
  { path: '/basic-reset-password', name: 'BasicResetPassword', element: <BasicResetPassword /> },
  { path: '/basic-verify-email', name: 'BasicVerifyEmail', element: <BasicVerifyEmail /> },
  { path: '/basic-logout', name: 'BasicLogout', element: <BasicLogout /> },
  { path: '/basic-two-steps', name: 'BasicTwoStep', element: <BasicTwoStep /> },

  { path: '/boxed-login', name: 'BoxedLogin', element: <BoxedLogin /> },
  { path: '/boxed-register', name: 'BoxedRegister', element: <BoxedRegister /> },
  { path: '/boxed-create-password', name: 'BoxedCreatePassword', element: <BoxedCreatePassword /> },
  { path: '/boxed-reset-password', name: 'BoxedResetPassword', element: <BoxedResetPassword /> },
  { path: '/boxed-logout', name: 'BoxedLogout', element: <BoxedLogout /> },
  { path: '/boxed-two-steps', name: 'BoxedTwoStep', element: <BoxedTwoStep /> },

  { path: '/cover-login', name: 'CoverLogin', element: <CoverLogin /> },
  { path: '/cover-register', name: 'CoverRegister', element: <CoverRegister /> },
  { path: '/cover-create-password', name: 'CoverCreatePassword', element: <CoverCreatePassword /> },
  { path: '/cover-reset-password', name: 'CoverResetPassword', element: <CoverResetPassword /> },
  { path: '/cover-logout', name: 'CoverLogout', element: <CoverLogout /> },
  { path: '/cover-two-steps', name: 'CoverTwoStep', element: <CoverTwoStep /> },
  { path: '/cover-verify-email', name: 'CoverVerifyEmail', element: <CoverVerifyEmail /> },

  {
    path: '/modern-create-password',
    name: 'ModernCreatePassword',
    element: <ModernCreatePassword />,
  },
  { path: '/modern-login', name: 'ModernLogin', element: <ModernLogin /> },
  { path: '/modern-register', name: 'ModernRegister', element: <ModernRegister /> },
  { path: '/modern-reset-password', name: 'ModernResetPassword', element: <ModernResetPassword /> },
  { path: '/modern-logout', name: 'ModernLogout', element: <ModernLogout /> },
  { path: '/modern-verify-email', name: 'ModernVerifyEmail', element: <ModernVerifyEmail /> },
  { path: '/modern-two-steps', name: 'ModernTwoStep', element: <ModernTwoStep /> },

  { path: '/onepage-landing', name: 'OnePageLanding', element: <OnePageLanding /> },
  { path: '/product-landing', name: 'ProductLanding', element: <ProductLanding /> },

  { path: '/404', name: '404', element: <Error404 /> },
  { path: '/coming-soon', name: 'ComingSoon', element: <CommingSoon /> },
  { path: '/maintenance', name: 'Maintenance', element: <Maintenance /> },
  { path: '/offline', name: 'Offline', element: <Offline /> },
];
