import React, { useState, useEffect } from 'react';
import { Card, Select, Typography, Spin } from 'antd';
import { ScatterChart, Scatter, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Cell } from 'recharts';
import { getScatterPerformance } from '../../services/api';
import { ScatterPoint } from '../../types/types';

const { Option } = Select;
const { Title, Text } = Typography;

const ScatterPerformanceChart: React.FC = () => {
  const [data, setData] = useState<ScatterPoint[]>([]);
  const [loading, setLoading] = useState(false);
  const [filters, setFilters] = useState({
    period: 'last_year',
    entity_type: 'author'
  });

  useEffect(() => {
    fetchData();
  }, [filters]);

  const fetchData = async () => {
    setLoading(true);
    try {
      const scatterData = await getScatterPerformance(filters.period, filters.entity_type);
      setData(scatterData);
    } catch (error) {
      console.error('Error fetching scatter performance:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleFilterChange = (key: string, value: string) => {
    setFilters(prev => ({ ...prev, [key]: value }));
  };

  const COLORS = ['#0088FE', '#00C49F', '#FFBB28', '#FF8042', '#8884D8', '#82ca9d'];

  return (
    <Card>
      <Title level={4}>Performance Scatter Plot</Title>
      
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
        
        <span>Group By: </span>
        <Select
          value={filters.entity_type}
          onChange={(value) => handleFilterChange('entity_type', value)}
          style={{ width: '120px', marginLeft: '8px' }}
          size="small"
        >
          <Option value="author">Author</Option>
          <Option value="category">Category</Option>
        </Select>
      </div>

      {/* Chart */}
      {loading ? (
        <div style={{ height: '300px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <Spin />
        </div>
      ) : (
        <ResponsiveContainer width="100%" height={300}>
          <ScatterChart
            margin={{ top: 20, right: 20, bottom: 20, left: 20 }}
          >
            <CartesianGrid />
            <XAxis 
              type="number" 
              dataKey="post_count" 
              name="Post Count"
              label={{ value: 'Post Count', position: 'insideBottom', offset: -5 }}
            />
            <YAxis 
              type="number" 
              dataKey="engagements_per_post" 
              name="Engagements per Post"
              label={{ value: 'Engagements/Post', angle: -90, position: 'insideLeft' }}
            />
            <Tooltip 
              cursor={{ strokeDasharray: '3 3' }} 
              formatter={(value, name) => [value, name === 'Post Count' ? 'Posts' : 'Engagements/Post']}
              labelFormatter={(label) => `Entity: ${label}`}
            />
            <Scatter name="Performance" data={data} fill="#8884d8">
              {data.map((entry, index) => (
                <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
              ))}
            </Scatter>
          </ScatterChart>
        </ResponsiveContainer>
      )}
      
      <div style={{ marginTop: '16px', textAlign: 'center' }}>
        <Text type="secondary">
          Each point represents {filters.entity_type} performance. 
          Higher engagements per post with more posts indicates strong performance.
        </Text>
      </div>
    </Card>
  );
};

export default ScatterPerformanceChart;