import axios from 'axios';
import { Form, Input, Button, Checkbox, message } from 'antd';
import type { 
  DashboardSummary, 
  AdvancedInsight, 
  HeatmapData, 
  ContentPerformance, 
  EngagementSummary, 
  TrendPoint, 
  OpportunityArea, 
  AdvancedPatterns, 
  UserData,
  Author,
  Post,
  ScatterPoint,
  EngagementTrendAuthorCategory
} from '../types/types';

export type {
  DashboardSummary, 
  AdvancedInsight, 
  HeatmapData, 
  ContentPerformance, 
  EngagementSummary, 
  TrendPoint, 
  OpportunityArea, 
  AdvancedPatterns, 
  UserData,
  Author,
  Post,
  ScatterPoint,
  EngagementTrendAuthorCategory
} from '../types/types';


const API_URL = process.env.REACT_APP_BACKEND_API_URL;

// Create axios instance with interceptors
const api = axios.create({
  baseURL: API_URL
});

// Add request interceptor to include access token
api.interceptors.request.use(config => {
  const token = localStorage.getItem('accessToken');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
}, error => {
  return Promise.reject(error);
});

// Add response interceptor to handle token expiration
api.interceptors.response.use(response => {
  return response;
}, error => {
  if (error.response?.status === 401) {
    localStorage.removeItem('accessToken');
    localStorage.removeItem('refreshToken');
    window.location.href = '/login';
  }
  return Promise.reject(error);
});

// Dashboard API functions
export const getDashboardSummary = async (): Promise<DashboardSummary> => {
  try {
    const response = await api.get('/api/v1/insight/dashboard-summary');
    return response.data;
  } catch (error) {
    console.error('Error fetching dashboard summary:', error);
    return generateDummyDashboardSummary();
  }
};

export const getAdvancedInsights = async (): Promise<AdvancedInsight[]> => {
  try {
    const response = await api.get('/api/v1/insight/advanced-insights');
    return response.data;
  } catch (error) {
    console.error('Error fetching advanced insights:', error);
    return generateDummyAdvancedInsights();
  }
};

export const downloadData = async (): Promise<Blob> => {
  try {
    const response = await api.get('/api/v1/insight/download-data', {
      responseType: 'blob'
    });
    message.success("Data downloaded successfully");
    return response.data;
  } catch (error) {
    console.error('Error downloading data:', error);
    throw error;
  }
};

export const downloadReport = async (): Promise<Blob> => {
  try {
    const response = await api.get('/api/v1/insight/download-report', {
      responseType: 'blob'
    });
    message.success("Report downloaded successfully");
    return response.data;
  } catch (error) {
    console.error('Error downloading report:', error);
    throw error;
  }
};

export const getEngagementHeatmap = async (period: string = 'last_year'): Promise<HeatmapData> => {
  try {
    const response = await api.get(`/api/v1/insight/engagement-heatmap?period=${period}`);
    return response.data;
  } catch (error) {
    console.error('Error fetching engagement heatmap:', error);
    return generateDummyHeatmapData();
  }
};

export const getContentPerformance = async (minContentLength: number = 500): Promise<ContentPerformance[]> => {
  try {
    const response = await api.get(`/api/v1/insight/content-performance?min_content_length=${minContentLength}`);
    return response.data;
  } catch (error) {
    console.error('Error fetching content performance:', error);
    return generateDummyContentPerformance();
  }
};

export const getTopEngagements = async (period: string = 'last_year', limit: number = 10): Promise<EngagementSummary[]> => {
  try {
    const response = await api.get(`/api/v1/insight/top-engagements?period=${period}&limit=${limit}`);
    return response.data;
  } catch (error) {
    console.error('Error fetching top engagements:', error);
    return generateDummyTopEngagements();
  }
};

export const getOpportunityAreas = async (minPosts: number = 2): Promise<OpportunityArea[]> => {
  try {
    const response = await api.get(`/api/v1/insight/opportunity-areas?min_posts=${minPosts}`);
    return response.data;
  } catch (error) {
    console.error('Error fetching opportunity areas:', error);
    return generateDummyOpportunityAreas();
  }
};

