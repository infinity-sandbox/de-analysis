import React from 'react';
import { Card, Row, Col, Statistic, Progress } from 'antd';
import { 
  FileTextOutlined, 
  TeamOutlined, 
  EyeOutlined, 
  LikeOutlined, 
  MessageOutlined, 
  ShareAltOutlined,
  StarOutlined 
} from '@ant-design/icons';
import { useDashboardContext } from '../../contexts/DashboardContext';

const SummaryCards: React.FC = () => {
  const { dashboardSummary } = useDashboardContext();

  if (!dashboardSummary) return null;

  return (
    <Row gutter={[16, 16]}>
      <Col xs={24} sm={12} lg={6}>
        <Card>
          <Statistic
            title="Total Posts"
            value={dashboardSummary.total_posts}
            prefix={<FileTextOutlined />}
            valueStyle={{ color: '#1890ff' }}
          />
        </Card>
      </Col>
      
      <Col xs={24} sm={12} lg={6}>
        <Card>
          <Statistic
            title="Total Authors"
            value={dashboardSummary.total_authors}
            prefix={<TeamOutlined />}
            valueStyle={{ color: '#52c41a' }}
          />
        </Card>
      </Col>
      
      <Col xs={24} sm={12} lg={6}>
        <Card>
          <Statistic
            title="Total Engagements"
            value={dashboardSummary.total_engagements}
            prefix={<EyeOutlined />}
            valueStyle={{ color: '#fa8c16' }}
          />
        </Card>
      </Col>
      
      <Col xs={24} sm={12} lg={6}>
        <Card>
          <div style={{ textAlign: 'center' }}>
            <Progress
              type="dashboard"
              percent={Math.min(dashboardSummary.avg_engagement_rate * 10, 100)}
              format={percent => `${dashboardSummary.avg_engagement_rate}%`}
              strokeColor={{
                '0%': '#108ee9',
                '100%': '#87d068',
              }}
            />
            <div style={{ marginTop: '8px', fontWeight: 'bold' }}>Avg Engagement Rate</div>
          </div>
        </Card>
      </Col>

      <Col xs={24} sm={8} lg={4}>
        <Card size="small">
          <Statistic
            title="Views"
            value={dashboardSummary.total_views}
            prefix={<EyeOutlined />}
            valueStyle={{ color: '#1890ff', fontSize: '16px' }}
          />
        </Card>
      </Col>
      
      <Col xs={24} sm={8} lg={4}>
        <Card size="small">
          <Statistic
            title="Likes"
            value={dashboardSummary.total_likes}
            prefix={<LikeOutlined />}
            valueStyle={{ color: '#52c41a', fontSize: '16px' }}
          />
        </Card>
      </Col>
      
      <Col xs={24} sm={8} lg={4}>
        <Card size="small">
          <Statistic
            title="Comments"
            value={dashboardSummary.total_comments}
            prefix={<MessageOutlined />}
            valueStyle={{ color: '#fa8c16', fontSize: '16px' }}
          />
        </Card>
      </Col>
      
      <Col xs={24} sm={8} lg={4}>
        <Card size="small">
          <Statistic
            title="Shares"
            value={dashboardSummary.total_shares}
            prefix={<ShareAltOutlined />}
            valueStyle={{ color: '#eb2f96', fontSize: '16px' }}
          />
        </Card>
      </Col>
      
      <Col xs={24} sm={8} lg={4}>
        <Card size="small">
          <Statistic
            title="Top Author"
            value={dashboardSummary.top_performing_author}
            prefix={<StarOutlined />}
            valueStyle={{ color: '#722ed1', fontSize: '12px' }}
          />
        </Card>
      </Col>
      
      <Col xs={24} sm={8} lg={4}>
        <Card size="small">
          <Statistic
            title="Best Time"
            value={dashboardSummary.best_time_to_post}
            valueStyle={{ color: '#13c2c2', fontSize: '12px' }}
          />
        </Card>
      </Col>
    </Row>
  );
};

export default SummaryCards;