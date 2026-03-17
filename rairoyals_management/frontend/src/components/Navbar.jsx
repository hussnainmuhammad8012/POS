import React from 'react'
import { Bell, Search, User } from 'lucide-react'

const Navbar = () => {
  const admin = JSON.parse(localStorage.getItem('admin') || '{"username": "Admin User", "role": "Super Admin"}');

  return (
    <nav className="navbar glass">
      <div className="search-field">
        <Search size={18} color="var(--text-secondary)" />
        <input type="text" placeholder="Global search..." />
      </div>

      <div className="nav-actions">
        <button className="icon-btn notification">
          <Bell size={20} />
          <span className="badge"></span>
        </button>
        <div className="user-profile">
          <div className="user-info">
            <strong>{admin.username}</strong>
            <span>{admin.role.charAt(0).toUpperCase() + admin.role.slice(1)}</span>
          </div>
          <div className="avatar">
            <User size={20} />
          </div>
        </div>
      </div>

      <style>{`
        .navbar {
          height: 80px;
          display: flex;
          align-items: center;
          justify-content: space-between;
          padding: 0 2rem;
          margin: 1.5rem 0 0; 
          border-radius: 20px;
          position: sticky;
          top: 1.5rem;
          z-index: 90;
        }
        .search-field {
          display: flex;
          align-items: center;
          gap: 0.8rem;
          background: rgba(255, 255, 255, 0.05);
          padding: 0.6rem 1.2rem;
          border-radius: 12px;
          width: 300px;
        }
        .search-field input {
          background: transparent;
          border: none;
          color: white;
          outline: none;
          width: 100%;
          font-size: 0.9rem;
        }
        .nav-actions {
          display: flex;
          align-items: center;
          gap: 1.5rem;
        }
        .icon-btn {
          position: relative;
          background: rgba(255, 255, 255, 0.05);
          color: var(--text-secondary);
          width: 44px;
          height: 44px;
          border-radius: 12px;
          display: flex;
          align-items: center;
          justify-content: center;
        }
        .icon-btn:hover {
          color: var(--text-primary);
          background: rgba(255, 255, 255, 0.1);
        }
        .badge {
          position: absolute;
          top: 10px;
          right: 12px;
          width: 8px;
          height: 8px;
          background: var(--danger);
          border-radius: 50%;
          border: 2px solid var(--bg-card);
        }
        .user-profile {
          display: flex;
          align-items: center;
          gap: 1rem;
          padding-left: 1.5rem;
          border-left: 1px solid rgba(255, 255, 255, 0.1);
        }
        .user-info {
          display: flex;
          flex-direction: column;
          align-items: flex-end;
        }
        .user-info strong {
          font-size: 0.95rem;
        }
        .user-info span {
          font-size: 0.75rem;
          color: var(--text-secondary);
        }
        .avatar {
          width: 44px;
          height: 44px;
          background: var(--primary);
          border-radius: 12px;
          display: flex;
          align-items: center;
          justify-content: center;
          color: white;
        }
      `}</style>
    </nav>
  )
}

export default Navbar
