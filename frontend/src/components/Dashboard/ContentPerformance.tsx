import React, { useState, useEffect } from 'react';
import { Card, Table, Typography, Tag, Progress, InputNumber, Spin } from 'antd';
import { EyeOutlined, LikeOutlined, MessageOutlined, ShareAltOutlined } from '@ant-design/icons';
import { getContentPerformance, ContentPerformance as ContentPerformanceType } from '../../services/api';

const { Title } = Typography;

const ContentPerformance: React.FC = () => {
  const [data, setData] = useState<ContentPerformanceType[]>([]);
  const [loading, setLoading] = useState(false);
  const [minContentLength, setMinContentLength] = useState(500);

  useEffect(() => {
    fetchData();
  }, [minContentLength]);

  const fetchData = async () => {
    setLoading(true);
    try {
      const contentData = await getContentPerformance(minContentLength);
      setData(contentData);
    } catch (error) {
      console.error('Error fetching content performance:', error);
    } finally {
      setLoading(false);
    }
  };

  const columns = [
    {
      title: 'Title',
      dataIndex: 'title',
      key: 'title',
      width: 200,
      render: (text: string, record: any) => (
        <div>
          <div style={{ fontWeight: 'bold' }}>{text.length > 50 ? text.substring(0, 50) + '...' : text}</div>
          <div style={{ fontSize: '12px', color: '#666' }}>
            {record.has_media && <Tag color="green">Media</Tag>}
            {record.is_promoted && <Tag color="orange">Promoted</Tag>}
            <Tag>{record.category}</Tag>
          </div>
          <div style={{ fontSize: '12px', color: '#999' }}>
            Length: {record.content_length} chars
          </div>
        </div>
      ),
    },
    {
      title: 'Engagement',
      dataIndex: 'total_engagements',
      key: 'total_engagements',
      render: (total: number, record: any) => (
        <div>
          <div><EyeOutlined /> {record.views}</div>
          <div><LikeOutlined /> {record.likes}</div>
          <div><MessageOutlined /> {record.comments}</div>
          <div><ShareAltOutlined /> {record.shares}</div>
        </div>
      ),
    },
    {
      title: 'Rate',
      dataIndex: 'engagement_rate',
      key: 'engagement_rate',
      render: (rate: number) => (
        <Progress 
          percent={Math.min(rate, 100)} 
          size="small" 
          format={percent => `${rate.toFixed(1)}%`}
        />
      ),
    },
    {
      title: 'Quality',
      dataIndex: 'content_quality',
      key: 'content_quality',
      render: (quality: string) => (
        <Tag color={quality === 'high_quality' ? 'green' : quality === 'medium_quality' ? 'orange' : 'red'}>
          {quality.replace('_', ' ').toUpperCase()}
        </Tag>
      ),
    },
    {
      title: 'Quality Ratio',
      dataIndex: 'quality_ratio',
      key: 'quality_ratio',
      render: (ratio: number) => (
        <Tag color={ratio > 1 ? 'green' : ratio === 1 ? 'orange' : 'red'}>
          {ratio.toFixed(1)}
        </Tag>
      ),
    },
  ];

  return (
    <Card>
      <Title level={4}>Content Performance</Title>
      
      {/* Filter */}
      <div style={{ marginBottom: '16px' }}>
        <span>Minimum Content Length: </span>
        <InputNumber
          value={minContentLength}
          onChange={(value) => setMinContentLength(value || 500)}
          min={100}
          max={5000}
          step={100}
          style={{ width: '120px', marginLeft: '8px' }}
          size="small"
        />
      </div>

      {loading ? (
        <div style={{ height: '300px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <Spin />
        </div>
      ) : data.length > 0 ? (
        <Table
          dataSource={data.slice(0, 10)}
          columns={columns}
          pagination={false}
          size="small"
          rowKey="post_id"
          scroll={{ x: 800 }}
        />
      ) : (
        <div style={{ height: '200px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <p>No content performance data available</p>
        </div>
      )}
      
      <div style={{ marginTop: '16px', fontSize: '12px', color: '#666' }}>
        Showing {data.length} posts with minimum {minContentLength} characters
      </div>
    </Card>
  );
};

export default ContentPerformance;