class UpsertBatchWorker
  include Sidekiq::Worker
  sidekiq_options queue: :critical, retry: 1

  def perform(file_path)
    PayrollImportService.call(file_path)
  end
end
