import React from 'react';
import { Button, Card, Typography, Row, Col, Statistic } from 'antd';
import { 
  DashboardOutlined, 
  LineChartOutlined, 
  TeamOutlined, 
  RocketOutlined,
  EyeOutlined,
  LikeOutlined,
  MessageOutlined,
  ShareAltOutlined
} from '@ant-design/icons';
import { useDashboardContext } from '../../contexts/DashboardContext';

const { Title, Paragraph } = Typography;

const WelcomePage: React.FC = () => {
  const { userData, dashboardSummary, loading } = useDashboardContext();

  return (
    <div className="welcome-container">
      <Card bordered={false} className="welcome-card">
        <div style={{ textAlign: 'center', marginBottom: '40px' }}>
          <Title level={1} style={{ color: '#1890ff', marginBottom: '16px' }}>
            Jumper Media Analytics
          </Title>
          <Title level={3} type="secondary" style={{ marginTop: '0' }}>
            Gain Powerful Insights into Your Content Performance
          </Title>
        </div>
        
        {!loading && dashboardSummary && (
          <Row gutter={[24, 24]} style={{ marginBottom: '40px' }}>
            <Col xs={12} sm={6}>
              <Statistic 
                title="Total Posts" 
                value={dashboardSummary.total_posts} 
                prefix={<DashboardOutlined />}
              />
            </Col>
            <Col xs={12} sm={6}>
              <Statistic 
                title="Total Authors" 
                value={dashboardSummary.total_authors} 
                prefix={<TeamOutlined />}
              />
            </Col>
            <Col xs={12} sm={6}>
              <Statistic 
                title="Total Views" 
                value={dashboardSummary.total_views} 
                prefix={<EyeOutlined />}
              />
            </Col>
            <Col xs={12} sm={6}>
              <Statistic 
                title="Engagement Rate" 
                value={dashboardSummary.avg_engagement_rate} 
                suffix="%" 
                prefix={<LineChartOutlined />}
              />
            </Col>
          </Row>
        )}

        <div style={{ margin: '40px 0' }}>
          <Row gutter={[24, 24]}>
            <Col xs={24} md={12} lg={8}>
              <div className="feature-card">
                <div className="feature-icon" style={{ backgroundColor: '#e6f7ff' }}>
                  <LineChartOutlined style={{ fontSize: '32px', color: '#1890ff' }} />
                </div>
                <h3>Advanced Analytics</h3>
                <p>Deep dive into engagement metrics, trends, and performance indicators</p>
              </div>
            </Col>
            <Col xs={24} md={12} lg={8}>
              <div className="feature-card">
                <div className="feature-icon" style={{ backgroundColor: '#f6ffed' }}>
                  <TeamOutlined style={{ fontSize: '32px', color: '#52c41a' }} />
                </div>
                <h3>Author Performance</h3>
                <p>Track and compare author performance across different categories</p>
              </div>
            </Col>
            <Col xs={24} md={12} lg={8}>
              <div className="feature-card">
                <div className="feature-icon" style={{ backgroundColor: '#fff2e8' }}>
                  <RocketOutlined style={{ fontSize: '32px', color: '#fa8c16' }} />
                </div>
                <h3>Content Optimization</h3>
                <p>Identify best-performing content types and optimization opportunities</p>
              </div>
            </Col>
            <Col xs={24} md={12} lg={8}>
              <div className="feature-card">
                <div className="feature-icon" style={{ backgroundColor: '#f9f0ff' }}>
                  <EyeOutlined style={{ fontSize: '32px', color: '#722ed1' }} />
                </div>
                <h3>Engagement Insights</h3>
                <p>Understand when and how your audience engages with content</p>
              </div>
            </Col>
            <Col xs={24} md={12} lg={8}>
              <div className="feature-card">
                <div className="feature-icon" style={{ backgroundColor: '#fff0f6' }}>
                  <LikeOutlined style={{ fontSize: '32px', color: '#eb2f96' }} />
                </div>
                <h3>Trend Analysis</h3>
                <p>Spot trends and patterns in audience behavior over time</p>
              </div>
            </Col>
            <Col xs={24} md={12} lg={8}>
              <div className="feature-card">
                <div className="feature-icon" style={{ backgroundColor: '#fcffe6' }}>
                  <ShareAltOutlined style={{ fontSize: '32px', color: '#a0d911' }} />
                </div>
                <h3>Opportunity Discovery</h3>
                <p>Find hidden opportunities for growth and engagement</p>
              </div>
            </Col>
          </Row>
        </div>
        
        <div style={{ marginTop: '45px', textAlign: 'center' }}>
          <Paragraph style={{ fontSize: '16px', marginBottom: '50px' }}>
            Welcome to Jumper Media's comprehensive analytics platform. 
            Get actionable insights to optimize your content strategy, 
            maximize engagement, and drive growth through data-driven decisions.
          </Paragraph>
        </div>
        
        <div style={{ textAlign: 'center' }}>
          <Button 
            type="primary" 
            size="large" 
            href="/dashboard"
            style={{ 
              padding: '0 40px', 
              height: '50px', 
              fontSize: '18px',
              fontWeight: 'bold'
            }}
          >
            Explore Dashboard
          </Button>
        </div>
      </Card>
    </div>
  );
};

export default WelcomePage;