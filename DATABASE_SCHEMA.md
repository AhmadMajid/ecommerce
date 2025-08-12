# Database Schema Summary for Ecommerce Rails Application

## Overview
This document outlines the complete database schema for a production-ready ecommerce Rails application with comprehensive indexing for optimal performance.

## Database Tables and Key Features

### 1. Users Table
- **Purpose**: Customer and admin authentication/profile management
- **Key Features**: Devise authentication, role-based access, user profiles
- **Important Indexes**:
  - `email` (unique) - for login authentication
  - `role`, `active` - for admin queries
  - `[active, role]` - composite for filtering active users by role

### 2. Addresses Table
- **Purpose**: Customer billing and shipping addresses
- **Key Features**: Multiple addresses per user, default address support
- **Important Indexes**:
  - `user_id` - for user's addresses lookup
  - `[user_id, address_type]` - for billing/shipping address queries
  - `[user_id, default_address]` - for default address lookup

### 3. Categories Table
- **Purpose**: Product categorization with hierarchical support
- **Key Features**: Nested categories, SEO-friendly slugs, featured categories
- **Important Indexes**:
  - `slug` (unique) - for SEO-friendly URLs
  - `parent_id` - for nested category queries
  - `[active, featured]` - for homepage category display
  - `[active, sort_order]` - for category listing

### 4. Products Table
- **Purpose**: Core product information and inventory
- **Key Features**: Rich product data, inventory tracking, SEO optimization
- **Important Indexes**:
  - `slug` (unique) - for SEO-friendly product URLs
  - `sku` (unique) - for inventory management
  - `category_id` - for category-based product queries
  - `[active, featured]` - for featured product display
  - `[category_id, active]` - for category product listings
  - `price` - for price-based filtering
  - `tags` (GIN) - for tag-based search

### 5. Product Variants Table
- **Purpose**: Product variations (size, color, etc.)
- **Key Features**: Option-based variants, individual pricing/inventory
- **Important Indexes**:
  - `product_id` - for product's variants lookup
  - `sku` (unique) - for variant identification
  - `[product_id, active]` - for active variant queries
  - `[option1_name, option1_value]` - for option-based filtering

### 6. Carts Table
- **Purpose**: Shopping cart management for users and guests
- **Key Features**: Guest cart support, cart abandonment tracking
- **Important Indexes**:
  - `user_id` - for user cart lookup
  - `session_id` - for guest cart lookup
  - `status` - for cart status queries
  - `expires_at` - for cart cleanup processes

### 7. Cart Items Table
- **Purpose**: Items within shopping carts
- **Key Features**: Product/variant linking, quantity management
- **Important Indexes**:
  - `cart_id` - for cart's items lookup
  - `[cart_id, product_id, product_variant_id]` (unique) - prevents duplicates
  - `product_id`, `product_variant_id` - for product-based queries

### 8. Orders Table
- **Purpose**: Customer order management and fulfillment
- **Key Features**: Complete order lifecycle, address storage, financial tracking
- **Important Indexes**:
  - `order_number` (unique) - for order lookup
  - `user_id` - for customer order history
  - `status`, `payment_status`, `fulfillment_status` - for order management
  - `[user_id, status]` - for customer order filtering
  - `tracking_number` - for shipment tracking
  - `created_at` - for order timeline queries

### 9. Order Items Table
- **Purpose**: Individual items within orders
- **Key Features**: Product snapshot at purchase time, fulfillment tracking
- **Important Indexes**:
  - `order_id` - for order's items lookup
  - `product_id`, `product_variant_id` - for product-based reporting
  - `fulfillment_status` - for fulfillment management
  - `product_sku`, `variant_sku` - for inventory reconciliation

### 10. Payments Table
- **Purpose**: Payment processing and transaction management
- **Key Features**: Multi-gateway support, fraud detection, refund handling
- **Important Indexes**:
  - `payment_id` (unique) - for payment processor integration
  - `order_id` - for order payment lookup
  - `status` - for payment status queries
  - `gateway` - for payment processor reporting
  - `amount` - for financial reporting
  - `created_at` - for payment timeline analysis

## Performance Optimization Strategies

### Index Design Principles
1. **Composite Indexes**: Used for multi-column WHERE clauses and sorting
2. **Unique Indexes**: Enforce data integrity while providing fast lookups
3. **Partial Indexes**: Consider for frequently filtered subsets (e.g., active records)
4. **JSON Indexes**: GIN indexes for JSON and array columns

### Query Optimization
1. **Foreign Key Indexes**: All foreign keys are indexed for JOIN performance
2. **Status Indexes**: All status enums are indexed for filtering
3. **Date Indexes**: Timestamp columns for reporting and cleanup processes
4. **Text Search**: pg_search integration with trigram indexes

### Monitoring and Maintenance
1. **Index Usage**: Monitor with `pg_stat_user_indexes`
2. **Query Performance**: Use `EXPLAIN ANALYZE` for slow queries
3. **Index Maintenance**: Regular `REINDEX` for heavily updated tables
4. **Statistics**: Keep table statistics current with `ANALYZE`

## Scaling Considerations

### Read Replicas
- Product catalog queries can use read replicas
- Reporting queries should use dedicated read replicas
- Cart operations require write access

### Partitioning Opportunities
- **Orders**: Partition by date for archival
- **Payments**: Partition by date for compliance
- **Cart Items**: Consider partitioning abandoned carts

### Caching Strategy
- Product catalog: Cache category trees and featured products
- Inventory: Cache low-stock alerts
- Cart totals: Cache calculated totals with invalidation
- Order status: Cache order summaries for customer accounts

## Security Considerations

### Data Protection
- Credit card data: PCI compliance requirements
- Customer PII: Encryption at rest and in transit
- Password security: Proper hashing with Devise

### Access Control
- Role-based permissions with Pundit
- API rate limiting for external integrations
- Audit logging for sensitive operations

## Backup and Recovery
- Point-in-time recovery for transaction data
- Regular backups with encryption
- Disaster recovery procedures
- Data retention policies for compliance

This schema provides a solid foundation for a production ecommerce application that can handle significant traffic and transaction volumes while maintaining data integrity and performance.
