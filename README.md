# Enterprise Salary Management System Runbook

This guide explains how to run the app, start MySQL and Redis, run Rails migrations, create 10,000 fake employees with Faker, and verify everything is working.

## App URLs

- Frontend: http://localhost:5173
- Backend API: http://localhost:3000/api/v1
- Rails health check: http://localhost:3000/up
- Sidekiq UI: http://localhost:3000/sidekiq

## Services

The app runs with Docker Compose:

- `db`: MySQL 8.0 database.
- `redis`: Redis cache and Sidekiq backend.
- `web`: Rails API on port `3000`.
- `worker`: Sidekiq background worker.
- `frontend`: Vite React app on port `5173`.

## Required Files

Make sure these files exist:

- `.env`
- `docker-compose.yml`
- `backend/Gemfile`
- `backend/Gemfile.lock`
- `backend/Rakefile`
- `backend/bin/rails`
- `backend/config.ru`
- `backend/db/seeds.rb`
- `frontend/.dockerignore`

## Environment

The project uses `.env` from the repo root.

Important values:

```env
COMPOSE_PROJECT_NAME=salary_dev
DB_ROOT_PASSWORD=password
DB_USERNAME=root
DB_PASSWORD=password
DATABASE_URL=mysql2://root:password@db:3306/hr
REDIS_URL=redis://redis:6379/0
RAILS_ENV=development
VITE_API_BASE_URL=http://localhost:3000/api/v1
```

`COMPOSE_PROJECT_NAME=salary_dev` avoids old `docker-compose` v1 container-name collisions such as `KeyError: 'ContainerConfig'`.

## Start The App

From the project root:

```bash
cd /home/ashish/test
./run-project.sh
```

If Docker requires sudo, the script will ask for your sudo password.

Alternative manual command:

```bash
cd /home/ashish/test
sudo docker-compose up --build
```

To run in the background:

```bash
cd /home/ashish/test
sudo docker-compose up -d --build
```

## Stop The App

```bash
cd /home/ashish/test
sudo docker-compose down
```

This stops containers but keeps MySQL and Redis volumes.

## Reset All Local Docker Data

Use this only when you are okay deleting the local dev MySQL and Redis data:

```bash
cd /home/ashish/test
sudo docker-compose down -v --remove-orphans
```

Then rebuild:

```bash
sudo docker-compose up -d --build
```

## Check Container Status

```bash
sudo docker ps --format '{{.Names}} {{.Status}} {{.Ports}}'
```

Expected containers:

```text
salary_dev_frontend_1
salary_dev_web_1
salary_dev_worker_1
salary_dev_redis_1
salary_dev_db_1
```

Expected ports:

```text
5173 -> frontend
3000 -> Rails API
6379 -> Redis
3306 -> MySQL
```

## Run Rails Migrations

Run this after the containers are up:

```bash
cd /home/ashish/test
sudo docker exec salary_dev_web_1 bundle exec rails db:migrate
```

This creates:

- `employees`
- `versions`

## Create 10,000 Faker Employees

The seed file is:

```text
backend/db/seeds.rb
```

It uses:

- `faker`
- `Employee::ALLOWED_JOB_TITLES`
- `Employee::ALLOWED_COUNTRIES`
- `Employee::ALLOWED_CURRENCIES`
- `Employee.insert_all!` for fast bulk loading

To reset employees and create exactly 10,000 records:

```bash
cd /home/ashish/test
sudo docker exec salary_dev_web_1 env RESET_EMPLOYEES=1 EMPLOYEE_SEED_COUNT=10000 bundle exec rails db:seed
```

To add another batch without deleting existing employees:

```bash
sudo docker exec salary_dev_web_1 env EMPLOYEE_SEED_COUNT=10000 bundle exec rails db:seed
```

To create a different amount:

```bash
sudo docker exec salary_dev_web_1 env RESET_EMPLOYEES=1 EMPLOYEE_SEED_COUNT=50000 bundle exec rails db:seed
```

