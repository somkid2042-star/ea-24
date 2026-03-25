import type { ApexOptions } from 'apexcharts';

export const getTotalEmployee = (): ApexOptions => ({
  series: [10],
  chart: {
    height: 110,
    type: 'radialBar',
    parentHeightOffset: 0,
    sparkline: {
      enabled: true,
    },
  },
  plotOptions: {
    radialBar: {
      hollow: {
        margin: 0,
        size: '50%',
      },
      track: {
        margin: 2,
      },
      dataLabels: {
        show: false,
      },
    },
  },
  grid: {
    padding: {
      top: -15,
      bottom: -15,
    },
  },
  stroke: {
    lineCap: 'round',
  },
  labels: ['Total Employee'],
  colors: ['#2b7fff'],
});

export const getTotalApplication = (): ApexOptions => ({
  series: [60],
  chart: {
    height: 110,
    type: 'radialBar',
    sparkline: {
      enabled: true,
    },
  },
  plotOptions: {
    radialBar: {
      hollow: {
        margin: 0,
        size: '50%',
      },
      track: {
        margin: 2,
      },
      dataLabels: {
        show: false,
      },
    },
  },
  grid: {
    padding: {
      top: -15,
      bottom: -15,
    },
  },
  stroke: {
    lineCap: 'round',
  },
  labels: ['Total Employee'],
  colors: ['var(--color-purple-500)'],
});

export const getHiredCandidates = (): ApexOptions => ({
  series: [25],
  chart: {
    height: 110,
    type: 'radialBar',
    sparkline: {
      enabled: true,
    },
  },
  plotOptions: {
    radialBar: {
      hollow: {
        margin: 0,
        size: '50%',
      },
      track: {
        margin: 2,
      },
      dataLabels: {
        show: false,
      },
    },
  },
  grid: {
    padding: {
      top: -15,
      bottom: -15,
    },
  },
  stroke: {
    lineCap: 'round',
  },
  labels: ['Total Employee'],
  colors: ['#00c951'],
});

export const getRjectedCandidates = (): ApexOptions => ({
  series: [75],
  chart: {
    height: 110,
    type: 'radialBar',
    sparkline: {
      enabled: true,
    },
  },
  plotOptions: {
    radialBar: {
      hollow: {
        margin: 0,
        size: '50%',
      },
      track: {
        margin: 2,
      },
      dataLabels: {
        show: false,
      },
    },
  },
  grid: {
    padding: {
      top: -15,
      bottom: -15,
    },
  },
  stroke: {
    lineCap: 'round',
  },
  labels: ['Total Employee'],
  colors: ['#ff6900'],
});

export const getApplicationReceivedChart = (): ApexOptions => ({
  series: [
    {
      name: 'Total Application',
      type: 'area',
      data: [44, 55, 41, 67, 22, 43, 21, 41, 56, 27, 43],
    },
    {
      name: 'Hired Candidates',
      type: 'line',
      data: [30, 25, 36, 30, 45, 35, 64, 52, 59, 36, 39],
    },
  ],
  chart: {
    height: 312,
    type: 'line',
    stacked: false,

    toolbar: {
      show: false,
    },
  },
  stroke: {
    width: [2, 2],
    curve: 'smooth',
  },
  plotOptions: {
    bar: {
      columnWidth: '50%',
    },
  },

  fill: {
    opacity: [0.03, 1],
    gradient: {
      inverseColors: false,
      shade: 'light',
      type: 'vertical',
      opacityFrom: 0.85,
      opacityTo: 0.55,
      stops: [0, 100, 100, 100],
    },
  },
  labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
  colors: ['#2b7fff', '#00c951'],
  markers: {
    size: 0,
  },
  grid: {
    padding: {
      top: -15,
      right: 0,
    },
  },
  tooltip: {
    shared: true,
    intersect: false,
    y: {
      formatter: function (y) {
        if (typeof y !== 'undefined') {
          return y.toFixed(0) + ' points';
        }
        return y;
      },
    },
  },
});
export const getTotalProjectChart = (): ApexOptions => ({
  series: [
    {
      name: 'New',
      data: [44, 55, 41, 67, 22, 43, 14, 55, 41],
    },
    {
      name: 'Pending',
      data: [13, 23, 20, 8, 13, 27, 8, 20, 8],
    },
    {
      name: 'Completed',
      data: [11, 17, 15, 15, 21, 14, 24, 11, 17],
    },
    {
      name: 'Rejected',
      data: [21, 7, 25, 13, 22, 8, 13, 7, 25],
    },
  ],
  chart: {
    type: 'bar',
    height: 353,
    stacked: true,
    zoom: {
      enabled: true,
    },
    toolbar: {
      show: false,
    },
    parentHeightOffset: 0,
  },
  plotOptions: {
    bar: {
      horizontal: false,
      borderRadius: 2,
      columnWidth: '25%',
    },
  },
  grid: {
    padding: {
      top: -15,
      bottom: 5,
      right: 0,
    },
  },
  xaxis: {
    categories: ['01', '02', '03', '04', '05', '06', '07', '08', '09'],
  },
  dataLabels: {
    enabled: false,
  },
  colors: ['#2b7fff', '#facc15', '#4ade80', '#f87171'],
  legend: {
    position: 'bottom',
  },
  fill: {
    opacity: 1,
  },
});
