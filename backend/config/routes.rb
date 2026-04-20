# ─────────────────────────────────────────────────────────────────────────────
# Routes — Enterprise Salary Management System API v1
# ─────────────────────────────────────────────────────────────────────────────
require "sidekiq/web"

Rails.application.routes.draw do
  # ── Sidekiq Web UI (protect in production with auth) ─────────────────────
  mount Sidekiq::Web => "/sidekiq"

  # ── Health Check ──────────────────────────────────────────────────────────
  get "/up", to: proc { [200, {}, [{ status: "ok", timestamp: Time.current }.to_json]] }

  namespace :api do
    namespace :v1 do
      # ── Employees ──────────────────────────────────────────────────────────
      resources :employees, only: %i[index show create update destroy] do
        collection do
          get  :search         # FULLTEXT search
          post :bulk_promote   # Bulk promote action
          post :upsert_batch   # Payroll import via upsert_all
        end
        member do
          get  :versions       # PaperTrail audit log for a single employee
        end
      end

      # ── Salary Insights ────────────────────────────────────────────────────
      resources :insights, only: [] do
        collection do
          get :salary_by_country    # AVG/MIN/MAX/Median/P25/P75/Gini per country
          get :salary_by_title      # Same metrics per job title
          get :salary_by_all_titles_in_country
          get :health_alerts        # Employees below avg, above P75
          get :global_summary       # Company-wide snapshot
        end
      end
    end
  end
end
