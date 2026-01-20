import React, { useState, useEffect } from 'react';
import { Card, Row, Col, Select, InputNumber, Typography, Spin } from 'antd';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts';
import { getEngagementTrend, getAuthors, getPosts, getCategories } from '../../services/api';
import { Author, Post } from '../../types/types';

const { Option } = Select;
const { Title } = Typography;

const EngagementTrendChart: React.FC = () => {
  const [data, setData] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);
  const [authors, setAuthors] = useState<Author[]>([]);
  const [posts, setPosts] = useState<Post[]>([]);
  const [categories, setCategories] = useState<string[]>([]);

  // Filters
  const [filters, setFilters] = useState({
    days: 365,
    entityType: 'author',
    authorName: '',
    postTitle: '',
    categoryName: ''
  });

  useEffect(() => {
    fetchDropdownData();
  }, [filters.entityType]);

  useEffect(() => {
    fetchData();
  }, [filters]);

  const fetchDropdownData = async () => {
    try {
      if (filters.entityType === 'author') {
        const authorsData = await getAuthors();
        setAuthors(authorsData);
        if (authorsData.length > 0) {
          setFilters(prev => ({ ...prev, authorName: authorsData[0].name }));
        }
      } else if (filters.entityType === 'post') {
        const postsData = await getPosts();
        setPosts(postsData);
        if (postsData.length > 0) {
          setFilters(prev => ({ ...prev, postTitle: postsData[0].title }));
        }
      } else if (filters.entityType === 'category') {
        const categoriesData = await getCategories();
        setCategories(categoriesData);
        if (categoriesData.length > 0) {
          setFilters(prev => ({ ...prev, categoryName: categoriesData[0] }));
        }
      }
    } catch (error) {
      console.error('Error fetching dropdown data:', error);
    }
  };

  const fetchData = async () => {
    setLoading(true);
    try {
      const trendData = await getEngagementTrend(
        filters.entityType,
        filters.entityType === 'author' ? filters.authorName : undefined,
        filters.entityType === 'post' ? filters.postTitle : undefined,
        filters.entityType === 'category' ? filters.categoryName : undefined,
        filters.days
      );
      setData(trendData);
    } catch (error) {
      console.error('Error fetching engagement trend:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleFilterChange = (key: string, value: any) => {
    setFilters(prev => ({ ...prev, [key]: value }));
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
  };

  const chartData = data.map(point => ({
    date: formatDate(point.engagement_date),
    views: point.views,
    likes: point.likes,
    comments: point.comments,
    shares: point.shares,
    total: point.total_engagements
  }));

  return (
    <Card>
      <Title level={4}>Engagement Trend</Title>
      
      {/* Filters */}
      <Row gutter={[16, 16]} style={{ marginBottom: '16px' }}>
        <Col>
          <span>Days: </span>
          <InputNumber
            value={filters.days}
            onChange={(value) => handleFilterChange('days', value || 365)}
            min={7}
            max={365}
            size="small"
            style={{ width: '80px', marginLeft: '8px' }}
          />
        </Col>
        
        <Col>
          <span>Entity Type: </span>
          <Select
            value={filters.entityType}
            onChange={(value) => handleFilterChange('entityType', value)}
            style={{ width: '120px', marginLeft: '8px' }}
            size="small"
          >
            <Option value="author">Author</Option>
            <Option value="post">Post</Option>
            <Option value="category">Category</Option>
          </Select>
        </Col>

        {filters.entityType === 'author' && (
          <Col>
            <span>Author: </span>
            <Select
              value={filters.authorName}
              onChange={(value) => handleFilterChange('authorName', value)}
              style={{ width: '200px', marginLeft: '8px' }}
              size="small"
              loading={authors.length === 0}
            >
              {authors.map(author => (
                <Option key={author.author_id} value={author.name}>
                  {author.name}
                </Option>
              ))}
            </Select>
          </Col>
        )}

        {filters.entityType === 'post' && (
          <Col>
            <span>Post: </span>
            <Select
              value={filters.postTitle}
              onChange={(value) => handleFilterChange('postTitle', value)}
              style={{ width: '300px', marginLeft: '8px' }}
              size="small"
              loading={posts.length === 0}
            >
              {posts.map(post => (
                <Option key={post.post_id} value={post.title}>
                  {post.title}
                </Option>
              ))}
            </Select>
          </Col>
        )}

        {filters.entityType === 'category' && (
          <Col>
            <span>Category: </span>
            <Select
              value={filters.categoryName}
              onChange={(value) => handleFilterChange('categoryName', value)}
              style={{ width: '150px', marginLeft: '8px' }}
              size="small"
              loading={categories.length === 0}
            >
              {categories.map(category => (
                <Option key={category} value={category}>
                  {category}
                </Option>
              ))}
            </Select>
          </Col>
        )}
      </Row>

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
            <Line type="monotone" dataKey="total" stroke="#1890ff" name="Total Engagements" strokeWidth={2} />
            <Line type="monotone" dataKey="views" stroke="#52c41a" name="Views" />
            <Line type="monotone" dataKey="likes" stroke="#fa8c16" name="Likes" />
            <Line type="monotone" dataKey="comments" stroke="#eb2f96" name="Comments" />
            <Line type="monotone" dataKey="shares" stroke="#722ed1" name="Shares" />
          </LineChart>
        </ResponsiveContainer>
      )}
    </Card>
  );
};

export default EngagementTrendChart;