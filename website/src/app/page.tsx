import Navbar from "@/components/Navbar";
import Hero from "@/components/Hero";
import FeaturesOverview from "@/components/FeaturesOverview";
import CloudsSection from "@/components/CloudsSection";
import ProvidersSection from "@/components/ProvidersSection";
import FeatureGrid from "@/components/FeatureGrid";
import HowItWorks from "@/components/HowItWorks";
import SecuritySection from "@/components/SecuritySection";
import InstallSection from "@/components/InstallSection";
import Footer from "@/components/Footer";

export default function Home() {
  return (
    <>
      <Navbar />
      <main>
        <Hero />
        <FeaturesOverview />
        <CloudsSection />
        <ProvidersSection />
        <FeatureGrid />
        <HowItWorks />
        <SecuritySection />
        <InstallSection />
      </main>
      <Footer />
    </>
  );
}
