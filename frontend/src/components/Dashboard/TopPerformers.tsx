import React, { useState, useEffect } from 'react';
import { Card, Table, Typography, Tag, Progress, Select, InputNumber, Spin } from 'antd';
import { CrownOutlined, StarOutlined } from '@ant-design/icons';
import { getTopEngagements, EngagementSummary } from '../../services/api';

const { Option } = Select;
const { Title } = Typography;

const TopPerformers: React.FC = () => {
  const [data, setData] = useState<EngagementSummary[]>([]);
  const [loading, setLoading] = useState(false);
  const [filters, setFilters] = useState({
    period: 'last_year',
    limit: 10
  });

  useEffect(() => {
    fetchData();
  }, [filters]);

  const fetchData = async () => {
    setLoading(true);
    try {
      const engagementsData = await getTopEngagements(filters.period, filters.limit);
      setData(engagementsData);
    } catch (error) {
      console.error('Error fetching top engagements:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleFilterChange = (key: string, value: any) => {
    setFilters(prev => ({ ...prev, [key]: value }));
  };

  const columns = [
    {
      title: 'Rank',
      dataIndex: 'rank',
      key: 'rank',
      render: (text: string, record: any, index: number) => (
        <div style={{ textAlign: 'center' }}>
          {index === 0 ? <CrownOutlined style={{ color: '#ffd666', fontSize: '16px' }} /> : 
           index === 1 ? <StarOutlined style={{ color: '#d9d9d9', fontSize: '16px' }} /> :
           index + 1}
        </div>
      ),
      width: 60,
    },
    {
      title: 'Author',
      dataIndex: 'author_name',
      key: 'author_name',
      render: (text: string, record: any) => (
        <div>
          <div style={{ fontWeight: 'bold' }}>{text}</div>
          <div style={{ fontSize: '12px', color: '#666' }}>{record.author_category}</div>
        </div>
      ),
    },
    {
      title: 'Engagement Score',
      dataIndex: 'engagement_score',
      key: 'engagement_score',
      render: (score: number) => (
        <Progress 
          percent={Math.min(score, 100)} 
          size="small" 
          format={percent => `${score}`}
        />
      ),
    },
    {
      title: 'Engagement Rate',
      dataIndex: 'engagement_rate',
      key: 'engagement_rate',
      render: (rate: number) => `${rate.toFixed(1)}%`,
    },
    {
      title: 'Metrics',
      key: 'metrics',
      render: (record: any) => (
        <div style={{ fontSize: '12px' }}>
          <div>👁️ {record.total_views}</div>
          <div>👍 {record.total_likes}</div>
          <div>💬 {record.total_comments}</div>
          <div>🔄 {record.total_shares}</div>
        </div>
      ),
    },
    {
      title: 'Category',
      dataIndex: 'post_category',
      key: 'post_category',
      render: (category: string) => <Tag color="blue">{category}</Tag>,
    },
  ];

  return (
    <Card>
      <Title level={4}>Top Performing Authors</Title>
      
      {/* Filters */}
      <div style={{ marginBottom: '16px' }}>
        <span>Period: </span>
        <Select
          value={filters.period}
          onChange={(value) => handleFilterChange('period', value)}
          style={{ width: '150px', marginLeft: '8px', marginRight: '16px' }}
          size="small"
        >
          <Option value="last_7_days">Last 7 Days</Option>
          <Option value="last_30_days">Last 30 Days</Option>
          <Option value="last_3_months">Last 3 Months</Option>
          <Option value="last_year">Last Year</Option>
        </Select>
        
        <span>Limit: </span>
        <InputNumber
          value={filters.limit}
          onChange={(value) => handleFilterChange('limit', value || 10)}
          min={5}
          max={50}
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
          dataSource={data.map((item, index) => ({ ...item, key: item.author_id, rank: index + 1 }))}
          columns={columns}
          pagination={false}
          size="small"
          rowKey="author_id"
        />
      ) : (
        <div style={{ height: '200px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <p>No top performers data available</p>
        </div>
      )}
    </Card>
  );
};

export default TopPerformers;