## Verify Employee Data

Check count:

```bash
sudo docker exec salary_dev_web_1 bundle exec rails runner 'puts Employee.count'
```

Expected for the default seed:

```text
10000
```

Check API:

```bash
sudo docker exec salary_dev_web_1 curl -s 'http://127.0.0.1:3000/api/v1/employees?limit=3'
```

Or from browser:

```text
http://localhost:3000/api/v1/employees?limit=3
```

## Verify Salary Insights

Country salary stats:

```bash
sudo docker exec salary_dev_web_1 curl -s 'http://127.0.0.1:3000/api/v1/insights/salary_by_country?country=US'
```

Job title salary stats in a country:

```bash
sudo docker exec salary_dev_web_1 curl -s 'http://127.0.0.1:3000/api/v1/insights/salary_by_title?country=US&job_title=Engineer'
```

All job title salary stats in a country:

```bash
sudo docker exec salary_dev_web_1 curl -s 'http://127.0.0.1:3000/api/v1/insights/salary_by_all_titles_in_country?country=US'
```

Global summary:

```bash
sudo docker exec salary_dev_web_1 curl -s 'http://127.0.0.1:3000/api/v1/insights/global_summary'
```

## Verify Redis

Redis is used for salary insight caching and Sidekiq.

Check Redis health:

```bash
sudo docker exec salary_dev_redis_1 redis-cli ping
```

Expected:

```text
PONG
```

See cached salary insight keys:

```bash
sudo docker exec salary_dev_redis_1 redis-cli keys '*salary_insights*'
```

Clear cached insight keys:

```bash
sudo docker exec salary_dev_redis_1 redis-cli keys '*salary_insights*' | xargs -r -I {} sudo docker exec salary_dev_redis_1 redis-cli del {}
```

Simpler full Redis flush for local dev:

```bash
sudo docker exec salary_dev_redis_1 redis-cli flushdb
```

## Verify MySQL

Open MySQL shell:

```bash
sudo docker exec -it salary_dev_db_1 mysql -uroot -ppassword hr
```

Check employee count:

```sql
SELECT COUNT(*) FROM employees;
```

Exit:

```sql
exit
```

## Verify Frontend

Frontend is Vite:

```text
http://localhost:5173
```

Useful screens:

- Dashboard
- Employees
- Salary Insights

If the frontend does not update after code changes:

```bash
sudo docker restart salary_dev_frontend_1
```

## Verify Backend

Rails health:

```bash
sudo docker exec salary_dev_web_1 curl -I 'http://127.0.0.1:3000/up'
```

Employees endpoint:

```bash
sudo docker exec salary_dev_web_1 curl -I 'http://127.0.0.1:3000/api/v1/employees?limit=10'
```

## Add Or Edit Employees

Use the frontend:

```text
http://localhost:5173
```

Go to:

```text
Employees -> New Employee
Employees -> Edit button
```

Valid values are enforced by Rails:

- Country must be one of the model ISO country codes.
- Currency must be one of `USD INR SGD GBP EUR JPY AUD CAD`.
- Job title must be one of the allowed job titles in `Employee::ALLOWED_JOB_TITLES`.
- Salary must be greater than `0` and less than or equal to `10,000,000`.

## Common Problems

### Docker permission denied

If Docker says permission denied:

```bash
sudo docker ps
```

If that works, use `sudo docker-compose ...` commands.

To avoid sudo later:

```bash
sudo usermod -aG docker "$USER"
```

Then close and reopen the terminal/WSL session.

### Legacy Compose `KeyError: 'ContainerConfig'`

This project is using legacy `docker-compose` v1. If you see:

```text
KeyError: 'ContainerConfig'
```

Remove stale containers without deleting volumes:

```bash
cd /home/ashish/test
sudo docker rm -f salary_dev_web_1 salary_dev_worker_1 salary_dev_frontend_1 salary_dev_db_1 salary_dev_redis_1
sudo docker-compose up -d --build
```

