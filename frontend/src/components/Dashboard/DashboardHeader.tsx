import React from 'react';
import { Card, Typography, Button } from 'antd';
import { DashboardOutlined, SyncOutlined } from '@ant-design/icons';
import UserAvatar from '../UserAvatar';
import { useDashboardContext } from '../../contexts/DashboardContext';

const { Title, Text } = Typography;

interface DashboardHeaderProps {
  onRefresh: () => void;
  refreshing: boolean;
}

const DashboardHeader: React.FC<DashboardHeaderProps> = ({ onRefresh, refreshing }) => {
  const { userData, dashboardSummary } = useDashboardContext();

  return (
    <Card className="dashboard-header-card">
      <div className="header-content">
        <div>
          <Title level={2} style={{ margin: 0, color: '#1890ff' }}>
            <DashboardOutlined /> Analytics Dashboard
          </Title>
          <Text type="secondary" style={{ margin: 0 }}>
            Real-time insights into content performance
          </Text>
          {dashboardSummary && (
            <div style={{ marginTop: '8px' }}>
              <Text strong>Top Category: </Text>
              <Text type="secondary">{dashboardSummary.top_category}</Text>
              <Text strong style={{ marginLeft: '16px' }}>Best Time: </Text>
              <Text type="secondary">{dashboardSummary.best_time_to_post}</Text>
            </div>
          )}
        </div>
        
        <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
          <Button 
            icon={<SyncOutlined spin={refreshing} />} 
            onClick={onRefresh}
            loading={refreshing}
          >
            Refresh
          </Button>
          {userData && (
            <UserAvatar email={userData.email} username={userData.username} />
          )}
        </div>
      </div>
    </Card>
  );
};

export default DashboardHeader;