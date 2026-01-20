import React from 'react';
import { useDashboardContext } from '../../contexts/DashboardContext';
import WelcomePage from './WelcomePage';
import DashboardPage from './DashboardPage';

const Dashboard: React.FC = () => {
  const { userData } = useDashboardContext();

  // Show welcome page if no specific dashboard route, or implement routing
  // For now, we'll show dashboard directly. You can implement routing as needed.
  
  return <DashboardPage />;
};

export default Dashboard;