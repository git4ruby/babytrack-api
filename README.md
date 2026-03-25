# BabyTrack API

Rails 8 API-only backend for tracking baby Ojas's feedings, weight, vaccinations, appointments, and milk storage inventory.

## Tech Stack

- Ruby 3.3 / Rails 8.0 (API-only)
- PostgreSQL 16
- Redis 7 (Sidekiq)
- Devise + JWT authentication
- RSpec + FactoryBot

## Setup

```bash
# Start infrastructure
docker compose up -d

# Install dependencies
bundle install

# Database
rails db:create db:migrate db:seed

# Run tests
bundle exec rspec

# Start server
rails s
```

Default login: `mohit@babytrack.local` / `password123`

## API Endpoints

### Auth
| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/v1/auth/sign_in` | Login (returns JWT in Authorization header) |
| DELETE | `/api/v1/auth/sign_out` | Logout (revokes JWT) |
| POST | `/api/v1/auth/sign_up` | Register |

### Feedings
| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/v1/feedings` | List (filters: `date`, `feed_type`, `from`/`to`) |
| POST | `/api/v1/feedings` | Create (bottle/breastfeed/pump) |
| PATCH | `/api/v1/feedings/:id` | Update |
| DELETE | `/api/v1/feedings/:id` | Soft-delete |
| GET | `/api/v1/feedings/summary?date=` | Daily summary (totals, breast balance, gaps) |
| GET | `/api/v1/feedings/last` | Most recent feeding |

### Milk Storage Inventory
| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/v1/milk_stashes` | List stashes (filters: `storage_type`, `status`) |
| POST | `/api/v1/milk_stashes` | Store milk (room_temp/fridge/freezer, auto-expiration) |
| GET | `/api/v1/milk_stashes/:id` | Stash detail with activity logs |
| PATCH | `/api/v1/milk_stashes/:id` | Update label/notes |
| POST | `/api/v1/milk_stashes/:id/consume` | Use milk (full or partial, optional feeding link) |
| POST | `/api/v1/milk_stashes/:id/discard` | Discard milk (full or partial, with reason) |
| POST | `/api/v1/milk_stashes/:id/transfer` | Move between storage (e.g. freezer to fridge) |
| GET | `/api/v1/milk_stashes/inventory` | Full inventory breakdown by storage type |
| GET | `/api/v1/milk_stashes/history` | Activity log (filter: `log_action`) |

**Expiration rules (CDC guidelines):**
- Room temperature: 4 hours
- Fridge: 4 days (96 hours)
- Freezer: 6 months (4320 hours)

### Weight Logs
| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/v1/weight_logs` | List |
| POST | `/api/v1/weight_logs` | Create |
| PATCH | `/api/v1/weight_logs/:id` | Update |
| DELETE | `/api/v1/weight_logs/:id` | Delete |
| GET | `/api/v1/weight_logs/percentiles` | Growth data with age |

### Vaccinations
| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/v1/vaccinations` | List (filter: `status`) |
| PATCH | `/api/v1/vaccinations/:id` | Update |
| POST | `/api/v1/vaccinations/:id/administer` | Mark as given |
| GET | `/api/v1/vaccinations/upcoming` | Due within 30 days |

### Appointments
| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/v1/appointments` | List (filter: `status`) |
| POST | `/api/v1/appointments` | Create |
| PATCH | `/api/v1/appointments/:id` | Update |
| DELETE | `/api/v1/appointments/:id` | Cancel |
| GET | `/api/v1/appointments/next_upcoming` | Next appointment |

### Baby
| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/v1/baby` | Baby info with age |
| PATCH | `/api/v1/baby` | Update baby info |

## Database Schema

8 tables: `users`, `babies`, `feedings`, `weight_logs`, `vaccinations`, `appointments`, `milk_stashes`, `milk_stash_logs`

## Tests

132 specs covering models, services, and request endpoints.

```bash
bundle exec rspec                    # all tests
bundle exec rspec spec/models/       # model specs only
bundle exec rspec spec/requests/     # API request specs
bundle exec rspec spec/services/     # service specs
```
