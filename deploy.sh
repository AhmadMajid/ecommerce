#!/bin/bash

# Vercel + Supabase Deployment Guide for Rails Ecommerce App

echo "🚀 Rails Ecommerce App - Vercel + Supabase Deployment Guide"
echo "=========================================================="

echo ""
echo "📋 Prerequisites:"
echo "1. Vercel CLI installed: npm i -g vercel"
echo "2. Supabase account created: https://supabase.com"
echo "3. Stripe account set up: https://stripe.com"

echo ""
echo "🗄️  Step 1: Set up Supabase Database"
echo "1. Go to https://supabase.com and create a new project"
echo "2. Note down your project details:"
echo "   - Project URL: https://[project-ref].supabase.co"
echo "   - Database Password (you set this during project creation)"
echo "   - API Keys (found in Settings > API)"

echo ""
echo "⚡ Step 2: Deploy to Vercel"
echo "1. Run: vercel login"
echo "2. Run: vercel --prod"
echo "3. Follow the prompts to link your project"

echo ""
echo "🔐 Step 3: Set Environment Variables in Vercel"
echo "Go to your Vercel dashboard > Project > Settings > Environment Variables"
echo "Add all variables from .env.production.template"

echo ""
echo "🗃️  Step 4: Set up Database"
echo "After deployment, run these commands locally:"
echo "RAILS_ENV=production rails db:create"
echo "RAILS_ENV=production rails db:migrate"
echo "RAILS_ENV=production rails db:seed"

echo ""
echo "💳 Step 5: Configure Stripe Webhooks"
echo "1. Go to Stripe Dashboard > Webhooks"
echo "2. Add endpoint: https://[your-vercel-domain].vercel.app/webhooks/stripe"
echo "3. Select events: payment_intent.succeeded, payment_intent.payment_failed"
echo "4. Copy the webhook secret to your Vercel environment variables"

echo ""
echo "✅ Step 6: Test Deployment"
echo "Visit your Vercel URL and test:"
echo "- User registration/login"
echo "- Product browsing"
echo "- Cart functionality"
echo "- Checkout process"
echo "- Admin panel (if applicable)"

echo ""
echo "🔧 Troubleshooting:"
echo "- Check Vercel deployment logs in the dashboard"
echo "- Verify all environment variables are set"
echo "- Check Supabase database connection"
echo "- Ensure Stripe webhooks are configured correctly"

echo ""
echo "📖 For detailed instructions, see the deployment documentation."
