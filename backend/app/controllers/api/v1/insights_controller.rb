module Api
  module V1
    class InsightsController < ApplicationController
      
      def salary_by_country
        country = country_param
        cache_key = Employee.country_cache_key(country)

        data = REDIS_POOL.with do |redis|
          cached = redis.get(cache_key)
          if cached
            JSON.parse(cached)
          else
            stats = generate_country_stats(country)
            redis.setex(cache_key, 12.hours.to_i, stats.to_json)
            stats
          end
        end

        render json: { data: data }
      end

      def salary_by_title
        permitted = salary_by_title_params
        title = permitted[:job_title]
        employees = Employee.where(job_title: title)
        employees = employees.where(country: permitted[:country].upcase) if permitted[:country].present?

        stats = employees.select('AVG(salary) as avg, MIN(salary) as min, MAX(salary) as max, COUNT(*) as count')[0]

        render json: {
          data: {
            job_title: title,
            country: permitted[:country]&.upcase,
            avg: stats.avg.to_f.round(2),
            min: stats.min.to_f.round(2),
            max: stats.max.to_f.round(2),
            count: stats.count.to_i
          }
        }
      end

      def salary_by_all_titles_in_country
        country = country_param

        stats = Employee.where(country: country)
                        .group(:job_title)
                        .select('job_title, AVG(salary) as avg, MIN(salary) as min, MAX(salary) as max, COUNT(*) as count')
                        .order(Arel.sql('AVG(salary) DESC'))

        render json: {
          data: stats.map { |row|
            {
              job_title: row.job_title,
              avg: row.avg.to_f.round(2),
              min: row.min.to_f.round(2),
              max: row.max.to_f.round(2),
              count: row.count.to_i
            }
          }
        }
      end

      def health_alerts
        avg = Employee.average(:salary) || 0
        
        anomalies_low = Employee.where('salary < ?', avg * 0.3).limit(50)
        anomalies_high = Employee.where('salary > ?', avg * 3.0).limit(50)

        render json: {
          data: {
            low_anomalies: anomalies_low,
            high_anomalies: anomalies_high
          }
        }
      end

      def global_summary
        cache_key = Employee.global_cache_key

        data = REDIS_POOL.with do |redis|
          cached = redis.get(cache_key)
          if cached
            JSON.parse(cached)
          else
            stats = {
              total_employees: Employee.count,
              average_salary: Employee.average(:salary).to_f.round(2),
              total_payroll: Employee.sum(:salary).to_f.round(2)
            }
            redis.setex(cache_key, 6.hours.to_i, stats.to_json)
            stats
          end
        end

        render json: { data: data }
      end

      private

      def country_param
        params.permit(:country).require(:country).upcase
      end

      def salary_by_title_params
        params.permit(:job_title, :country).tap { |permitted| permitted.require(:job_title) }
      end

      def generate_country_stats(country)
        InsightGenerationService.call(country)
      end
    end
  end
end
