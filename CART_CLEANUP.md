# Cart Cleanup Background Job

## Overview
Automated cart cleanup system to prevent database bloat from guest carts and abandoned carts.

## What it does
- **Deletes empty guest carts** older than 1 hour
- **Abandons guest carts with items** older than 7 days
- **Abandons expired carts** (based on expires_at field)

## Schedule
- Runs **every hour at minute 30**
- Configured in `config/recurring.yml`

## Files
- **Job**: `app/jobs/cart_cleanup_job.rb`
- **Schedule**: `config/recurring.yml`
- **Manual cleanup**: `cleanup_empty_carts.rb`
- **Test script**: `test_cart_cleanup_job.rb`

## Manual Execution

### Run immediately
```bash
bundle exec rails runner "CartCleanupJob.perform_now"
```

### Queue for background execution
```bash
bundle exec rails runner "CartCleanupJob.perform_later"
```

### Manual cleanup script
```bash
bundle exec rails runner cleanup_empty_carts.rb
```

## Monitoring
Check the logs for cart cleanup activity:
```bash
tail -f log/development.log | grep "Cart cleanup"
```

## Configuration
Edit `config/recurring.yml` to change the schedule:
```yaml
development:
  cart_cleanup:
    class: CartCleanupJob
    queue: background
    schedule: every hour at minute 30  # Change this line
```

## Job Queue Status
The app uses Solid Queue for background job processing. Jobs are queued to the `background` queue.
