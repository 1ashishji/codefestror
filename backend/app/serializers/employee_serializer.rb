class EmployeeSerializer < ActiveModel::Serializer
  attributes :id, :full_name, :job_title, :country, :salary, :currency, :department_id, :created_at, :updated_at
  
  def salary
    object.salary.to_f
  end
end
