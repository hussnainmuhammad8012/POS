import React from 'react'
import { NavLink } from 'react-router-dom'
import { LayoutDashboard, Users, MessageSquare, ShieldCheck, LogOut } from 'lucide-react'

const Sidebar = ({ onLogout }) => {
  const handleLogout = () => {
    localStorage.removeItem('token');
    localStorage.removeItem('admin');
    onLogout();
  };

  return (
    <aside className="sidebar glass">
      <div className="brand">
        <ShieldCheck size={28} color="var(--primary)" />
        <h2>RaiRoyals</h2>
      </div>

      <nav>
        <SidebarLink to="/" icon={<LayoutDashboard size={20} />} label="Dashboard" />
        <SidebarLink to="/clients" icon={<Users size={20} />} label="Clients" />
        <SidebarLink to="/feedback" icon={<MessageSquare size={20} />} label="Feedback" />
      </nav>

      <div className="sidebar-footer">
        <button className="logout-btn" onClick={handleLogout}>
          <LogOut size={18} />
          <span>Logout</span>
        </button>
      </div>

      <style>{`
        .sidebar {
          width: 260px;
          height: 100vh;
          position: fixed;
          left: 0;
          top: 0;
          display: flex;
          flex-direction: column;
          padding: 2rem 1.5rem;
          z-index: 100;
        }
        .brand {
          display: flex;
          align-items: center;
          gap: 0.8rem;
          padding: 0 0.5rem;
          margin-bottom: 3rem;
        }
        .brand h2 {
          font-size: 1.4rem;
          letter-spacing: -0.5px;
          background: linear-gradient(to right, #fff, var(--text-secondary));
          -webkit-background-clip: text;
          -webkit-text-fill-color: transparent;
        }
        nav {
          flex: 1;
          display: flex;
          flex-direction: column;
          gap: 0.5rem;
        }
        .sidebar-footer {
          padding-top: 1rem;
          border-top: 1px solid var(--border);
        }
        .logout-btn {
          width: 100%;
          display: flex;
          align-items: center;
          gap: 0.8rem;
          padding: 0.8rem 1rem;
          color: var(--text-secondary);
          background: transparent;
          border-radius: 12px;
          font-size: 0.95rem;
          transition: 0.2s;
        }
        .logout-btn:hover {
          color: var(--danger);
          background: rgba(239, 68, 68, 0.05);
        }
      `}</style>
    </aside>
  )
}

const SidebarLink = ({ to, icon, label }) => {
  return (
    <NavLink 
      to={to} 
      className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`}
    >
      {icon}
      <span>{label}</span>
      <style>{`
        .nav-link {
          display: flex;
          align-items: center;
          gap: 1rem;
          padding: 0.8rem 1rem;
          color: var(--text-secondary);
          border-radius: 12px;
          transition: all 0.2s ease;
          font-weight: 500;
        }
        .nav-link:hover {
          color: var(--text-primary);
          background: rgba(255, 255, 255, 0.05);
        }
        .nav-link.active {
          color: white;
          background: var(--primary);
          box-shadow: 0 4px 12px rgba(99, 102, 241, 0.3);
        }
      `}</style>
    </NavLink>
  )
}

export default Sidebar
