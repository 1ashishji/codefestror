module Api
  module V1
    class EmployeesController < ApplicationController
      before_action :set_employee, only: %i[show update destroy versions]

      # Keyset pagination implementation
      def index
        permitted = index_params
        limit = permitted.fetch(:limit, 50).to_i.clamp(1, 100)
        cursor = permitted.fetch(:cursor, 0).to_i
        
        @employees = Employee.page_after(cursor, limit)
        
        render json: {
          data: @employees,
          meta: {
            next_cursor: @employees.last&.id,
            has_more: @employees.size == limit
          }
        }
      end

      def show
        render json: { data: @employee }
      end

      def create
        @employee = Employee.new(create_employee_params)
        @employee.current_ip = request.remote_ip
        
        if @employee.save
          render json: { data: @employee }, status: :created
        else
          render json: { errors: @employee.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        @employee.current_ip = request.remote_ip

        if @employee.update(update_employee_params)
          render json: { data: @employee }
        else
          render json: { errors: @employee.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        @employee.destroy
        head :no_content
      end

      # FULLTEXT search
      def search
        query = search_params[:q]
        if query.blank?
          render json: { data: [] }
          return
        end

        @employees = Employee.fulltext_search(query).limit(50)
        render json: { data: @employees }
      end

      # Trigger batch job
      def bulk_promote
        permitted = bulk_promote_params
        department_id = permitted[:department_id]
        promotion_percentage = permitted[:promotion_percentage]

        BulkPromoteWorker.perform_async(department_id, promotion_percentage)

        render json: { message: "Bulk promotion queued for department #{department_id}" }, status: :accepted
      end

      # Large payroll import
      def upsert_batch
        file_path = upsert_batch_params[:file_path]
        UpsertBatchWorker.perform_async(file_path)

        render json: { message: "Batch upsert queued" }, status: :accepted
      end

      def versions
        render json: { data: @employee.versions }
      end

      private

      def set_employee
        @employee = Employee.find(params[:id])
      end

      def index_params
        params.permit(:limit, :cursor)
      end

      def search_params
        params.permit(:q)
      end

      def bulk_promote_params
        params.permit(:department_id, :promotion_percentage)
              .tap do |permitted|
                permitted.require(:department_id)
                permitted.require(:promotion_percentage)
              end
      end

      def upsert_batch_params
        params.permit(:file_path).tap { |permitted| permitted.require(:file_path) }
      end

      def create_employee_params
        params.require(:employee).permit(:full_name, :job_title, :country, :salary, :currency, :department_id)
      end

      def update_employee_params
        params.require(:employee).permit(:full_name, :job_title, :country, :salary, :currency, :department_id, :lock_version)
      end
    end
  end
end
