import type { ApexOptions } from 'apexcharts';

export const getPresPectiveChart = (): ApexOptions => ({
  series: [
    {
      data: [
        {
          x: 'React',
          y: 218,
        },
        {
          x: 'TailwindCSS',
          y: 187,
        },
        {
          x: 'Angular',
          y: 134,
        },
        {
          x: 'Vue Js',
          y: 55,
        },
        {
          x: 'Laravel',
          y: 99,
        },
        {
          x: 'PHP',
          y: 34,
        },
        {
          x: 'ASP.Net',
          y: 86,
        },
        {
          x: 'Django',
          y: 30,
        },
        {
          x: 'CI',
          y: 44,
        },
      ],
    },
  ],
  legend: {
    show: false,
  },
  chart: {
    height: 252,
    type: 'treemap',
    toolbar: {
      show: false,
    },
    parentHeightOffset: 0,
  },
  xaxis: {
    // show: false,
  },
  grid: {
    show: false,
    padding: {
      top: -15,
      right: 0,
      bottom: 0,
      left: 0,
    },
  },
  colors: ['#2b7fff'],
});

export const getLocationChart = (): ApexOptions => ({
  series: [
    {
      name: 'Response Times',
      data: [10, 41, 35, 51, 49, 62, 69, 91, 148],
    },
  ],
  chart: {
    height: 350,
    type: 'line',
    zoom: {
      enabled: false,
    },
    // margin: {

    //     left: 0,
    //     right: 0,
    //     top: 0,
    //     bottom: 0
    // },
    toolbar: {
      show: false,
    },
  },
  stroke: {
    show: true,
    curve: 'smooth',
    lineCap: 'butt',
    width: 2,
    dashArray: 0,
  },
  dataLabels: {
    enabled: false,
  },
  colors: ['#2b7fff'],
  xaxis: {
    categories: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep'],
  },
});

export const getPagesInteraction = (): ApexOptions => ({
  series: [
    {
      name: 'Viewers',
      data: [20, 13, 19, 23, 29, 42, 33, 29, 37, 46, 40, 49],
    },
  ],
  chart: {
    height: 350,
    type: 'bar',
    toolbar: {
      show: false,
    },
  },
  plotOptions: {
    bar: {
      borderRadius: 10,
      dataLabels: {
        position: 'top', // top, center, bottom
      },
    },
  },
  dataLabels: {
    enabled: true,
    offsetY: -20,
    style: {
      fontSize: '12px',
      colors: ['#304758'],
    },
  },

  xaxis: {
    categories: [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ],
    position: 'bottom',
    axisBorder: {
      show: false,
    },
    axisTicks: {
      show: false,
    },
    crosshairs: {
      fill: {
        type: 'gradient',
        gradient: {
          colorFrom: '#D8E3F0',
          colorTo: '#BED1E6',
          stops: [0, 100],
          opacityFrom: 0.4,
          opacityTo: 0.5,
        },
      },
    },
    tooltip: {
      enabled: true,
    },
  },
  yaxis: {
    axisBorder: {
      show: false,
    },
    axisTicks: {
      show: false,
    },
    labels: {
      show: false,
    },
  },
  stroke: {
    show: true,
    width: 4,
    colors: ['transparent'],
  },
  grid: {
    show: false,
    padding: {
      top: 0,
      right: 0,
      bottom: 0,
      left: -10,
    },
  },
  colors: ['#2b7fff', '#00c951'],
});

export const getUserDeviceChart = (): ApexOptions => ({
  series: [
    {
      name: 'Desktop',
      data: [80, 50, 30, 40, 100, 20],
    },
    {
      name: 'Mobile',
      data: [20, 30, 40, 80, 20, 80],
    },
    {
      name: 'Others',
      data: [44, 76, 78, 13, 43, 10],
    },
  ],
  chart: {
    height: 230,
    type: 'radar',
    dropShadow: {
      enabled: true,
      blur: 1,
      left: 1,
      top: 1,
    },
    toolbar: {
      show: false,
    },
  },
  stroke: {
    width: 2,
  },
  fill: {
    opacity: 0.1,
  },
  markers: {
    size: 0,
  },
  responsive: [
    {
      breakpoint: 480,
      options: {
        legend: {
          show: false,
        },
      },
    },
  ],
  colors: ['#2b7fff', '#22c55e', '#f97316'],
  legend: {
    position: 'right',
    offsetY: 0,
    height: 230,
  },
  xaxis: {
    categories: ['2018', '2019', '2020', '2021', '2022', '2023'],
  },
});

