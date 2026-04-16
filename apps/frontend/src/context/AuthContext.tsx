import React, { createContext, useContext, useState, useEffect } from 'react';
import api from '../lib/api';

interface AuthContextType {
  user: any;
  setUser: (user: any) => void;
  login: (email: string, code: string) => Promise<void>;
  logout: () => void;
  isLoading: boolean;
}

const AuthContext = createContext<AuthContextType | null>(null);

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<any>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const checkUser = async () => {
      const token = localStorage.getItem('token');
      if (token) {
        try {
          const res = await api.get('/users/me');
          setUser(res.data);
        } catch (e) {
          localStorage.removeItem('token');
        }
      }
      setIsLoading(false);
    };
    checkUser();
  }, []);

  const login = async (email: string, code: string) => {
    const res = await api.post('/auth/verify-otp', { email, code });
    localStorage.setItem('token', res.data.access_token);
    setUser(res.data.user);
  };

  const logout = () => {
    localStorage.removeItem('token');
    setUser(null);
    window.location.href = '/login';
  };

  return (
    <AuthContext.Provider value={{ user, setUser, login, logout, isLoading }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) throw new Error('useAuth must be used within AuthProvider');
  return context;
};
