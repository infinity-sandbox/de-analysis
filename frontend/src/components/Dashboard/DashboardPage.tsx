import React, { useState } from 'react';
import { Row, Col, Spin, Alert } from 'antd';
import { useDashboardContext } from '../../contexts/DashboardContext';
import DashboardHeader from './DashboardHeader';
import SummaryCards from './SummaryCards';
import EngagementChart from './EngagementChart';
import EngagementTrendAuthorCategoryChart from './EngagementTrendAuthorCategoryChart';
import ScatterPerformanceChart from './ScatterPerformanceChart';
import HeatmapVisualization from './HeatmapVisualization';
import TopPerformers from './TopPerformers';
import ContentPerformance from './ContentPerformance';
import AdvancedInsights from './AdvancedInsights';
import AdvancedPatterns from './AdvancedPatterns';
import OpportunityAreas from './OpportunityAreas';
import DownloadButtons from './DownloadButtons';

const DashboardPage: React.FC = () => {
  const { loading, fetchDashboardData, dashboardSummary } = useDashboardContext();
  const [refreshing, setRefreshing] = useState(false);

  const handleRefresh = async () => {
    setRefreshing(true);
    await fetchDashboardData();
    setRefreshing(false);
  };

  if (loading) {
    return (
      <div style={{ textAlign: 'center', padding: '100px' }}>
        <Spin size="large" />
        <div style={{ marginTop: '16px' }}>
          <p>Loading dashboard data...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="dashboard-container" style={{ padding: '24px', background: '#f9f9f9ff', minHeight: '100vh' }}>
      <DashboardHeader onRefresh={handleRefresh} refreshing={refreshing} />
      
      {!dashboardSummary ? (
        <Alert
          message="Data Unavailable"
          description="Unable to load dashboard data. Please check your connection and try again."
          type="warning"
          showIcon
          style={{ marginBottom: '24px' }}
        />
      ) : (
        <>
          {/* Summary Cards - No filters */}
          <SummaryCards />
          
          {/* Engagement Trends Section */}
          <Row gutter={[24, 24]} style={{ marginTop: '24px' }}>
            <Col xs={24} lg={12}>
              <EngagementChart />
            </Col>
            <Col xs={24} lg={12}>
              <EngagementTrendAuthorCategoryChart />
            </Col>
          </Row>

          {/* Scatter Plot and Heatmap */}
          <Row gutter={[24, 24]} style={{ marginTop: '24px' }}>
            <Col xs={24} lg={12}>
              <ScatterPerformanceChart />
            </Col>
            <Col xs={24} lg={12}>
              <HeatmapVisualization />
            </Col>
          </Row>

          {/* Content Performance and Top Performers */}
          <Row gutter={[24, 24]} style={{ marginTop: '24px' }}>
            <Col xs={24} lg={12}>
              <ContentPerformance />
            </Col>
            <Col xs={24} lg={12}>
              <TopPerformers />
            </Col>
          </Row>

          {/* Advanced Patterns and Insights - No filters */}
          <Row gutter={[24, 24]} style={{ marginTop: '24px' }}>
            <Col xs={24} lg={12}>
              <AdvancedPatterns />
            </Col>
            <Col xs={24} lg={12}>
              <AdvancedInsights />
            </Col>
          </Row>

          {/* Opportunity Areas */}
          <Row gutter={[24, 24]} style={{ marginTop: '24px' }}>
            <Col xs={24}>
              <OpportunityAreas />
            </Col>
          </Row>
          {/* Download Buttons at the bottom */}
          <DownloadButtons />
        </>
      )}
    </div>
  );
};

export default DashboardPage;