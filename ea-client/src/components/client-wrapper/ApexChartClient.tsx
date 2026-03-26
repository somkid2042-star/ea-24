import type { ApexOptions } from 'apexcharts';
import { useMemo } from 'react';
import ReactApexChart from 'react-apexcharts';

type PropsType = {
  type?: 'line' | 'area' | 'bar' | 'pie' | 'donut' | 'radialBar' | 'scatter' | 'bubble' | 'heatmap' | 'candlestick' | 'boxPlot' | 'radar' | 'polarArea' | 'rangeBar' | 'rangeArea' | 'treemap';
  height?: number | string;
  width?: number | string;
  getOptions: () => ApexOptions;
  series: ApexOptions['series'];
  className?: string;
};

const ApexChartClient = ({
  type,
  height,
  width = '100%',
  getOptions,
  series,
  className,
}: PropsType) => {
  const options = useMemo(() => getOptions(), []);

  return (
    <ReactApexChart
      type={type}
      height={height}
      width={width}
      options={options}
      series={series}
      className={className}
    />
  );
};

export default ApexChartClient;
