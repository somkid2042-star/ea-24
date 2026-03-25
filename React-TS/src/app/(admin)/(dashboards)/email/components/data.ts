import type { ApexOptions } from 'apexcharts';

export const getSentEmail = (): ApexOptions => ({
  series: [
    {
      name: 'Sent',
      data: [14, 20, 10, 5, 11, 30, 24, 26, 33, 38, 34, 27, 22],
    },
  ],
  chart: {
    id: 'area-datetime',
    type: 'line',
    height: 80,
    sparkline: {
      enabled: true,
    },
    zoom: {
      autoScaleYaxis: true,
    },
  },
  colors: ['#2b7fff', '#00c951'],
  stroke: {
    width: 2,
    curve: 'smooth',
  },
  dataLabels: {
    enabled: false,
  },
});

export const getOpenRate = (): ApexOptions => ({
  series: [
    {
      name: 'Open Rate',
      data: [38, 34, 27, 22, 14, 20, 10, 5, 11, 30, 24, 26, 33],
    },
  ],
  chart: {
    id: 'area-datetime',
    type: 'line',
    height: 80,
    sparkline: {
      enabled: true,
    },
    zoom: {
      autoScaleYaxis: true,
    },
  },
  colors: ['#00c951'],
  stroke: {
    width: 2,
    curve: 'smooth',
  },
  dataLabels: {
    enabled: false,
  },
});

export const getClickRate = (): ApexOptions => ({
  series: [
    {
      name: 'Click Rate',
      data: [30, 24, 14, 20, 10, 5, 11, 26, 33, 38, 34, 27, 22],
    },
  ],
  chart: {
    id: 'area-datetime',
    type: 'line',
    height: 80,
    sparkline: {
      enabled: true,
    },
    zoom: {
      autoScaleYaxis: true,
    },
  },
  colors: ['#ff6900'],
  stroke: {
    width: 2,
    curve: 'smooth',
  },
  dataLabels: {
    enabled: false,
  },
});
export const getClickThrough = (): ApexOptions => ({
  series: [
    {
      name: 'Delivered Rate',
      data: [11, 30, 24, 26, 33, 38, 14, 20, 10, 9, 34, 27, 22],
    },
  ],
  chart: {
    id: 'area-datetime',
    type: 'bar',
    height: 80,
    sparkline: {
      enabled: true,
    },
    zoom: {
      autoScaleYaxis: true,
    },
  },
  colors: ['#2b7fff'],
  stroke: {
    width: 1,
    curve: 'smooth',
  },
  dataLabels: {
    enabled: false,
  },
});

export const getDeliveredRate = (): ApexOptions => ({
  series: [
    {
      name: 'Delivered Rate',
      data: [11, 30, 24, 26, 33, 38, 14, 20, 10, 9, 34, 27, 22],
    },
  ],
  chart: {
    id: 'area-datetime',
    type: 'bar',
    height: 80,
    sparkline: {
      enabled: true,
    },
    zoom: {
      autoScaleYaxis: true,
    },
  },
  colors: ['#2b7fff'],
  stroke: {
    width: 1,
    curve: 'smooth',
  },
  dataLabels: {
    enabled: false,
  },
});

export const getHardBounceRate = (): ApexOptions => ({
  series: [
    {
      name: 'Hard Bounce Rate',
      data: [14, 20, 10, 5, 11, 30, 24, 26, 33, 38, 34, 27, 22],
    },
  ],
  chart: {
    id: 'area-datetime',
    type: 'bar',
    height: 80,
    sparkline: {
      enabled: true,
    },
    zoom: {
      autoScaleYaxis: true,
    },
  },
  colors: ['#00c951'],
  stroke: {
    width: 2,
    curve: 'smooth',
  },
  dataLabels: {
    enabled: false,
  },
});

export const getUnsubscribedRate = (): ApexOptions => ({
  series: [
    {
      name: 'Unsubscribed Rate',
      data: [38, 34, 27, 22, 14, 20, 10, 5, 11, 30, 24, 26, 33],
    },
  ],
  chart: {
    id: 'area-datetime',
    type: 'bar',
    height: 80,
    sparkline: {
      enabled: true,
    },
    zoom: {
      autoScaleYaxis: true,
    },
  },
  colors: ['var(--color-yellow-500)'],
  stroke: {
    width: 2,
    curve: 'smooth',
  },
  dataLabels: {
    enabled: false,
  },
});

export const getSpanReportRate = (): ApexOptions => ({
  series: [
    {
      name: 'Spam Report Rate',
      data: [30, 24, 14, 20, 10, 13, 11, 26, 33, 38, 34, 27, 22],
    },
  ],
  chart: {
    id: 'area-datetime',
    type: 'bar',
    height: 80,
    sparkline: {
      enabled: true,
    },
    zoom: {
      autoScaleYaxis: true,
    },
  },
  colors: ['var(--color-purple-500)'],
  stroke: {
    width: 2,
    curve: 'smooth',
  },
  dataLabels: {
    enabled: false,
  },
});

export const getEmailDataChart = (): ApexOptions => ({
  series: [
    {
      name: 'Open Rate',
      data: [28, 29, 31, 36, 32, 32, 33, 40, 37],
    },
    {
      name: 'Click Rate',
      data: [26, 41, 40, 51, 49, 62, 69, 52, 58],
    },
  ],
  chart: {
    height: 333,
    type: 'line',
    dropShadow: {
      enabled: true,
      color: '#000',
      top: 18,
      left: 7,
      blur: 10,
      opacity: 0.2,
    },
    toolbar: {
      show: false,
    },
  },
  colors: ['#2b7fff', 'var(--color-purple-500)'],
  stroke: {
    curve: 'smooth',
    width: 3,
  },
  markers: {
    size: 5,
    hover: {
      sizeOffset: 1,
    },
  },
  xaxis: {
    categories: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep'],
  },
  legend: {
    position: 'top',
    horizontalAlign: 'right',
    floating: true,
    offsetY: -15,
    show: true,
    // offsetX: -5
  },
});

export const getEmailMarketingChart = (): ApexOptions => ({
  series: [44, 55, 67],
  chart: {
    height: 370,
    type: 'radialBar',
  },
  legend: {
    show: false,
  },
  plotOptions: {
    radialBar: {
      dataLabels: {
        name: {
          fontSize: '22px',
        },
        value: {
          fontSize: '16px',
        },
        total: {
          show: true,
          label: 'Total',
          formatter: function () {
            return '249';
          },
        },
      },
      track: {
        margin: 14,
      },
    },
  },
  colors: ['#2b7fff', '#00c951', '#ff6900'],
  labels: ['Sent', 'Opened', 'Not Opened'],
});
