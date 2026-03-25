import PageMeta from '@/components/PageMeta';
import About from './components/About';
import Contact from './components/Contact';
import Feature from './components/Feature';
import Footer from './components/Footer';
import Hero from './components/Hero';
import Navbar from './components/Navbar';
import Pricing from './components/Pricing';
import Works from './components/Works';

const Index = () => {
  return (
    <>
      <PageMeta title="One Page Landing" />
      <Navbar />
      <Hero />
      <Feature />
      <Works />
      <About />
      <Pricing />
      <Contact />
      <Footer />
    </>
  );
};

export default Index;
