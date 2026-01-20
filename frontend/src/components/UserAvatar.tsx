import React, { useState } from 'react';
import { Avatar, Dropdown, Menu, Button } from 'antd';
import { LogoutOutlined, UserOutlined } from '@ant-design/icons';
import { logoutUser } from '../services/api';

interface UserAvatarProps {
  email: string;
  username?: string;
}

const UserAvatar: React.FC<UserAvatarProps> = ({ email, username }) => {
  const [visible, setVisible] = useState(false);
  
  const handleLogout = async () => {
    try {
      await logoutUser();
    } catch (error) {
      console.error('Logout failed:', error);
    }
  };

  const menu = (
    <Menu>
      <Menu.Item key="profile" icon={<UserOutlined />}>
        {username || email}
      </Menu.Item>
      <Menu.Divider />
      <Menu.Item key="logout" onClick={handleLogout} icon={<LogoutOutlined />}>
        Logout
      </Menu.Item>
    </Menu>
  );

  return (
    <Dropdown 
      overlay={menu} 
      trigger={['click']}
      onOpenChange={setVisible}
      placement="bottomRight"
    >
      <Avatar 
        style={{ 
          backgroundColor: '#1890ff', 
          cursor: 'pointer',
          fontWeight: 'bold',
          fontSize: '18px'
        }}
      >
        {email ? email.charAt(0).toUpperCase() : "U"}
      </Avatar>
    </Dropdown>
  );
};

export default UserAvatar;