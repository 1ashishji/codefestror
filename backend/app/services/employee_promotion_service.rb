class EmployeePromotionService < ApplicationService
  def initialize(department_id, promotion_percentage)
    @department_id = department_id
    @promotion_percentage = promotion_percentage
  end

  def call
    factor = 1.0 + (@promotion_percentage.to_f / 100.0)
    
    Employee.where(department_id: @department_id).find_in_batches(batch_size: 1000) do |group|
      ActiveRecord::Base.transaction do
        group.each do |employee|
          employee.update!(salary: employee.salary * factor)
        end
      end
    end
    
    # Invalidate global insights cache
    REDIS_POOL.with { |r| r.del(Employee.global_cache_key) }
    true
  end
end
