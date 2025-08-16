# Vercel + Supabase Deployment Guide

## Overview
This guide will help you deploy your Rails ecommerce application to Vercel with a Supabase PostgreSQL database.

## Prerequisites
- [Vercel account](https://vercel.com)
- [Supabase account](https://supabase.com)
- [Stripe account](https://stripe.com) (for payments)
- Vercel CLI: `npm install -g vercel`

## Step 1: Supabase Database Setup

### 1.1 Create Supabase Project
1. Go to [supabase.com](https://supabase.com)
2. Click "Start your project" 
3. Create new project:
   - **Project Name**: `ecommerce-app` (or your preferred name)
   - **Database Password**: Choose a strong password (save this!)
   - **Region**: Select closest to your users

### 1.2 Get Connection Details
After project creation, go to **Settings > Database**:
- **Host**: `db.[project-ref].supabase.co`
- **Database**: `postgres`
- **User**: `postgres`
- **Port**: `5432`
- **Password**: The password you set during creation

### 1.3 Get API Keys
Go to **Settings > API**:
- **Project URL**: `https://[project-ref].supabase.co`
- **Anon key**: (public key)
- **Service role key**: (private key - keep secret!)

## Step 2: Vercel Deployment

### 2.1 Initial Deployment
```bash
# Login to Vercel
vercel login

# Deploy (from your project root)
vercel --prod

# Follow the prompts:
# - Link to existing project? No
# - Project name: ecommerce-app
# - Directory: ./ 
```

### 2.2 Environment Variables
Go to Vercel Dashboard > Your Project > Settings > Environment Variables

Add these variables (replace placeholders with your actual values):

#### Database Variables
```
DATABASE_URL=postgresql://postgres:[YOUR_DB_PASSWORD]@db.[PROJECT_REF].supabase.co:5432/postgres
SUPABASE_DB_HOST=db.[PROJECT_REF].supabase.co
SUPABASE_DB_NAME=postgres
SUPABASE_DB_USER=postgres
SUPABASE_DB_PASSWORD=[YOUR_SUPABASE_DB_PASSWORD]
SUPABASE_DB_PORT=5432
```

#### Rails Configuration
```
RAILS_ENV=production
RACK_ENV=production
RAILS_LOG_TO_STDOUT=true
RAILS_SERVE_STATIC_FILES=true
SECRET_KEY_BASE=[GENERATE_THIS]
```

To generate SECRET_KEY_BASE:
```bash
rails secret
```

#### Stripe Configuration
```
STRIPE_PUBLISHABLE_KEY=[YOUR_STRIPE_PUBLISHABLE_KEY]
STRIPE_SECRET_KEY=[YOUR_STRIPE_SECRET_KEY]
STRIPE_WEBHOOK_SECRET=[YOUR_STRIPE_WEBHOOK_SECRET]
```

## Step 3: Database Migration

### 3.1 Set Environment Variables Locally
Create a `.env.production.local` file (don't commit this!):
```bash
DATABASE_URL=postgresql://postgres:[PASSWORD]@db.[PROJECT_REF].supabase.co:5432/postgres
RAILS_ENV=production
```

### 3.2 Run Migrations
```bash
# Install dependencies
bundle install

# Create and migrate database
RAILS_ENV=production rails db:create
RAILS_ENV=production rails db:migrate
RAILS_ENV=production rails db:seed
```

## Step 4: Stripe Webhook Configuration

### 4.1 Create Webhook Endpoint
1. Go to [Stripe Dashboard > Webhooks](https://dashboard.stripe.com/webhooks)
2. Click "Add endpoint"
3. **Endpoint URL**: `https://[your-vercel-domain].vercel.app/webhooks/stripe`
4. **Events to send**:
   - `payment_intent.succeeded`
   - `payment_intent.payment_failed`
   - `payment_intent.canceled`

### 4.2 Get Webhook Secret
1. Click on your created webhook
2. Copy the "Signing secret" 
3. Add it to Vercel environment variables as `STRIPE_WEBHOOK_SECRET`

## Step 5: Final Deployment

### 5.1 Redeploy with Environment Variables
```bash
vercel --prod
```

### 5.2 Test Your Application
Visit your Vercel URL and test:
- ✅ User registration/login
- ✅ Product browsing and search
- ✅ Cart functionality
- ✅ Checkout process
- ✅ Payment processing
- ✅ Admin panel access

## Troubleshooting

### Common Issues

#### 1. Database Connection Errors
- Verify DATABASE_URL is correct
- Check Supabase project is active
- Ensure database password is correct

#### 2. Asset Loading Issues
```bash
# Add to environment variables
RAILS_SERVE_STATIC_FILES=true
```

#### 3. Secret Key Base Errors
```bash
# Generate new secret
rails secret
# Add to VERCEL environment variables
```

#### 4. Stripe Webhook Errors
- Verify webhook URL is correct
- Check webhook secret matches
- Ensure endpoint is accessible

### Viewing Logs
- **Vercel Logs**: Dashboard > Project > Functions tab
- **Database Logs**: Supabase Dashboard > Logs
- **Stripe Logs**: Stripe Dashboard > Webhooks > Your endpoint

### Environment Variables Checklist
- [ ] `DATABASE_URL`
- [ ] `RAILS_ENV=production`
- [ ] `SECRET_KEY_BASE`
- [ ] `STRIPE_PUBLISHABLE_KEY`
- [ ] `STRIPE_SECRET_KEY`
- [ ] `STRIPE_WEBHOOK_SECRET`

## Production Checklist

### Pre-Launch
- [ ] Database migrated successfully
- [ ] All environment variables set
- [ ] Stripe webhooks configured
- [ ] SSL certificate active (automatic with Vercel)
- [ ] Admin user created
- [ ] Test transactions working

### Post-Launch Monitoring
- [ ] Set up error monitoring (e.g., Sentry)
- [ ] Monitor Vercel function usage
- [ ] Monitor Supabase database usage
- [ ] Set up backup strategy
- [ ] Configure domain (optional)

## Support

If you encounter issues:
1. Check Vercel deployment logs
2. Verify all environment variables
3. Test database connection
4. Check Stripe webhook configuration
5. Review this documentation

## Cost Considerations

### Vercel
- **Hobby Plan**: Free for personal projects
- **Pro Plan**: $20/month for commercial use

### Supabase  
- **Free Tier**: 500MB database, 50MB file storage
- **Pro Plan**: $25/month for 8GB database

### Stripe
- **No monthly fee**
- **2.9% + 30¢** per successful charge

---

*Last updated: August 2025*
