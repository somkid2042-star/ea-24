import type { IconType } from 'react-icons/lib';
import {
  LuCircuitBoard,
  LuMonitorDot,
  LuBrain,
  LuChartLine,
  LuBot,
} from 'react-icons/lu';

export type MenuItemType = {
  key: string;
  label: string;
  isTitle?: boolean;
  href?: string;
  children?: MenuItemType[];

  icon?: IconType;
  parentKey?: string;
  target?: string;
  isDisabled?: boolean;
};

export const menuItemsData: MenuItemType[] = [
  {
    key: 'Dashboard',
    label: 'Dashboard',
    icon: LuMonitorDot,
    href: '/',
  },
  {
    key: 'Dashboard AI',
    label: 'Dashboard AI',
    icon: LuBot,
    href: '/ai/dashboard',
  },
  {
    key: 'Config Server',
    label: 'Config Server',
    icon: LuCircuitBoard,
    children: [
      { key: 'MT5 Settings', label: 'MT5 Settings', href: '/config/mt5' },
      { key: 'Server Settings', label: 'Server Settings', href: '/config/server' },
      { key: 'Database Settings', label: 'Database Settings', href: '/config/database' },
      { key: 'Security & License', label: 'Security & License', href: '/config/security' },
      { key: 'AI Settings', label: '🤖 AI Settings', href: '/config/ai' },
    ],
  },
  {
    key: 'Strategy Config',
    label: 'Strategy Config',
    icon: LuBrain,
    children: [
      { key: 'Strategy List', label: 'Strategy List', href: '/strategy/list' },
      { key: 'Strategy Builder', label: 'Strategy Builder', href: '/strategy/builder' },
      { key: 'Backtest', label: 'Backtest', href: '/strategy/backtest' },
    ],
  },
  {
    key: 'Trade Config',
    label: 'Trade Config',
    icon: LuChartLine,
    children: [
      { key: 'Active Trades', label: 'Active Trades', href: '/trade/active' },
      { key: 'Trade Setup', label: 'Trade Setup', href: '/trade/setup' },
      { key: 'Trade History', label: 'Trade History', href: '/trade/history' },
    ],
  },
];
