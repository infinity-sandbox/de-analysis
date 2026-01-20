import React, { useState, useEffect } from 'react';
import { Routes, Route, BrowserRouter } from 'react-router-dom';
import Login from './components/Login';
import ForgotPassword from './components/forgetLink/forgetLinkPage';
import PasswordResetPage from './components/forgetLink/emailRedirectedPage';
import SuccessRegistrationPage from './components/statusPages/successRegistrationPage';
import PrivateRoute from './components/PrivateRoute';
import Register from './components/RegisterForm';
import Dashboard from './components/Dashboard';
import { DashboardProvider } from './contexts/DashboardContext';
import { getUserData } from './services/api';
import './App.css';
import './styles/simulator.css';
import './styles/responsive.css';
import './styles/dashboard.css';
import WelcomePage from './components/Dashboard/WelcomePage';

function App() {
  const [userEmail, setUserEmail] = useState('');

  useEffect(() => {
    const fetchUserData = async () => {
      try {
        const userData = await getUserData();
        setUserEmail(userData.email);
      } catch (error) {
        console.error('Error fetching user data:', error);
      }
    };
    
    fetchUserData();
  }, []);

  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<Login />} />
        <Route path="/login" element={<Login />} />
        <Route path='/forgot/password' element={<ForgotPassword />} />
        <Route path='/reset/password' element={<PasswordResetPage />} />
        <Route path='/success/registration' element={<SuccessRegistrationPage />} />
        <Route path='/register' element={<Register />} />
        <Route path="/dashboard" element={
          <PrivateRoute>
            <DashboardProvider>
              <Dashboard />
            </DashboardProvider>
          </PrivateRoute>
        } />
        <Route path="/welcome" element={
          <PrivateRoute>
            <DashboardProvider>
              <WelcomePage />
            </DashboardProvider>
          </PrivateRoute>
        } />
      </Routes>
    </BrowserRouter>
  );
}

export default App;