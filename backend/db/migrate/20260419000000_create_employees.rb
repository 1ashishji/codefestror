class CreateEmployees < ActiveRecord::Migration[7.2]
  def change
    create_table :employees do |t|
      t.string :full_name, null: false
      t.string :job_title, null: false
      t.string :country, null: false, limit: 2
      t.decimal :salary, precision: 12, scale: 2, null: false
      t.string :currency, null: false, limit: 3
      t.integer :department_id
      t.integer :lock_version, default: 0, null: false
      
      t.timestamps
    end

    add_index :employees, :country
    add_index :employees, :job_title
    add_index :employees, :department_id
    add_index :employees, [:salary, :country]
    
    # Needs a raw execute for FULLTEXT in MySQL
    reversible do |dir|
      dir.up do
        execute "ALTER TABLE employees ADD FULLTEXT INDEX index_employees_on_full_name (full_name)"
      end
      dir.down do
        execute "ALTER TABLE employees DROP INDEX index_employees_on_full_name"
      end
    end
  end
end
