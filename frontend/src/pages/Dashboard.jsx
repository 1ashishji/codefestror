import React, { useState, useEffect } from 'react';
import { Users, DollarSign, Briefcase, TrendingUp } from 'lucide-react';
import StatCard from '../components/StatCard';
import api from '../api';

const Dashboard = () => {
  const [stats, setStats] = useState({
    total_employees: 0,
    average_salary: 0,
    total_payroll: 0
  });
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchStats = async () => {
      try {
        const response = await api.get('/insights/global_summary');
        setStats(response.data.data);
      } catch (error) {
        console.error('Error fetching dashboard stats:', error);
      } finally {
        setLoading(false);
      }
    };
    fetchStats();
  }, []);

  return (
    <div className="dashboard">
      <h1>Executive Overview</h1>
      
      <div className="stats-grid">
        <StatCard 
          title="Total Employees" 
          value={loading ? '...' : stats.total_employees.toLocaleString()} 
          subtext="Active in organization"
          icon={Users}
          color="primary"
        />
        <StatCard 
          title="Average Salary" 
          value={loading ? '...' : `$${Number(stats.average_salary || 0).toLocaleString()}`} 
          subtext="Global average"
          icon={Briefcase}
          color="info"
        />
        <StatCard 
          title="Total Payroll" 
          value={loading ? '...' : `$${Number(stats.total_payroll || 0).toLocaleString()}`} 
          subtext="Monthly expenditure"
          icon={DollarSign}
          color="success"
        />
        <StatCard 
          title="Growth Rate" 
          value="+12.5%" 
          subtext="vs last quarter"
          icon={TrendingUp}
          color="accent"
        />
      </div>

      <div className="dashboard-grid">
        <div className="card span-2">
          <h3>Recent Activity</h3>
          <div className="activity-placeholder">
            <p className="text-muted">No recent activity found.</p>
          </div>
        </div>
        <div className="card">
          <h3>Alerts & Notifications</h3>
          <div className="alert-item">
            <div className="alert-dot warning"></div>
            <span>New payroll cycle starting soon</span>
          </div>
        </div>
      </div>

      <style jsx>{`
        .stats-grid {
          display: grid;
          grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
          gap: 1.5rem;
          margin-bottom: 2rem;
        }

        .dashboard-grid {
          display: grid;
          grid-template-columns: 2fr 1fr;
          gap: 1.5rem;
        }

        .span-2 { grid-column: span 2; }

        .activity-placeholder {
          height: 200px;
          display: flex;
          align-items: center;
          justify-content: center;
        }

        .alert-item {
          display: flex;
          align-items: center;
          gap: 0.75rem;
          padding: 0.75rem 0;
          font-size: 0.875rem;
        }

        .alert-dot {
          width: 8px;
          height: 8px;
          border-radius: 50%;
        }

        .alert-dot.warning { background: #fbbf24; }
      `}</style>
    </div>
  );
};

export default Dashboard;
