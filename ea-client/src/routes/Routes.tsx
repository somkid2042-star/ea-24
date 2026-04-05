import { lazy } from 'react';
import type { RouteProps } from 'react-router-dom';

const TradingDashboard = lazy(() => import('@/app/(admin)/(dashboards)/trading'));
const OpenClawDashboard = lazy(() => import('@/app/(admin)/(dashboards)/dashboard-ai'));
const MT5Settings = lazy(() => import('@/app/(admin)/(config)/mt5'));
const ServerSettings = lazy(() => import('@/app/(admin)/(config)/server'));
const DatabaseSettings = lazy(() => import('@/app/(admin)/(config)/database'));
const SecuritySettings = lazy(() => import('@/app/(admin)/(config)/security'));
const AiSettings = lazy(() => import('@/app/(admin)/(config)/ai-settings'));
const EmailSettings = lazy(() => import('@/app/(admin)/(config)/email-settings'));

const StrategyBuilder = lazy(() => import('@/app/(admin)/(config)/strategy-builder'));
const StrategyBacktest = lazy(() => import('@/app/(admin)/(config)/strategy-backtest'));
const ActiveTrades = lazy(() => import('@/app/(admin)/(config)/trade-active'));
const TradeSetup = lazy(() => import('@/app/(admin)/(config)/trade-setup'));
const TradeHistory = lazy(() => import('@/app/(admin)/(config)/trade-history'));

export type RoutesProps = { path: RouteProps['path']; element: RouteProps['element']; name: string };

export const layoutsRoutes: RoutesProps[] = [
  { path: '/', element: <TradingDashboard />, name: 'Dashboard' },
  { path: '/ai/dashboard', element: <OpenClawDashboard />, name: 'Dashboard AI' },
  { path: '/config/mt5', element: <MT5Settings />, name: 'MT5 Settings' },
  { path: '/config/server', element: <ServerSettings />, name: 'Server Settings' },
  { path: '/config/database', element: <DatabaseSettings />, name: 'Database Settings' },
  { path: '/config/security', element: <SecuritySettings />, name: 'Security & License' },
  { path: '/config/ai', element: <AiSettings />, name: 'AI Settings' },
  { path: '/config/email', element: <EmailSettings />, name: 'Email Settings' },

  { path: '/strategy/builder', element: <StrategyBuilder />, name: 'Strategy Builder' },
  { path: '/strategy/backtest', element: <StrategyBacktest />, name: 'Backtest' },
  { path: '/trade/active', element: <ActiveTrades />, name: 'Active Trades' },
  { path: '/trade/setup', element: <TradeSetup />, name: 'Trade Setup' },
  { path: '/trade/history', element: <TradeHistory />, name: 'Trade History' },
];

export const singlePageRoutes: RoutesProps[] = [];
