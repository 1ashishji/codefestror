import React, { useState, useEffect } from 'react';
import { Search, ChevronLeft, ChevronRight, Edit2, Trash2, MoreVertical } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import api from '../api';

const Employees = () => {
  const [employees, setEmployees] = useState([]);
  const [loading, setLoading] = useState(true);
  const [cursor, setCursor] = useState(0);
  const [hasMore, setHasMore] = useState(false);
  const [nextCursor, setNextCursor] = useState(null);
  const [searchTerm, setSearchTerm] = useState('');
  const navigate = useNavigate();

  const fetchEmployees = async (currentCursor = 0) => {
    setLoading(true);
    try {
      const response = await api.get('/employees', {
        params: { cursor: currentCursor, limit: 10 }
      });
      setEmployees(response.data.data);
      setNextCursor(response.data.meta.next_cursor);
      setHasMore(response.data.meta.has_more);
    } catch (error) {
      console.error('Error fetching employees:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleSearch = async (e) => {
    e.preventDefault();
    if (!searchTerm) {
      fetchEmployees(0);
      return;
    }
    setLoading(true);
    try {
      const response = await api.get('/employees/search', { params: { q: searchTerm } });
      setEmployees(response.data.data);
      setHasMore(false);
    } catch (error) {
      console.error('Error searching employees:', error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchEmployees(0);
  }, []);

  const deleteEmployee = async (id) => {
    if (window.confirm('Are you sure you want to delete this employee?')) {
      try {
        await api.delete(`/employees/${id}`);
        setEmployees(employees.filter(e => e.id !== id));
      } catch (error) {
        console.error('Error deleting employee:', error);
      }
    }
  };

  return (
    <div className="employees-page">
      <div className="page-header">
        <h1>Employee Directory</h1>
        <button className="btn btn-primary" onClick={() => navigate('/employees/new')}>
          Add Employee
        </button>
      </div>

      <div className="filter-bar card">
        <form onSubmit={handleSearch} className="search-form">
          <Search size={18} className="search-icon" />
          <input 
            type="text" 
            placeholder="Search by name, title, or country..." 
            className="search-input"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
          />
        </form>
      </div>

      <div className="card no-padding">
        <table className="employee-table">
          <thead>
            <tr>
              <th>Full Name</th>
              <th>Job Title</th>
              <th>Country</th>
              <th>Salary</th>
              <th>Currency</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {loading && employees.length === 0 ? (
              <tr><td colSpan="6" className="text-center">Loading...</td></tr>
            ) : employees.length === 0 ? (
              <tr><td colSpan="6" className="text-center">No employees found.</td></tr>
            ) : (
              employees.map((employee) => (
                <tr key={employee.id}>
                  <td className="font-semibold">{employee.full_name}</td>
                  <td>{employee.job_title}</td>
                  <td>
                    <span className="badge badge-info">{employee.country}</span>
                  </td>
                  <td className="font-mono">
                    {Number(employee.salary).toLocaleString()}
                  </td>
                  <td className="text-muted">{employee.currency}</td>
                  <td>
                    <div className="action-buttons">
                      <button 
                        className="action-btn edit" 
                        onClick={() => navigate(`/employees/edit/${employee.id}`)}
                        title="Edit"
                      >
                        <Edit2 size={16} />
                      </button>
                      <button 
                        className="action-btn delete" 
                        onClick={() => deleteEmployee(employee.id)}
                        title="Delete"
                      >
                        <Trash2 size={16} />
                      </button>
                    </div>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>

        <div className="pagination">
          <p className="pagination-info">
            Showing {employees.length} results
          </p>
          <div className="pagination-controls">
            <button 
              className="btn btn-outline" 
              disabled={cursor === 0}
              onClick={() => {
                const prevCursor = Math.max(0, cursor - 10);
                setCursor(prevCursor);
                fetchEmployees(prevCursor);
              }}
            >
              <ChevronLeft size={16} />
              Previous
            </button>
            <button 
              className="btn btn-outline" 
              disabled={!hasMore}
              onClick={() => {
                if (nextCursor) {
                  setCursor(nextCursor);
                  fetchEmployees(nextCursor);
                }
              }}
            >
              Next
              <ChevronRight size={16} />
            </button>
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

        .filter-bar {
          margin-bottom: 1.5rem;
          padding: 0.75rem 1rem;
        }

        .search-form {
          display: flex;
          align-items: center;
          gap: 0.75rem;
        }

        .search-icon {
          color: var(--text-muted);
        }

        .search-input {
          flex: 1;
          border: none;
          font-size: 0.875rem;
          outline: none;
          background: transparent;
        }

        .no-padding { padding: 0; overflow: hidden; }

        .employee-table { margin-top: 0; }

        .font-semibold { font-weight: 600; }
        .font-mono { font-family: ui-monospace, monospace; }
        .text-center { text-align: center; padding: 3rem; color: var(--text-muted); }

        .action-buttons {
          display: flex;
          gap: 0.5rem;
        }

        .action-btn {
          width: 32px;
          height: 32px;
          border-radius: 6px;
          display: flex;
          align-items: center;
          justify-content: center;
          transition: all 0.2s;
          color: var(--text-muted);
        }

        .action-btn:hover {
          background: #f1f5f9;
        }

        .action-btn.edit:hover { color: var(--primary); }
        .action-btn.delete:hover { color: var(--accent); }

        .pagination {
          display: flex;
          align-items: center;
          justify-content: space-between;
          padding: 1rem 1.5rem;
          background: #f8fafc;
          border-top: 1px solid var(--border);
        }

        .pagination-info {
          font-size: 0.875rem;
          color: var(--text-muted);
        }

        .pagination-controls {
          display: flex;
          gap: 0.5rem;
        }
      `}</style>
    </div>
  );
};

export default Employees;
