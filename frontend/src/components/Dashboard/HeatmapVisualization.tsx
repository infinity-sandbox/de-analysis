import React, { useState, useEffect } from 'react';
import { Card, Select, Typography, Spin, Row, Col } from 'antd';
import { getEngagementHeatmap, HeatmapData as HeatmapDataType } from '../../services/api';

const { Option } = Select;
const { Title } = Typography;

const HeatmapVisualization: React.FC = () => {
  const [heatmapData, setHeatmapData] = useState<HeatmapDataType | null>(null);
  const [loading, setLoading] = useState(false);
  const [period, setPeriod] = useState('last_year');

  useEffect(() => {
    fetchData();
  }, [period]);

  const fetchData = async () => {
    setLoading(true);
    try {
      const data = await getEngagementHeatmap(period);
      setHeatmapData(data);
    } catch (error) {
      console.error('Error fetching heatmap data:', error);
    } finally {
      setLoading(false);
    }
  };

  const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  const hours = Array.from({ length: 24 }, (_, i) => i);

  const getIntensityColor = (intensity: number) => {
    if (intensity === 0) return '#f0f0f0';
    if (intensity <= 2) return '#d0e6ff';
    if (intensity <= 4) return '#69c0ff';
    if (intensity <= 6) return '#1890ff';
    return '#0050b3';
  };

  const getEngagementCount = (hour: number, dayIndex: number) => {
    const hourData = heatmapData?.[hour.toString()];
    const dayData = hourData ? hourData[dayIndex.toString()] : null;
    return dayData ? dayData.engagement_count : 0;
  };

  const getIntensity = (hour: number, dayIndex: number) => {
    const hourData = heatmapData?.[hour.toString()];
    const dayData = hourData ? hourData[dayIndex.toString()] : null;
    return dayData ? dayData.intensity : 0;
  };

  return (
    <Card>
      <Title level={4}>Engagement Heatmap (Hour vs Day)</Title>
      
      {/* Filter */}
      <div style={{ marginBottom: '16px' }}>
        <span>Period: </span>
        <Select
          value={period}
          onChange={setPeriod}
          style={{ width: '150px', marginLeft: '8px' }}
          size="small"
        >
          <Option value="last_7_days">Last 7 Days</Option>
          <Option value="last_30_days">Last 30 Days</Option>
          <Option value="last_3_months">Last 3 Months</Option>
          <Option value="last_year">Last Year</Option>
        </Select>
      </div>

      {loading ? (
        <div style={{ height: '300px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <Spin />
        </div>
      ) : heatmapData ? (
        <div style={{ overflowX: 'auto' }}>
          <div style={{ minWidth: '600px' }}>
            <Row gutter={[2, 2]} style={{ marginBottom: '8px' }}>
              <Col span={3}></Col>
              {days.map(day => (
                <Col key={day} span={3}>
                  <div style={{ textAlign: 'center', fontWeight: 'bold', fontSize: '12px' }}>{day}</div>
                </Col>
              ))}
            </Row>
            
            {hours.map(hour => (
              <Row key={hour} gutter={[2, 2]} style={{ marginBottom: '2px' }}>
                <Col span={3}>
                  <div style={{ textAlign: 'right', paddingRight: '8px', fontSize: '11px' }}>
                    {hour === 0 ? '12 AM' : hour < 12 ? `${hour} AM` : hour === 12 ? '12 PM' : `${hour - 12} PM`}
                  </div>
                </Col>
                {days.map((_, dayIndex) => {
                  const intensity = getIntensity(hour, dayIndex);
                  const count = getEngagementCount(hour, dayIndex);
                  
                  return (
                    <Col key={dayIndex} span={3}>
                      <div
                        style={{
                          backgroundColor: getIntensityColor(intensity),
                          height: '20px',
                          borderRadius: '2px',
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'center',
                          fontSize: '10px',
                          color: intensity > 3 ? 'white' : 'black',
                          cursor: 'pointer',
                          border: '1px solid #f0f0f0'
                        }}
                        title={`${hour}:00, ${days[dayIndex]}: ${count} engagements (Intensity: ${intensity})`}
                      >
                        {count > 0 ? count : ''}
                      </div>
                    </Col>
                  );
                })}
              </Row>
            ))}
          </div>
        </div>
      ) : (
        <div style={{ height: '300px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <p>No heatmap data available</p>
        </div>
      )}
      
      <div style={{ marginTop: '16px', fontSize: '12px', color: '#666' }}>
        <div>Color intensity indicates engagement level</div>
        {/* <div>Hover over cells to see engagement counts and intensity</div> */}
        <div>Period: {period.replace(/_/g, ' ')}</div>
      </div>
    </Card>
  );
};

export default HeatmapVisualization;