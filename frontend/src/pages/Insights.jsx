import React, { useState, useEffect } from 'react';
import { BarChart, Globe, Briefcase, Filter } from 'lucide-react';
import api from '../api';

const Insights = () => {
  const [globalStats, setGlobalStats] = useState(null);
  const [countryStats, setCountryStats] = useState(null);
  const [titleStats, setTitleStats] = useState([]);
  const [selectedCountry, setSelectedCountry] = useState('US');
  const [loading, setLoading] = useState(true);

  const fetchInsights = async () => {
    setLoading(true);
    try {
      const [globalRes, countryRes, titlesRes] = await Promise.all([
        api.get('/insights/global_summary'),
        api.get(`/insights/salary_by_country?country=${selectedCountry}`),
        api.get(`/insights/salary_by_all_titles_in_country?country=${selectedCountry}`)
      ]);
      
      setGlobalStats(globalRes.data.data);
      setCountryStats(countryRes.data.data);
      setTitleStats(titlesRes.data.data);
    } catch (error) {
      console.error('Error fetching insights:', error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchInsights();
  }, [selectedCountry]);

  return (
    <div className="insights-page">
      <div className="page-header">
        <h1>Salary Insights</h1>
        <div className="filter-group">
          <Globe size={18} className="text-muted" />
          <select 
            value={selectedCountry} 
            onChange={(e) => setSelectedCountry(e.target.value)}
            className="select-input"
          >
            <option value="US">United States</option>
            <option value="UK">United Kingdom</option>
            <option value="IN">India</option>
            <option value="DE">Germany</option>
            <option value="CA">Canada</option>
          </select>
        </div>
      </div>

      <div className="insights-grid">
        <div className="card">
          <div className="card-header">
            <h3 className="flex items-center gap-2">
              <Globe size={20} className="text-primary" />
              Country Summary: {selectedCountry}
            </h3>
          </div>
          {loading ? (
            <p>Loading summary...</p>
          ) : countryStats ? (
            <div className="stats-list">
              <div className="stat-item">
                <span className="label">Total Employees</span>
                <span className="value">{countryStats.metrics?.count || 0}</span>
              </div>
              <div className="stat-item">
                <span className="label">Average Salary</span>
                <span className="value">${Number(countryStats.metrics?.avg || 0).toLocaleString()}</span>
              </div>
              <div className="stat-item">
                <span className="label">Top Job Title</span>
                <span className="value badge badge-info">{countryStats.metrics?.top_job_title || 'N/A'}</span>
              </div>
            </div>
          ) : (
            <p>No data available for this country.</p>
          )}
        </div>

        <div className="card span-2">
          <div className="card-header">
            <h3 className="flex items-center gap-2">
              <BarChart size={20} className="text-primary" />
              Salary by Job Title ({selectedCountry})
            </h3>
          </div>
          <div className="table-container">
            <table>
              <thead>
                <tr>
                  <th>Job Title</th>
                  <th>Avg Salary</th>
                  <th>Min</th>
                  <th>Max</th>
                  <th>Count</th>
                </tr>
              </thead>
              <tbody>
                {loading ? (
                  <tr><td colSpan="5" className="text-center">Loading...</td></tr>
                ) : titleStats.length === 0 ? (
                  <tr><td colSpan="5" className="text-center">No titles found.</td></tr>
                ) : (
                  titleStats.map((stat, i) => (
                    <tr key={stat.job_title}>
                      <td className="font-semibold">{stat.job_title}</td>
                      <td className="text-primary font-bold">${Number(stat.avg || 0).toLocaleString()}</td>
                      <td>${Number(stat.min || 0).toLocaleString()}</td>
                      <td>${Number(stat.max || 0).toLocaleString()}</td>
                      <td>
                        <span className="badge">{stat.count || 0}</span>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <style jsx>{`
        .page-header {
          display: flex;
          justify-content: space-between;
          align-items: center;
          margin-bottom: 2rem;
        }

        .filter-group {
          display: flex;
          align-items: center;
          gap: 0.75rem;
          background: white;
          padding: 0.5rem 1rem;
          border-radius: 0.5rem;
          border: 1px solid var(--border);
        }

        .select-input {
          border: none;
          font-weight: 500;
          outline: none;
          cursor: pointer;
        }

        .insights-grid {
          display: grid;
          grid-template-columns: 1fr 2fr;
          gap: 1.5rem;
        }

        .span-2 { grid-column: span 1; }
        @media (min-width: 1024px) {
          .span-2 { grid-column: span 1; }
        }

        .stats-list {
          display: flex;
          flex-direction: column;
          gap: 1.25rem;
          margin-top: 1rem;
        }

        .stat-item {
          display: flex;
          justify-content: space-between;
          align-items: center;
          padding-bottom: 0.75rem;
          border-bottom: 1px solid #f1f5f9;
        }

        .stat-item .label {
          color: var(--text-muted);
          font-size: 0.875rem;
        }

        .stat-item .value {
          font-weight: 600;
        }

        .font-bold { font-weight: 700; }
        .text-primary { color: var(--primary); }
        .flex { display: flex; }
        .items-center { align-items: center; }
        .gap-2 { gap: 0.5rem; }
        .table-container { overflow-x: auto; }
      `}</style>
    </div>
  );
};

export default Insights;
