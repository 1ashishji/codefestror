class InsightGenerationService < ApplicationService
  def initialize(country)
    @country = country
  end

  def call
    stats = Employee.where(country: @country)
                    .select('AVG(salary) as avg, MIN(salary) as min, MAX(salary) as max, COUNT(*) as count')[0]
    
    {
      country: @country,
      metrics: {
        avg: stats.avg.to_f.round(2),
        min: stats.min.to_f.round(2),
        max: stats.max.to_f.round(2),
        count: stats.count.to_i
      }
    }
  end
end