export const getAdvancedPatterns = async (): Promise<AdvancedPatterns> => {
  try {
    const response = await api.get('/api/v1/insight/advanced-patterns');
    return response.data;
  } catch (error) {
    console.error('Error fetching advanced patterns:', error);
    return generateDummyAdvancedPatterns();
  }
};

export const getUserData = async (): Promise<UserData> => {
  try {
    const response = await api.get('/api/v1/insight/user');
    return response.data;
  } catch (error) {
    console.error('Error fetching user data:', error);
    return { email: 'a', username: 'admin' };
  }
};

export const logoutUser = () => {
  try {
    // Remove stored tokens (localStorage, sessionStorage, or cookies)
    localStorage.removeItem('accessToken'); // or your token key
    localStorage.removeItem('refreshToken'); // if you have a refresh token
    // sessionStorage.removeItem('accessToken'); // if stored in sessionStorage

    // Redirect to login page
    window.location.href = '/login';
  } catch (error) {
    console.error('Error during logout:', error);
  }
};

export const getAuthors = async (): Promise<Author[]> => {
  try {
    const response = await api.get('/api/v1/insight/authors');
    return response.data;
  } catch (error) {
    console.error('Error fetching authors:', error);
    return [];
  }
};

export const getPosts = async (): Promise<Post[]> => {
  try {
    const response = await api.get('/api/v1/insight/posts');
    return response.data;
  } catch (error) {
    console.error('Error fetching posts:', error);
    return [];
  }
};

export const getCategories = async (): Promise<string[]> => {
  try {
    const response = await api.get('/api/v1/insight/categories');
    return response.data;
  } catch (error) {
    console.error('Error fetching categories:', error);
    return [];
  }
};

export const getScatterPerformance = async (
  period: string = 'last_year',
  entity_type: string = 'author'
): Promise<ScatterPoint[]> => {
  try {
    const response = await api.get(
      `/api/v1/insight/scatter-performance?period=${period}&entity_type=${entity_type}`
    );
    return response.data;
  } catch (error) {
    console.error('Error fetching scatter performance:', error);
    return generateDummyScatterData();
  }
};

export const getEngagementTrendAuthorCategory = async (
  days: number = 365
): Promise<EngagementTrendAuthorCategory[]> => {
  try {
    const response = await api.get(
      `/api/v1/insight/engagement-trend-author-category?days=${days}`
    );
    return response.data;
  } catch (error) {
    console.error('Error fetching engagement trend author category:', error);
    return generateDummyEngagementTrendAuthorCategory();
  }
};

// Update the engagement trend function to match new backend
export const getEngagementTrend = async (
  entityType: string,
  authorName?: string,
  postTitle?: string,
  categoryName?: string,
  days: number = 365
): Promise<any[]> => {
  try {
    const params = new URLSearchParams({
      entity_type: entityType,
      days: days.toString()
    });
    
    if (authorName) params.append('author_name', authorName);
    if (postTitle) params.append('post_title', postTitle);
    if (categoryName) params.append('category_name', categoryName);
    
    const response = await api.get(`/api/v1/insight/engagement-trend?${params}`);
    return response.data;
  } catch (error) {
    console.error('Error fetching engagement trend:', error);
    return generateDummyTrendData();
  }
};

// Dummy data generators
const generateDummyScatterData = (): ScatterPoint[] => [
  {
    entity_type: "author",
    entity_id: "1",
    entity_name: "Alice",
    post_count: 5,
    engagements_per_post: 8.2
  },
  {
    entity_type: "author",
    entity_id: "2",
    entity_name: "Bob",
    post_count: 3,
    engagements_per_post: 6.5
  }
];

const generateDummyEngagementTrendAuthorCategory = (): EngagementTrendAuthorCategory[] => {
  const data: EngagementTrendAuthorCategory[] = [];
  for (let i = 0; i < 30; i++) {
    data.push({
      engagement_date: new Date(Date.now() - (29 - i) * 24 * 60 * 60 * 1000).toISOString(),
      author_name: i % 2 === 0 ? "Alice" : "Bob",
      category: i % 2 === 0 ? "Tech" : "Lifestyle",
      views: Math.floor(Math.random() * 100) + 50,
      likes: Math.floor(Math.random() * 30) + 10,
      comments: Math.floor(Math.random() * 10) + 5,
      shares: Math.floor(Math.random() * 5) + 1,
      total_engagements: 0
    });
  }
  return data.map(d => ({ ...d, total_engagements: d.views + d.likes + d.comments + d.shares }));
};