export const getSatisfactionChart = (): ApexOptions => ({
  series: [95.33],
  chart: {
    type: 'radialBar',
    height: 445,
    offsetY: -20,
    sparkline: {
      enabled: true,
    },
  },
  plotOptions: {
    radialBar: {
      startAngle: -90,
      endAngle: 90,
      track: {
        strokeWidth: '97%',
        margin: 5, // margin is in pixels
      },

      dataLabels: {
        name: {
          show: false,
        },
        value: {
          offsetY: -5,
          fontSize: '22px',
          fontWeight: '600',
        },
      },
    },
  },
  grid: {
    padding: {
      top: -10,
    },
  },
  colors: ['#2b7fff'],
  fill: {
    type: 'gradient',
    gradient: {
      shade: 'light',
      shadeIntensity: 0.4,
      inverseColors: false,
      opacityFrom: 1,
      opacityTo: 1,
      stops: [0, 50, 53, 91],
    },
  },
  stroke: {
    dashArray: 4,
  },
  labels: ['Average Results'],
});

export const getDailyVisitInsightsChart = (): ApexOptions => ({
  series: [
    {
      name: 'Male',
      data: [55, 41, 67, 22, 43, 21, 33, 45],
    },
    {
      name: 'Female',
      data: [55, 41, 67, 22, 43, 21, 33, 45],
    },
  ],
  annotations: {
    points: [
      {
        x: 'Bananas',
        seriesIndex: 0,
        label: {
          borderColor: '#2b7fff',
          offsetY: 0,
          style: {
            color: '#fff',
            background: '#2b7fff',
          },
          text: 'Bananas are good',
        },
      },
    ],
  },
  colors: ['#00c951', '#a855f7'],
  chart: {
    height: 245,
    type: 'bar',
    toolbar: {
      show: false,
    },
  },
  plotOptions: {
    bar: {
      borderRadius: 10,
      columnWidth: '70%',
    },
  },
  dataLabels: {
    enabled: false,
  },
  stroke: {
    width: 2,
  },
  xaxis: {
    labels: {
      rotate: -45,
    },
    categories: ['May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
    tickPlacement: 'on',
  },
  fill: {
    type: 'gradient',
    gradient: {
      shade: 'light',
      type: 'horizontal',
      shadeIntensity: 0.25,
      gradientToColors: undefined,
      inverseColors: true,
      opacityFrom: 0.85,
      opacityTo: 0.85,
      stops: [50, 0, 100],
    },
  },
  grid: {
    xaxis: {
      lines: {
        show: true,
      },
    },
    yaxis: {
      lines: {
        show: true,
      },
    },
    padding: {
      top: -10,
      right: -10,
      left: -10,
    },
  },
  yaxis: {
    show: false,
  },
});

export const getAnalyticsReports = (): ApexOptions => ({
  series: [
    {
      name: 'Income - 2023',
      data: [28, 29, 33, 36, 32],
    },
    {
      name: 'Expense - 2023',
      data: [20, 17, 21, 29, 23],
    },
  ],
  chart: {
    height: 260,
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
  colors: ['#2b7fff', '#00c951'],

  dataLabels: {
    enabled: true,
  },
  stroke: {
    curve: 'smooth',
  },
  markers: {
    size: 1,
  },
  yaxis: {
    show: false,
  },
  xaxis: {
    categories: ['Mar', 'Apr', 'May', 'Jun', 'Jul'],
  },
  legend: {
    position: 'top',
    horizontalAlign: 'right',
    floating: true,
    offsetY: -25,
    offsetX: -5,
  },
  grid: {
    xaxis: {
      lines: {
        show: false,
      },
    },
    yaxis: {
      lines: {
        show: false,
      },
    },
    padding: {
      top: -25,
    },
  },
});

export const getSubscriptionDistribution = (): ApexOptions => ({
  series: [44, 55, 41, 17, 15],
  labels: ['Beginner', 'Intermediate', 'Enterprise', 'VIP', 'Professional'],
  chart: {
    height: 290,
    type: 'donut',
  },
  plotOptions: {
    pie: {
      startAngle: -90,
      donut: {
        size: '75%',
      },
    },
  },
  dataLabels: {
    enabled: false,
  },
  fill: {
    type: 'gradient',
  },
  colors: ['#2b7fff', '#f97316', '#00c951', '#facc15', '#a855f7'],
  legend: {
    formatter: function (val, opts) {
      return val + ' - ' + opts.w.globals.series[opts.seriesIndex];
    },

    position: 'bottom',
  },
});
