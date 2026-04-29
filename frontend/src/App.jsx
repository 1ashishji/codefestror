import React from 'react';
import { BrowserRouter as Router, Routes, Route, Link, useLocation } from 'react-router-dom';
import { LayoutDashboard, Users, BarChart3, PlusCircle } from 'lucide-react';
import Dashboard from './pages/Dashboard';
import Employees from './pages/Employees';
import Insights from './pages/Insights';
import EmployeeForm from './components/EmployeeForm';

const NavLink = ({ to, icon: Icon, children }) => {
  const location = useLocation();
  const isActive = location.pathname === to;
  
  return (
    <Link 
      to={to} 
      className={`nav-link ${isActive ? 'active' : ''}`}
    >
      <Icon size={20} />
      <span>{children}</span>
    </Link>
  );
};

const App = () => {
  return (
    <Router>
      <div className="app-container">
        <aside className="sidebar">
          <div className="sidebar-header">
            <div className="logo">
              <div className="logo-icon">S</div>
              <span>SalaryPortal</span>
            </div>
          </div>
          
          <nav className="sidebar-nav">
            <NavLink to="/" icon={LayoutDashboard}>Dashboard</NavLink>
            <NavLink to="/employees" icon={Users}>Employees</NavLink>
            <NavLink to="/insights" icon={BarChart3}>Salary Insights</NavLink>
          </nav>
          
          <div className="sidebar-footer">
            <button className="btn btn-primary w-full gap-2">
              <PlusCircle size={18} />
              <span>New Employee</span>
            </button>
          </div>
        </aside>

        <main className="main-content">
          <header className="top-bar">
            <div className="search-box">
              <input type="text" placeholder="Search employees..." className="input" />
            </div>
            <div className="user-profile">
              <div className="avatar">AM</div>
            </div>
          </header>

          <div className="page-container">
            <Routes>
              <Route path="/" element={<Dashboard />} />
              <Route path="/employees" element={<Employees />} />
              <Route path="/insights" element={<Insights />} />
              <Route path="/employees/new" element={<EmployeeForm />} />
              <Route path="/employees/edit/:id" element={<EmployeeForm />} />
            </Routes>
          </div>
        </main>
      </div>

      <style jsx>{`
        .app-container {
          display: flex;
          min-height: 100vh;
        }

        .sidebar {
          width: 260px;
          background: #ffffff;
          border-right: 1px solid var(--border);
          display: flex;
          flex-direction: column;
          padding: 1.5rem;
          position: fixed;
          height: 100vh;
        }

        .sidebar-header {
          margin-bottom: 2.5rem;
        }

        .logo {
          display: flex;
          align-items: center;
          gap: 0.75rem;
          font-weight: 700;
          font-size: 1.25rem;
          color: var(--primary);
        }

        .logo-icon {
          width: 32px;
          height: 32px;
          background: var(--primary);
          color: white;
          display: flex;
          align-items: center;
          justify-content: center;
          border-radius: 0.5rem;
        }

        .sidebar-nav {
          display: flex;
          flex-direction: column;
          gap: 0.5rem;
          flex: 1;
        }

        .nav-link {
          display: flex;
          align-items: center;
          gap: 0.75rem;
          padding: 0.75rem 1rem;
          border-radius: 0.5rem;
          color: var(--text-muted);
          font-weight: 500;
          transition: all 0.2s;
        }

        .nav-link:hover {
          background: #f8fafc;
          color: var(--primary);
        }

        .nav-link.active {
          background: #eef2ff;
          color: var(--primary);
        }

        .main-content {
          flex: 1;
          margin-left: 260px;
          display: flex;
          flex-direction: column;
        }

        .top-bar {
          height: 64px;
          background: white;
          border-bottom: 1px solid var(--border);
          display: flex;
          align-items: center;
          justify-content: space-between;
          padding: 0 2rem;
          position: sticky;
          top: 0;
          z-index: 10;
        }

        .search-box {
          width: 400px;
        }

        .avatar {
          width: 36px;
          height: 36px;
          background: #e2e8f0;
          border-radius: 50%;
          display: flex;
          align-items: center;
          justify-content: center;
          font-size: 0.875rem;
          font-weight: 600;
          color: var(--text-muted);
        }

        .page-container {
          padding: 2rem;
        }

        .w-full { width: 100%; }
        .gap-2 { gap: 0.5rem; }
      `}</style>
    </Router>
  );
};

export default App;
