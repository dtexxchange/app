import React from 'react';
import { useAuth } from '../context/AuthContext';
import UserDashboard from '../components/UserDashboard';
import AdminDashboard from '../components/AdminDashboard';
import { LogOut, Diamond } from 'lucide-react';
import { motion } from 'framer-motion';

const Home: React.FC = () => {
  const { user, logout } = useAuth();

  if (!user) return null;

  return (
    <div className="min-h-screen bg-bg-dark selection:bg-primary/30">
      {/* Premium Navbar */}
      <nav className="sticky top-0 z-50 border-b border-white/5 bg-bg-dark/80 backdrop-blur-xl">
        <div className="max-w-7xl mx-auto px-6 h-20 flex items-center justify-between">
          <div className="flex items-center gap-3 group cursor-pointer">
            <div className="w-10 h-10 bg-[#00ff9d]/10 group-hover:bg-[#00ff9d]/20 transition-colors rounded-xl flex items-center justify-center border border-[#00ff9d]/20 shadow-[0_0_15px_rgba(0,255,157,0.1)]">
              <Diamond className="text-[#00ff9d] w-5 h-5 group-hover:scale-110 transition-transform" />
            </div>
            <span className="font-outfit font-bold text-2xl tracking-tight text-white group-hover:text-[#00ff9d] transition-colors">
              USDT<span className="text-white/50">.EX</span>
            </span>
          </div>

          <div className="flex items-center gap-6">
            <div className="hidden md:flex flex-col items-end justify-center">
              <span className="text-sm font-medium text-white">{user.email}</span>
              <span className={`text-[10px] font-bold uppercase tracking-widest mt-0.5 ${user.role === 'ADMIN' ? 'text-[#00ff9d]' : 'text-accent-blue'}`}>
                {user.role} Workspace
              </span>
            </div>
            <div className="w-px h-8 bg-white/10 hidden md:block"></div>
            <button 
              onClick={logout}
              className="p-2.5 rounded-xl border border-white/5 bg-white/5 hover:bg-red-400/10 hover:border-red-400/20 hover:text-red-400 transition-all duration-300 text-text-dim group"
            >
              <LogOut size={18} className="group-hover:-translate-x-0.5 transition-transform" />
            </button>
          </div>
        </div>
      </nav>

      {/* Main Content Area */}
      <main className="max-w-7xl mx-auto p-6 pt-10">
        <motion.div
           initial={{ opacity: 0, y: 10 }}
           animate={{ opacity: 1, y: 0 }}
           transition={{ duration: 0.4 }}
        >
          {user.role === 'ADMIN' ? <AdminDashboard /> : <UserDashboard />}
        </motion.div>
      </main>
    </div>
  );
};

export default Home;
