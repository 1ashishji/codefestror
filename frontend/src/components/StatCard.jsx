import React from 'react';

const StatCard = ({ title, value, subtext, icon: Icon, color = 'primary' }) => {
  const colorMap = {
    primary: 'text-indigo-600 bg-indigo-50',
    success: 'text-emerald-600 bg-emerald-50',
    info: 'text-blue-600 bg-blue-50',
    accent: 'text-rose-600 bg-rose-50'
  };

  return (
    <div className="card">
      <div className="stat-card-header">
        <div className={`icon-wrapper ${color}`}>
          <Icon size={24} />
        </div>
        <div className="stat-content">
          <p className="stat-title">{title}</p>
          <h3 className="stat-value">{value}</h3>
          {subtext && <p className="stat-subtext">{subtext}</p>}
        </div>
      </div>
      <style jsx>{`
        .stat-card-header {
          display: flex;
          align-items: flex-start;
          gap: 1rem;
        }

        .icon-wrapper {
          padding: 0.75rem;
          border-radius: 0.75rem;
          display: flex;
          align-items: center;
          justify-content: center;
        }

        .icon-wrapper.primary { background: #eef2ff; color: #4f46e5; }
        .icon-wrapper.success { background: #ecfdf5; color: #10b981; }
        .icon-wrapper.info { background: #eff6ff; color: #3b82f6; }
        .icon-wrapper.accent { background: #fff1f2; color: #f43f5e; }

        .stat-content {
          flex: 1;
        }

        .stat-title {
          font-size: 0.875rem;
          color: var(--text-muted);
          font-weight: 500;
          margin-bottom: 0.25rem;
        }

        .stat-value {
          font-size: 1.5rem;
          font-weight: 700;
          color: var(--text-main);
          margin-bottom: 0.125rem;
        }

        .stat-subtext {
          font-size: 0.75rem;
          color: var(--text-muted);
        }
      `}</style>
    </div>
  );
};

export default StatCard;
