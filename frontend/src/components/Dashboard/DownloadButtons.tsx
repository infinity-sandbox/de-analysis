import React, { useState } from 'react';
import { Card, Button, Typography, Alert, Space } from 'antd';
import { DownloadOutlined, FileZipOutlined, FilePptOutlined, CloudDownloadOutlined } from '@ant-design/icons';
import { downloadData, downloadReport } from '../../services/api';

const { Title, Text } = Typography;

const DownloadButtons: React.FC = () => {
  const [downloadingData, setDownloadingData] = useState(false);
  const [downloadingReport, setDownloadingReport] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleDownloadData = async () => {
    setDownloadingData(true);
    setError(null);
    try {
      const blob = await downloadData();
      
      // Create a download link for the zip file
      const url = window.URL.createObjectURL(blob);
      const link = document.createElement('a');
      link.href = url;
      link.setAttribute('download', 'data.zip');
      document.body.appendChild(link);
      link.click();
      
      // Clean up
      window.URL.revokeObjectURL(url);
      document.body.removeChild(link);
    } catch (err: any) {
      console.error('Download failed:', err);
      setError(err.response?.data?.detail || 'Failed to download data. Please try again.');
    } finally {
      setDownloadingData(false);
    }
  };

  const handleDownloadReport = async () => {
    setDownloadingReport(true);
    setError(null);
    try {
      const blob = await downloadReport();
      
      // Create a download link for the PowerPoint file
      const url = window.URL.createObjectURL(blob);
      const link = document.createElement('a');
      link.href = url;
      link.setAttribute('download', 'analytics_report.pptx');
      document.body.appendChild(link);
      link.click();
      
      // Clean up
      window.URL.revokeObjectURL(url);
      document.body.removeChild(link);
    } catch (err: any) {
      console.error('Download failed:', err);
      setError(err.response?.data?.detail || 'Failed to download report. Please try again.');
    } finally {
      setDownloadingReport(false);
    }
  };

  return (
    <Card style={{ marginTop: '24px' }}>
      <Title level={4}>
        <CloudDownloadOutlined /> Export Data & Reports
      </Title>
      
      {error && (
        <Alert
          message="Download Error"
          description={error}
          type="error"
          showIcon
          closable
          onClose={() => setError(null)}
          style={{ marginBottom: '16px' }}
        />
      )}

      <Space direction="vertical" size="middle" style={{ width: '100%' }}>
        <div>
          <Text strong>Download Complete Dataset</Text>
          <div style={{ marginTop: '8px' }}>
            <Button
              type="primary"
              icon={<FileZipOutlined />}
              loading={downloadingData}
              onClick={handleDownloadData}
              size="large"
              style={{ 
                backgroundColor: '#52c41a',
                borderColor: '#52c41a',
                marginRight: '16px'
              }}
            >
              {downloadingData ? 'Downloading...' : 'Download Data (ZIP)'}
            </Button>
            <Text type="secondary">
              Includes all database tables as CSV and Excel files in a ZIP archive
            </Text>
          </div>
        </div>

        <div>
          <Text strong>Download Analytics Report</Text>
          <div style={{ marginTop: '8px' }}>
            <Button
              type="primary"
              icon={<FilePptOutlined />}
              loading={downloadingReport}
              onClick={handleDownloadReport}
              size="large"
              style={{ 
                backgroundColor: '#1890ff',
                borderColor: '#1890ff',
                marginRight: '16px'
              }}
            >
              {downloadingReport ? 'Downloading...' : 'Download Report (PPTX)'}
            </Button>
            <Text type="secondary">
              Comprehensive PowerPoint report with analytics and insights
            </Text>
          </div>
        </div>
      </Space>

      <div style={{ marginTop: '16px', padding: '12px', background: '#f6ffed', borderRadius: '4px' }}>
        <Text type="secondary">
          <strong>Note:</strong> The data download includes all database tables (authors, engagements, post_metadata, posts, users) 
          in both CSV and Excel formats. The report delivers an in-depth overview of content performance.
        </Text>
      </div>
    </Card>
  );
};

export default DownloadButtons;