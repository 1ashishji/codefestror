import React, { useState, useEffect } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { Save, X, AlertCircle } from 'lucide-react';
import api from '../api';

const EmployeeForm = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const isEdit = Boolean(id);
  
  const [formData, setFormData] = useState({
    full_name: '',
    job_title: '',
    country: 'US',
    salary: '',
    currency: 'USD',
    department_id: '',
    lock_version: 0
  });

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  useEffect(() => {
    if (isEdit) {
      const fetchEmployee = async () => {
        setLoading(true);
        try {
          const response = await api.get(`/employees/${id}`);
          const data = response.data.data;
          setFormData({
            full_name: data.full_name,
            job_title: data.job_title,
            country: data.country,
            salary: data.salary,
            currency: data.currency,
            department_id: data.department_id || '',
            lock_version: data.lock_version
          });
        } catch (err) {
          setError('Failed to load employee data');
          console.error(err);
        } finally {
          setLoading(false);
        }
      };
      fetchEmployee();
    }
  }, [id, isEdit]);

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: name === 'salary' ? parseFloat(value) || '' : value
    }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    try {
      if (isEdit) {
        await api.put(`/employees/${id}`, { employee: formData });
      } else {
        await api.post('/employees', { employee: formData });
      }
      navigate('/employees');
    } catch (err) {
      const messages = err.response?.data?.errors;
      setError(Array.isArray(messages) ? messages.join(', ') : 'An error occurred while saving.');
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  if (loading && isEdit) return <div className="p-8 text-center">Loading...</div>;

  return (
    <div className="form-container">
      <div className="card max-w-2xl mx-auto">
        <div className="form-header">
          <h2>{isEdit ? 'Edit Employee' : 'Add New Employee'}</h2>
          <button className="btn-icon" onClick={() => navigate('/employees')}>
            <X size={20} />
          </button>
        </div>

        {error && (
          <div className="error-alert">
            <AlertCircle size={18} />
            <span>{error}</span>
          </div>
        )}

        <form onSubmit={handleSubmit} className="employee-form">
          <div className="form-group">
            <label>Full Name</label>
            <input 
              type="text" 
              name="full_name"
              className="input" 
              value={formData.full_name}
              onChange={handleChange}
              required
              placeholder="e.g. John Doe"
            />
          </div>

          <div className="form-row">
            <div className="form-group">
              <label>Job Title</label>
              <input 
                type="text" 
                name="job_title"
                className="input" 
                value={formData.job_title}
                onChange={handleChange}
                required
                placeholder="e.g. Software Engineer"
              />
            </div>
            <div className="form-group">
              <label>Country (ISO)</label>
              <input 
                type="text" 
                name="country"
                className="input" 
                value={formData.country}
                onChange={handleChange}
                required
                maxLength={2}
                placeholder="US"
              />
            </div>
          </div>

          <div className="form-row">
            <div className="form-group">
              <label>Salary</label>
              <input 
                type="number" 
                name="salary"
                className="input" 
                value={formData.salary}
                onChange={handleChange}
                required
                min="0"
                step="0.01"
              />
            </div>
            <div className="form-group">
              <label>Currency</label>
              <select 
                name="currency" 
                className="input"
                value={formData.currency}
                onChange={handleChange}
              >
                <option value="USD">USD</option>
                <option value="EUR">EUR</option>
                <option value="GBP">GBP</option>
                <option value="INR">INR</option>
                <option value="JPY">JPY</option>
              </select>
            </div>
          </div>

          <div className="form-actions">
            <button 
              type="button" 
              className="btn btn-outline" 
              onClick={() => navigate('/employees')}
              disabled={loading}
            >
              Cancel
            </button>
            <button 
              type="submit" 
              className="btn btn-primary gap-2"
              disabled={loading}
            >
              <Save size={18} />
              {loading ? 'Saving...' : 'Save Employee'}
            </button>
          </div>
        </form>
      </div>

      <style jsx>{`
        .max-w-2xl { max-width: 42rem; }
        .mx-auto { margin-left: auto; margin-right: auto; }
        
        .form-header {
          display: flex;
          justify-content: space-between;
          align-items: center;
          margin-bottom: 2rem;
          padding-bottom: 1rem;
          border-bottom: 1px solid var(--border);
        }

        .btn-icon {
          color: var(--text-muted);
          padding: 0.5rem;
          border-radius: 50%;
          transition: background 0.2s;
        }

        .btn-icon:hover { background: #f1f5f9; }

        .error-alert {
          background: #fef2f2;
          color: #991b1b;
          padding: 1rem;
          border-radius: 0.5rem;
          display: flex;
          align-items: center;
          gap: 0.75rem;
          margin-bottom: 1.5rem;
          font-size: 0.875rem;
          border: 1px solid #fecaca;
        }

        .employee-form {
          display: flex;
          flex-direction: column;
          gap: 1.5rem;
        }

        .form-group label {
          display: block;
          font-size: 0.875rem;
          font-weight: 500;
          color: var(--text-main);
          margin-bottom: 0.5rem;
        }

        .form-row {
          display: grid;
          grid-template-columns: 1fr 1fr;
          gap: 1.5rem;
        }

        .form-actions {
          display: flex;
          justify-content: flex-end;
          gap: 1rem;
          margin-top: 1rem;
          padding-top: 1.5rem;
          border-top: 1px solid var(--border);
        }
      `}</style>
    </div>
  );
};

export default EmployeeForm;
