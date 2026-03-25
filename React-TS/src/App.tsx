import 'flatpickr/dist/flatpickr.css';
import 'swiper/swiper-bundle.css';
import '@/assets/css/style.css';
import ProvidersWrapper from './components/ProvidersWrapper';
import AppRoutes from './routes';

const App = () => {
  return (
    <ProvidersWrapper>
      <AppRoutes />
    </ProvidersWrapper>
  );
};

export default App;
