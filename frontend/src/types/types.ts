// Dashboard Summary Types
export interface DashboardSummary {
  total_posts: number;
  total_authors: number;
  total_engagements: number;
  total_views: number;
  total_likes: number;
  total_comments: number;
  total_shares: number;
  avg_engagement_rate: number;
  top_performing_author: string;
  best_time_to_post: string;
  top_category: string;
}

// Advanced Insights Types
export interface AdvancedInsight {
  insight_type: string;
  title: string;
  description: string;
  metric: number;
  trend: string;
  impact: string;
  recommendation: string;
}

// Engagement Heatmap Types
export interface HeatmapData {
  [hour: string]: {
    [day: string]: {
      engagement_count: number;
      intensity: number;
      types: {
        views: number;
        likes: number;
        comments: number;
        shares: number;
      };
    };
  };
}

// Content Performance Types
export interface ContentPerformance {
  post_id: number;
  title: string;
  content_length: number;
  has_media: boolean;
  category: string;
  tags: string[];
  is_promoted: boolean;
  author_category: string;
  total_engagements: number;
  views: number;
  likes: number;
  comments: number;
  shares: number;
  engagement_rate: number;
  quality_ratio: number;
  content_quality: string;
}

// Top Engagements Types
export interface EngagementSummary {
  author_id: number;
  author_name: string;
  author_category: string;
  post_category: string;
  total_views: number;
  total_likes: number;
  total_comments: number;
  total_shares: number;
  engagement_score: number;
  engagement_rate: number;
}

// Engagement Trend Types
export interface TrendPoint {
  engagement_date: string;
  views: number;
  likes: number;
  comments: number;
  shares: number;
  total_engagements: number;
}

// Opportunity Areas Types
export interface OpportunityArea {
  analysis_type: string;
  entity_id: number | null;
  entity_name: string;
  category: string;
  post_category: string | null;
  post_count: number;
  total_engagements: number;
  engagement_per_post: number;
  engagements_per_user: number | null;
  opportunity_score: number;
}

// Advanced Patterns Types
export interface AdvancedPatterns {
  user_behavior: {
    avg_diversity_score: number;
    high_diversity_users: number;
    total_analyzed_users: number;
  };
  content_optimization: {
    best_media_type: string | null;
    promotion_effectiveness: number;
    optimal_tag_count: number;
  };
}

// User Data Types
export interface UserData {
  email: string;
  username?: string;
}

// Author type
export interface Author {
  author_id: number;
  name: string;
}

// Post type
export interface Post {
  post_id: number;
  title: string;
}

// Scatter Point type
export interface ScatterPoint {
  entity_type: string;
  entity_id: string;
  entity_name: string;
  post_count: number;
  engagements_per_post: number;
}

// Engagement Trend Author Category type
export interface EngagementTrendAuthorCategory {
  engagement_date: string;
  author_name: string;
  category: string;
  views: number;
  likes: number;
  comments: number;
  shares: number;
  total_engagements: number;
}
// Dashboard Filters Type
export interface DashboardFilters {
  heatmapPeriod: string;
  contentMinLength: number;
  engagementsPeriod: string;
  engagementsLimit: number;
  opportunityMinPosts: number;
  trendEntityType: string;
  trendEntityId?: number;
  trendEntityName?: string;
  trendDays: number;
}

// Update DashboardContextType to include filters
export interface DashboardContextType {
  userData: UserData | null;
  dashboardSummary: DashboardSummary | null;
  advancedInsights: AdvancedInsight[];
  heatmapData?: HeatmapData | null;
  contentPerformance?: ContentPerformance[];
  topEngagements?: EngagementSummary[];
  engagementTrend?: TrendPoint[];
  opportunityAreas?: OpportunityArea[];
  advancedPatterns: AdvancedPatterns | null;
  loading: boolean;
  // filters: DashboardFilters;
  // updateFilters: (filters: Partial<DashboardFilters>) => void;
  fetchDashboardData: () => Promise<void>;
  // refreshWithFilters: (filters: Partial<DashboardFilters>) => Promise<void>;
}