// Dummy data generators for fallback
const generateDummyDashboardSummary = (): DashboardSummary => ({
  total_posts: 156,
  total_authors: 24,
  total_engagements: 12450,
  total_views: 89234,
  total_likes: 5678,
  total_comments: 1234,
  total_shares: 789,
  avg_engagement_rate: 4.2,
  top_performing_author: "Sarah Johnson",
  best_time_to_post: "Weekdays 2-4 PM",
  top_category: "Technology"
});

const generateDummyAdvancedInsights = (): AdvancedInsight[] => [
  {
    insight_type: "engagement",
    title: "Video Content Drives 3x More Engagement",
    description: "Posts with video content show significantly higher engagement rates",
    metric: 3.2,
    trend: "increasing",
    impact: "high",
    recommendation: "Increase video content production by 40%"
  },
  {
    insight_type: "timing",
    title: "Optimal Posting Time Identified",
    description: "2-4 PM on weekdays generates 45% more engagement",
    metric: 45,
    trend: "consistent",
    impact: "medium",
    recommendation: "Schedule key content for 2-4 PM time slot"
  }
];

const generateDummyHeatmapData = (): HeatmapData => ({
  "9": { "0": { engagement_count: 15, intensity: 2, types: { views: 10, likes: 3, comments: 1, shares: 1 } } },
  "10": { "0": { engagement_count: 25, intensity: 3, types: { views: 15, likes: 6, comments: 2, shares: 2 } } },
  "14": { "1": { engagement_count: 45, intensity: 4, types: { views: 25, likes: 12, comments: 5, shares: 3 } } },
  "15": { "1": { engagement_count: 52, intensity: 5, types: { views: 30, likes: 14, comments: 6, shares: 2 } } }
});

const generateDummyContentPerformance = (): ContentPerformance[] => [
  {
    post_id: 101,
    title: "The Future of AI in Content Creation",
    content_length: 1200,
    has_media: true,
    category: "Technology",
    tags: ["AI", "Content", "Future"],
    is_promoted: true,
    author_category: "Tech",
    total_engagements: 456,
    views: 320,
    likes: 89,
    comments: 32,
    shares: 15,
    engagement_rate: 12.5,
    quality_ratio: 1.8,
    content_quality: "high_quality"
  }
];

const generateDummyTopEngagements = (): EngagementSummary[] => [
  {
    author_id: 1,
    author_name: "Sarah Johnson",
    author_category: "Technology",
    post_category: "Tech",
    total_views: 2345,
    total_likes: 567,
    total_comments: 123,
    total_shares: 45,
    engagement_score: 89,
    engagement_rate: 15.2
  }
];

const generateDummyTrendData = (): TrendPoint[] => {
  const data: TrendPoint[] = [];
  for (let i = 0; i < 30; i++) {
    data.push({
      engagement_date: new Date(Date.now() - (29 - i) * 24 * 60 * 60 * 1000).toISOString(),
      views: Math.floor(Math.random() * 100) + 50,
      likes: Math.floor(Math.random() * 30) + 10,
      comments: Math.floor(Math.random() * 10) + 5,
      shares: Math.floor(Math.random() * 5) + 1,
      total_engagements: 0
    });
  }
  return data.map(d => ({ ...d, total_engagements: d.views + d.likes + d.comments + d.shares }));
};

const generateDummyOpportunityAreas = (): OpportunityArea[] => [
  {
    analysis_type: "author",
    entity_id: 5,
    entity_name: "Michael Chen",
    category: "Lifestyle",
    post_category: null,
    post_count: 8,
    total_engagements: 234,
    engagement_per_post: 29.25,
    engagements_per_user: 15.6,
    opportunity_score: 3.8
  }
];

const generateDummyAdvancedPatterns = (): AdvancedPatterns => ({
  user_behavior: {
    avg_diversity_score: 7.2,
    high_diversity_users: 15,
    total_analyzed_users: 24
  },
  content_optimization: {
    best_media_type: "video",
    promotion_effectiveness: 2.8,
    optimal_tag_count: 5
  }
});
