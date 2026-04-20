class BulkPromoteWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default, retry: 3

  def perform(department_id, promotion_percentage)
    EmployeePromotionService.call(department_id, promotion_percentage)
  end
end
