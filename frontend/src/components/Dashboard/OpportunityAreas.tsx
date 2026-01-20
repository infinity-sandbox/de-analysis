import React, { useState, useEffect } from 'react';
import { Card, Table, Typography, Progress, Tag, InputNumber, Spin } from 'antd';
import { RocketOutlined, UserOutlined, TagOutlined } from '@ant-design/icons';
import { getOpportunityAreas, OpportunityArea as OpportunityAreaType } from '../../services/api';

const { Title } = Typography;

const OpportunityAreas: React.FC = () => {
  const [data, setData] = useState<OpportunityAreaType[]>([]);
  const [loading, setLoading] = useState(false);
  const [minPosts, setMinPosts] = useState(2);

  useEffect(() => {
    fetchData();
  }, [minPosts]);

  const fetchData = async () => {
    setLoading(true);
    try {
      const opportunitiesData = await getOpportunityAreas(minPosts);
      setData(opportunitiesData);
    } catch (error) {
      console.error('Error fetching opportunity areas:', error);
    } finally {
      setLoading(false);
    }
  };

  const columns = [
    {
      title: 'Entity',
      dataIndex: 'entity_name',
      key: 'entity_name',
      render: (text: string, record: any) => (
        <div>
          {record.analysis_type === 'author' ? <UserOutlined /> : <TagOutlined />}
          <span style={{ marginLeft: '8px', fontWeight: 'bold' }}>{text}</span>
          <div style={{ fontSize: '12px', color: '#666' }}>{record.category}</div>
          <div style={{ fontSize: '12px', color: '#999' }}>
            Type: {record.analysis_type}
          </div>
        </div>
      ),
    },
    {
      title: 'Posts',
      dataIndex: 'post_count',
      key: 'post_count',
      render: (count: number) => <Tag color="blue">{count}</Tag>,
      width: 80,
    },
    {
      title: 'Engagement/Post',
      dataIndex: 'engagement_per_post',
      key: 'engagement_per_post',
      render: (engagement: number) => engagement.toFixed(1),
      width: 120,
    },
    {
      title: 'Total Engagements',
      dataIndex: 'total_engagements',
      key: 'total_engagements',
      render: (total: number) => total.toLocaleString(),
      width: 120,
    },
    {
      title: 'Opportunity Score',
      dataIndex: 'opportunity_score',
      key: 'opportunity_score',
      render: (score: number) => (
        <Progress 
          percent={Math.min(score * 20, 100)} 
          size="small" 
          status="active"
          format={percent => score.toFixed(1)}
        />
      ),
    },
  ];

  return (
    <Card>
      <Title level={4}>
        <RocketOutlined /> Opportunity Areas
      </Title>
      
      {/* Filter */}
      <div style={{ marginBottom: '16px' }}>
        <span>Minimum Posts: </span>
        <InputNumber
          value={minPosts}
          onChange={(value) => setMinPosts(value || 2)}
          min={1}
          max={20}
          style={{ width: '80px', marginLeft: '8px' }}
          size="small"
        />
      </div>

      {loading ? (
        <div style={{ height: '300px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <Spin />
        </div>
      ) : data.length > 0 ? (
        <Table
          dataSource={data}
          columns={columns}
          pagination={false}
          size="small"
          rowKey={(record) => `${record.analysis_type}-${record.entity_id || record.entity_name}`}
          scroll={{ x: 800 }}
        />
      ) : (
        <div style={{ height: '200px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <p>No opportunity areas data available</p>
        </div>
      )}
      
      <div style={{ marginTop: '16px', fontSize: '12px', color: '#666' }}>
        Showing entities with at least {minPosts} posts. Higher opportunity scores indicate better potential for growth.
      </div>
    </Card>
  );
};

export default OpportunityAreas;