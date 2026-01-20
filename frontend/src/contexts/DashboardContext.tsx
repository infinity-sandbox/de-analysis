import React, { createContext, useState, useContext, ReactNode, useEffect } from 'react';
import { 
  DashboardContextType, 
  UserData, 
  DashboardSummary, 
  AdvancedInsight, 
  AdvancedPatterns 
} from '../types/types';
import { 
  getUserData, 
  getDashboardSummary, 
  getAdvancedInsights, 
  getAdvancedPatterns 
} from '../services/api';

const DashboardContext = createContext<DashboardContextType | undefined>(undefined);

export const DashboardProvider: React.FC<{children: ReactNode}> = ({ children }) => {
  const [userData, setUserData] = useState<UserData | null>(null);
  const [dashboardSummary, setDashboardSummary] = useState<DashboardSummary | null>(null);
  const [advancedInsights, setAdvancedInsights] = useState<AdvancedInsight[]>([]);
  const [advancedPatterns, setAdvancedPatterns] = useState<AdvancedPatterns | null>(null);
  const [loading, setLoading] = useState(true);

  const fetchDashboardData = async () => {
    setLoading(true);
    try {
      const [user, summary, insights, patterns] = await Promise.all([
        getUserData(),
        getDashboardSummary(),
        getAdvancedInsights(),
        getAdvancedPatterns()
      ]);

      setUserData(user);
      setDashboardSummary(summary);
      setAdvancedInsights(insights);
      setAdvancedPatterns(patterns);
    } catch (error) {
      console.error('Error fetching dashboard data:', error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchDashboardData();
  }, []);

  return (
    <DashboardContext.Provider value={{
      userData,
      dashboardSummary,
      advancedInsights,
      advancedPatterns,
      loading,
      fetchDashboardData,
    }}>
      {children}
    </DashboardContext.Provider>
  );
};

export const useDashboardContext = () => {
  const context = useContext(DashboardContext);
  if (!context) throw new Error('useDashboardContext must be used within DashboardProvider');
  return context;
};