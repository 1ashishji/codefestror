class InsightGenerationService < ApplicationService
  def initialize(country)
    @country = country
  end

  def call
    stats = Employee.where(country: @country)
                    .select('AVG(salary) as avg, MIN(salary) as min, MAX(salary) as max, COUNT(*) as count')[0]
    
    top_title = Employee.where(country: @country)
                        .group(:job_title)
                        .order('COUNT(*) DESC')
                        .limit(1)
                        .pluck(:job_title)
                        .first

    {
      country: @country,
      metrics: {
        avg: stats.avg.to_f.round(2),
        min: stats.min.to_f.round(2),
        max: stats.max.to_f.round(2),
        count: stats.count.to_i,
        top_job_title: top_title || 'N/A'
      }
    }
  end
end