If old `test_*` containers exist:

```bash
sudo docker rm -f test_web_1 test_worker_1 test_frontend_1 test_db_1 test_redis_1
```

Best long-term fix: install Docker Compose v2 and use `docker compose` instead of `docker-compose`.

### MySQL unhealthy

Check logs:

```bash
sudo docker logs salary_dev_db_1 --tail 100
```

If the volume was initialized with wrong credentials and this is only local dev:

```bash
cd /home/ashish/test
sudo docker-compose down -v --remove-orphans
sudo docker-compose up -d --build
sudo docker exec salary_dev_web_1 bundle exec rails db:migrate
sudo docker exec salary_dev_web_1 env RESET_EMPLOYEES=1 EMPLOYEE_SEED_COUNT=10000 bundle exec rails db:seed
```

### Rails says employees table does not exist

Run migrations:

```bash
sudo docker exec salary_dev_web_1 bundle exec rails db:migrate
```

### Salary Insights says no data

Make sure employees are seeded:

```bash
sudo docker exec salary_dev_web_1 bundle exec rails runner 'puts Employee.count'
```

If count is `0`, seed:

```bash
sudo docker exec salary_dev_web_1 env RESET_EMPLOYEES=1 EMPLOYEE_SEED_COUNT=10000 bundle exec rails db:seed
```

Clear Redis cache if old insight data is stuck:

```bash
sudo docker exec salary_dev_redis_1 redis-cli flushdb
```

### Add or edit employee returns 500

Check Rails logs:

```bash
tail -n 120 backend/log/development.log
```

This was previously caused by PaperTrail metadata using `updated_by_ip` while the `versions` table had `current_ip`. The model should contain:

```ruby
attr_accessor :current_ip
has_paper_trail meta: { current_ip: :current_ip }
```

Restart Rails after model changes:

```bash
sudo docker restart salary_dev_web_1
```

## Daily Development Flow

Start:

```bash
cd /home/ashish/test
sudo docker-compose up -d --build
```

Migrate:

```bash
sudo docker exec salary_dev_web_1 bundle exec rails db:migrate
```

Seed 10k employees:

```bash
sudo docker exec salary_dev_web_1 env RESET_EMPLOYEES=1 EMPLOYEE_SEED_COUNT=10000 bundle exec rails db:seed
```

Open:

```text
http://localhost:5173
```

Stop:

```bash
sudo docker-compose down
```

---

## Test-Driven Development (TDD) Approach

This project follows a strict **Test-Driven Development** methodology:

### Test Stack
- **RSpec** — BDD testing framework for Ruby
- **FactoryBot** — Test data generation
- **Shoulda Matchers** — One-liner validation tests
- **DatabaseCleaner** — Test isolation between examples

### Test Coverage (25+ test cases)

| Layer | File | Test Cases |
|-------|------|------------|
| Model Validations | `employee_spec.rb` | 20 tests covering full_name, job_title, salary, country, currency |
| Model Callbacks | `employee_spec.rb` | 5 tests for name/string normalization |
| Model Scopes | `employee_scope_spec.rb` | 6 tests for filtering and pagination |
| Services | `insight_generation_service_spec.rb` | 5 tests for metrics calculation |
| Services | `employee_promotion_service_spec.rb` | 3 tests for salary promotion logic |
| API Requests | `employees_spec.rb` | 7 tests for CRUD endpoints |
| API Requests | `employees_search_spec.rb` | 3 tests for search and error handling |
| API Requests | `insights_spec.rb` | 5 tests for analytics endpoints |

### TDD Workflow
Each feature was developed using the Red-Green-Refactor cycle:
1. **Red** — Write a failing test that defines expected behavior
2. **Green** — Write minimal code to make the test pass
3. **Refactor** — Clean up code while keeping tests green

### Running Tests
```bash
docker-compose exec web bundle exec rspec
docker-compose exec web bundle exec rspec --format documentation
```
