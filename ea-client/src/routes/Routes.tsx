import { lazy } from 'react';
import type { RouteProps } from 'react-router-dom';

const TradingDashboard = lazy(() => import('@/app/(admin)/(dashboards)/trading'));
const MT5Settings = lazy(() => import('@/app/(admin)/(config)/mt5'));
const ServerSettings = lazy(() => import('@/app/(admin)/(config)/server'));
const DatabaseSettings = lazy(() => import('@/app/(admin)/(config)/database'));
const SecuritySettings = lazy(() => import('@/app/(admin)/(config)/security'));
const StrategyList = lazy(() => import('@/app/(admin)/(config)/strategy-list'));
const StrategyBuilder = lazy(() => import('@/app/(admin)/(config)/strategy-builder'));
const StrategyBacktest = lazy(() => import('@/app/(admin)/(config)/strategy-backtest'));
const ActiveTrades = lazy(() => import('@/app/(admin)/(config)/trade-active'));
const TradeSetup = lazy(() => import('@/app/(admin)/(config)/trade-setup'));

export type RoutesProps = { path: RouteProps['path']; element: RouteProps['element']; name: string };

export const layoutsRoutes: RoutesProps[] = [
  { path: '/', element: <TradingDashboard />, name: 'Dashboard' },
  { path: '/config/mt5', element: <MT5Settings />, name: 'MT5 Settings' },
  { path: '/config/server', element: <ServerSettings />, name: 'Server Settings' },
  { path: '/config/database', element: <DatabaseSettings />, name: 'Database Settings' },
  { path: '/config/security', element: <SecuritySettings />, name: 'Security & License' },
  { path: '/strategy/list', element: <StrategyList />, name: 'Strategy List' },
  { path: '/strategy/builder', element: <StrategyBuilder />, name: 'Strategy Builder' },
  { path: '/strategy/backtest', element: <StrategyBacktest />, name: 'Backtest' },
  { path: '/trade/active', element: <ActiveTrades />, name: 'Active Trades' },
  { path: '/trade/setup', element: <TradeSetup />, name: 'Trade Setup' },
];

export const singlePageRoutes: RoutesProps[] = [];
