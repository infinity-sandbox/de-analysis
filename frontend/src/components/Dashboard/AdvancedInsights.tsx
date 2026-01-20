import React from 'react';
import { Card, List, Typography, Tag, Alert } from 'antd';
import { BulbOutlined, RiseOutlined, FallOutlined } from '@ant-design/icons';
import { useDashboardContext } from '../../contexts/DashboardContext';

const { Title } = Typography;

const AdvancedInsights: React.FC = () => {
  const { advancedInsights } = useDashboardContext();

  if (!advancedInsights || advancedInsights.length === 0) {
    return (
      <Card>
        <Title level={4}>Advanced Insights</Title>
        <Alert message="No advanced insights available" type="info" showIcon />
      </Card>
    );
  }

  const getTrendIcon = (trend: string) => {
    switch (trend) {
      case 'increasing': return <RiseOutlined style={{ color: '#52c41a' }} />;
      case 'decreasing': return <FallOutlined style={{ color: '#f5222d' }} />;
      default: return <BulbOutlined />;
    }
  };

  const getImpactColor = (impact: string) => {
    switch (impact) {
      case 'high': return 'red';
      case 'medium': return 'orange';
      case 'low': return 'green';
      default: return 'blue';
    }
  };

  return (
    <Card>
      <Title level={4}>Advanced Insights</Title>
      <List
        dataSource={advancedInsights}
        renderItem={(insight, index) => (
          <List.Item key={index}>
            <List.Item.Meta
              avatar={getTrendIcon(insight.trend)}
              title={
                <div>
                  {insight.title}
                  <Tag color={getImpactColor(insight.impact)} style={{ marginLeft: '8px' }}>
                    {insight.impact.toUpperCase()}
                  </Tag>
                </div>
              }
              description={
                <div>
                  <p>{insight.description}</p>
                  <p><strong>Metric:</strong> {insight.metric}</p>
                  <p><strong>Recommendation:</strong> {insight.recommendation}</p>
                </div>
              }
            />
          </List.Item>
        )}
      />
    </Card>
  );
};

export default AdvancedInsights;