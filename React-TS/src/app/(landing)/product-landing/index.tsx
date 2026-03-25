import PageMeta from '@/components/PageMeta';
import About from './components/About';
import Cta from './components/Cta';
import Customer from './components/Customer';
import Features from './components/Features';
import Footer from './components/Footer';
import Hero from './components/Hero';
import Navbar from './components/Navbar';
import Product from './components/Product';

const Index = () => {
  return (
    <>
      <PageMeta title="Product Landing" />
      <Navbar />
      <Hero />
      <Product />
      <Features />
      <About />
      <Customer />
      <Cta />
      <Footer />
    </>
  );
};

export default Index;
