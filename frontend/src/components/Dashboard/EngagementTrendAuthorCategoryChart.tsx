import React, { useState, useEffect } from 'react';
import { Card, InputNumber, Typography, Spin, Select } from 'antd';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts';
import { getEngagementTrendAuthorCategory } from '../../services/api';
import { EngagementTrendAuthorCategory } from '../../types/types';

const { Option } = Select;
const { Title } = Typography;

const EngagementTrendAuthorCategoryChart: React.FC = () => {
  const [data, setData] = useState<EngagementTrendAuthorCategory[]>([]);
  const [loading, setLoading] = useState(false);
  const [days, setDays] = useState(365);
  const [selectedAuthor, setSelectedAuthor] = useState<string>('all');

  useEffect(() => {
    fetchData();
  }, [days]);

  const fetchData = async () => {
    setLoading(true);
    try {
      const trendData = await getEngagementTrendAuthorCategory(days);
      setData(trendData);
    } catch (error) {
      console.error('Error fetching engagement trend author category:', error);
    } finally {
      setLoading(false);
    }
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
  };

  // Get unique authors from data
//   const authors = [...new Set(data.map(item => item.author_name))];
  const authors = Array.from(new Set(data.map(item => item.author_name)));
  
  // Filter data by selected author
  const filteredData = selectedAuthor === 'all' 
    ? data 
    : data.filter(item => item.author_name === selectedAuthor);

  // Group by date and author/category for chart
  const chartData = filteredData.reduce((acc: any[], item) => {
    const date = formatDate(item.engagement_date);
    const key = `${date}-${item.author_name}-${item.category}`;
    
    acc.push({
      date,
      author: item.author_name,
      category: item.category,
      views: item.views,
      likes: item.likes,
      comments: item.comments,
      shares: item.shares,
      total: item.total_engagements,
      key
    });
    
    return acc;
  }, []);

  return (
    <Card>
      <Title level={4}>Engagement Trend by Author</Title>
      
      {/* Filters */}
      <div style={{ marginBottom: '16px' }}>
        <span>Days: </span>
        <InputNumber
          value={days}
          onChange={(value) => setDays(value || 365)}
          min={7}
          max={365}
          size="small"
          style={{ width: '80px', marginLeft: '8px', marginRight: '16px' }}
        />
        
        <span>Author: </span>
        <Select
          value={selectedAuthor}
          onChange={setSelectedAuthor}
          style={{ width: '150px', marginLeft: '8px' }}
          size="small"
        >
          <Option value="all">All Authors</Option>
          {authors.map(author => (
            <Option key={author} value={author}>{author}</Option>
          ))}
        </Select>
      </div>

      {/* Chart */}
      {loading ? (
        <div style={{ height: '300px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <Spin />
        </div>
      ) : (
        <ResponsiveContainer width="100%" height={300}>
          <LineChart data={chartData}>
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis dataKey="date" />
            <YAxis />
            <Tooltip />
            <Legend />
            <Line type="monotone" dataKey="views" stroke="#1890ff" name="Views" />
            <Line type="monotone" dataKey="likes" stroke="#52c41a" name="Likes" />
            <Line type="monotone" dataKey="comments" stroke="#fa8c16" name="Comments" />
            <Line type="monotone" dataKey="shares" stroke="#eb2f96" name="Shares" />
          </LineChart>
        </ResponsiveContainer>
      )}
    </Card>
  );
};

export default EngagementTrendAuthorCategoryChart;