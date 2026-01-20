import React from 'react';
import { Card, Row, Col, Statistic, Progress, Typography, Tag } from 'antd';
import { UserOutlined, RocketOutlined, TagOutlined, StarOutlined } from '@ant-design/icons';
import { useDashboardContext } from '../../contexts/DashboardContext';

const { Title, Text } = Typography;

const AdvancedPatterns: React.FC = () => {
  const { advancedPatterns } = useDashboardContext();

  if (!advancedPatterns) {
    return (
      <Card>
        <Title level={4}>Advanced Patterns</Title>
        <div style={{ height: '200px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <p>No advanced patterns data available</p>
        </div>
      </Card>
    );
  }

  const { user_behavior, content_optimization } = advancedPatterns;

  return (
    <Card>
      <Title level={4}>Advanced Patterns Analysis</Title>
      
      <Row gutter={[16, 16]} style={{ marginBottom: '24px' }}>
        <Col span={24}>
          <Title level={5} style={{ color: '#1890ff', marginBottom: '16px' }}>
            <UserOutlined /> User Behavior Patterns
          </Title>
        </Col>
        
        <Col xs={12} md={8}>
          <Card size="small">
            <Statistic
              title="Avg Diversity Score"
              value={user_behavior.avg_diversity_score}
              precision={2}
              prefix={<StarOutlined />}
              valueStyle={{ color: '#52c41a', fontSize: '18px' }}
            />
            <Progress 
              percent={(user_behavior.avg_diversity_score / 5) * 100} 
              size="small" 
              status="active"
              strokeColor={{
                '0%': '#108ee9',
                '100%': '#87d068',
              }}
            />
          </Card>
        </Col>
        
        <Col xs={12} md={8}>
          <Card size="small">
            <Statistic
              title="High Diversity Users"
              value={user_behavior.high_diversity_users}
              suffix={`/ ${user_behavior.total_analyzed_users}`}
              prefix={<UserOutlined />}
              valueStyle={{ color: '#1890ff', fontSize: '18px' }}
            />
            <div style={{ marginTop: '8px' }}>
              <Text type="secondary">
                {((user_behavior.high_diversity_users / user_behavior.total_analyzed_users) * 100).toFixed(1)}% of users
              </Text>
            </div>
          </Card>
        </Col>
        
        <Col xs={24} md={8}>
          <Card size="small">
            <Statistic
              title="Total Analyzed Users"
              value={user_behavior.total_analyzed_users}
              prefix={<UserOutlined />}
              valueStyle={{ color: '#fa8c16', fontSize: '18px' }}
            />
          </Card>
        </Col>
      </Row>

      <Row gutter={[16, 16]}>
        <Col span={24}>
          <Title level={5} style={{ color: '#1890ff', marginBottom: '16px' }}>
            <RocketOutlined /> Content Optimization
          </Title>
        </Col>
        
        <Col xs={12} md={8}>
          <Card size="small">
            <Statistic
              title="Best Media Type"
              value={content_optimization.best_media_type ? "Video/Image" : "Text"}
              prefix={<TagOutlined />}
              valueStyle={{ color: '#eb2f96', fontSize: '14px' }}
            />
            <div style={{ marginTop: '8px' }}>
              <Tag color={content_optimization.best_media_type ? "green" : "blue"}>
                {content_optimization.best_media_type ? "Visual Content" : "Text Content"}
              </Tag>
            </div>
          </Card>
        </Col>
        
        <Col xs={12} md={8}>
          <Card size="small">
            <Statistic
              title="Promotion Effectiveness"
              value={content_optimization.promotion_effectiveness}
              precision={1}
              prefix={<RocketOutlined />}
              valueStyle={{ color: '#722ed1', fontSize: '18px' }}
            />
            <Progress 
              percent={Math.min(content_optimization.promotion_effectiveness * 25, 100)} 
              size="small" 
              status="active"
            />
          </Card>
        </Col>
        
        <Col xs={24} md={8}>
          <Card size="small">
            <Statistic
              title="Optimal Tag Count"
              value={content_optimization.optimal_tag_count}
              prefix={<TagOutlined />}
              valueStyle={{ color: '#13c2c2', fontSize: '18px' }}
            />
            <div style={{ marginTop: '8px' }}>
              <Text type="secondary">Tags per post for max engagement</Text>
            </div>
          </Card>
        </Col>
      </Row>

      <div style={{ marginTop: '16px', padding: '12px', background: '#f6ffed', borderRadius: '4px' }}>
        <Text type="secondary">
          <strong>Insight:</strong> {
            content_optimization.best_media_type 
              ? "Visual content performs better. Consider adding images/videos to increase engagement."
              : "Text content shows strong performance. Focus on quality writing and storytelling."
          }
        </Text>
      </div>
    </Card>
  );
};

export default AdvancedPatterns;