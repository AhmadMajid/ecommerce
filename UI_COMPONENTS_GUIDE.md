# EcommerceStore UI Components Documentation

This document provides comprehensive documentation for all the reusable UI components available in the EcommerceStore application.

## Layout Components

### Application Layout

The main application layout (`app/views/layouts/application.html.erb`) includes:

- **Header with Navigation**: Logo, main navigation, search bar, user authentication, and shopping cart
- **Flash Messages**: Success and error message display with dismissible functionality
- **Footer**: Company info, links, social media icons, newsletter signup, and payment methods
- **Mobile Responsive**: Hamburger menu for mobile devices
- **JavaScript Features**: Mobile menu toggle and auto-hiding flash messages

#### Key Features:

1. **Dynamic Cart Badge**: Shows item count from user's cart
2. **User Avatar**: Shows user initials in colored circle
3. **Dropdown Menu**: User menu with profile, orders, and admin options
4. **Social Media Icons**: Twitter, Facebook, Pinterest, Instagram
5. **Payment Method Icons**: Visa, Mastercard, PayPal, Apple Pay
6. **Newsletter Signup**: Email subscription form in footer

## Reusable Components

### 1. Button Component

**Location**: `app/views/shared/_button.html.erb`

```erb
<!-- Primary Button -->
<%= render 'shared/button',
    text: 'Submit',
    type: 'primary',
    classes: 'w-full' %>

<!-- Secondary Button -->
<%= render 'shared/button',
    text: 'Cancel',
    type: 'secondary' %>

<!-- Button as Link -->
<%= render 'shared/button',
    text: 'View Details',
    type: 'outline-primary',
    link: product_path(@product) %>

<!-- Button with Size -->
<%= render 'shared/button',
    text: 'Small Button',
    type: 'success',
    size: 'sm' %>
```

**Parameters**:
- `text` (required): Button text
- `type`: 'primary', 'secondary', 'success', 'danger', 'outline-primary'
- `size`: 'sm', 'lg', or nil for default
- `classes`: Additional CSS classes
- `link`: URL if this should be a link
- `method`: HTTP method for links (:delete, :patch, etc.)
- `onclick`: JavaScript onclick handler
- `disabled`: Boolean to disable button

### 2. Form Input Component

**Location**: `app/views/shared/_form_input.html.erb`

```erb
<!-- Basic Input -->
<%= render 'shared/form_input',
    name: 'email',
    label: 'Email Address',
    type: 'email',
    required: true %>

<!-- Input with Help Text -->
<%= render 'shared/form_input',
    name: 'password',
    label: 'Password',
    type: 'password',
    help: 'Password must be at least 8 characters' %>

<!-- Input with Error -->
<%= render 'shared/form_input',
    name: 'username',
    label: 'Username',
    value: @user.username,
    error: @user.errors[:username].first %>
```

**Parameters**:
- `name` (required): Input name attribute
- `label`: Input label
- `type`: Input type (default: 'text')
- `value`: Input value
- `placeholder`: Input placeholder
- `required`: Boolean - whether field is required
- `error`: Error message to display
- `help`: Help text to display
- `classes`: Additional CSS classes
- `autofocus`: Boolean - whether to autofocus
- `autocomplete`: Autocomplete attribute value

### 3. Form Select Component

**Location**: `app/views/shared/_form_select.html.erb`

```erb
<!-- Basic Select -->
<%= render 'shared/form_select',
    name: 'category_id',
    label: 'Category',
    options: Category.all.map { |c| [c.name, c.id] },
    prompt: 'Select a category' %>

<!-- Select with Selected Value -->
<%= render 'shared/form_select',
    name: 'status',
    label: 'Status',
    options: [['Active', 'active'], ['Inactive', 'inactive']],
    selected: @product.status %>
```

**Parameters**:
- `name` (required): Select name attribute
- `label`: Select label
- `options` (required): Array of [text, value] pairs
- `selected`: Selected value
- `required`: Boolean - whether field is required
- `error`: Error message to display
- `prompt`: Prompt text for first option
- `classes`: Additional CSS classes

### 4. Card Component

**Location**: `app/views/shared/_card.html.erb`

```erb
<!-- Basic Card -->
<%= render 'shared/card', header: 'User Profile' do %>
  <p>Card content goes here</p>
<% end %>

<!-- Card with Footer -->
<%= render 'shared/card',
    header: 'Product Details',
    footer: 'Last updated: Today',
    classes: 'mb-6' do %>
  <p>Product information here</p>
<% end %>
```

**Parameters**:
- `header`: Card header text (optional)
- `classes`: Additional CSS classes for the card
- `body_classes`: Additional CSS classes for the card body
- `footer`: Footer content (optional)

### 5. Badge Component

**Location**: `app/views/shared/_badge.html.erb`

```erb
<!-- Success Badge -->
<%= render 'shared/badge', text: 'Active', type: 'success' %>

<!-- Warning Badge -->
<%= render 'shared/badge', text: 'Pending', type: 'warning' %>

<!-- Custom Badge -->
<%= render 'shared/badge',
    text: 'New',
    type: 'primary',
    classes: 'ml-2' %>
```

**Parameters**:
- `text` (required): Badge text
- `type`: 'primary', 'success', 'warning', 'danger', 'gray' (default: 'gray')
- `classes`: Additional CSS classes

### 6. Loading Spinner Component

**Location**: `app/views/shared/_spinner.html.erb`

```erb
<!-- Basic Spinner -->
<%= render 'shared/spinner' %>

<!-- Large Spinner with Text -->
<%= render 'shared/spinner',
    size: 'lg',
    text: 'Loading...' %>

<!-- Small Spinner -->
<%= render 'shared/spinner', size: 'sm' %>
```

**Parameters**:
- `size`: 'sm', 'lg', or nil for default
- `classes`: Additional CSS classes
- `text`: Loading text to display next to spinner

### 7. Alert Component

**Location**: `app/views/shared/_alert.html.erb`

```erb
<!-- Success Alert -->
<%= render 'shared/alert',
    message: 'Profile updated successfully!',
    type: 'success',
    dismissible: true %>

<!-- Error Alert -->
<%= render 'shared/alert',
    message: 'Please fix the errors below',
    type: 'error' %>

<!-- Info Alert -->
<%= render 'shared/alert',
    message: 'Your order is being processed',
    type: 'info' %>
```

**Parameters**:
- `message` (required): Alert message
- `type`: 'success', 'error', 'warning', 'info' (default: 'info')
- `dismissible`: Boolean - whether alert can be dismissed
- `classes`: Additional CSS classes

## CSS Classes and Utilities

### Custom CSS Classes

The application includes a comprehensive set of CSS utility classes in `app/assets/stylesheets/components.css`:

#### Button Classes
- `.btn` - Base button class
- `.btn-primary` - Primary button styling
- `.btn-secondary` - Secondary button styling
- `.btn-success` - Success button styling
- `.btn-danger` - Danger button styling
- `.btn-lg` - Large button
- `.btn-sm` - Small button

#### Form Classes
- `.form-input` - Standard input styling
- `.form-input-error` - Error state input
- `.form-label` - Form label styling
- `.form-select` - Select dropdown styling
- `.form-checkbox` - Checkbox styling
- `.form-radio` - Radio button styling

#### Card Classes
- `.card` - Basic card styling
- `.card-header` - Card header styling
- `.card-body` - Card body styling
- `.card-footer` - Card footer styling

#### Badge Classes
- `.badge` - Base badge class
- `.badge-primary` - Primary badge
- `.badge-success` - Success badge
- `.badge-warning` - Warning badge
- `.badge-danger` - Danger badge

### Animation Classes
- `.fade-in` - Fade in animation
- `.slide-down` - Slide down animation
- `.cart-badge-bounce` - Cart badge bounce animation

### Responsive Utilities
- `.product-grid` - Responsive product grid
- `.text-responsive-*` - Responsive text sizes

## Form Examples

### Registration Form Example

```erb
<%= render 'shared/card', header: 'Create Account' do %>
  <%= form_with url: user_registration_path, class: 'space-y-4' do |f| %>

    <%= render 'shared/form_input',
        name: 'user[first_name]',
        label: 'First Name',
        required: true,
        autofocus: true %>

    <%= render 'shared/form_input',
        name: 'user[last_name]',
        label: 'Last Name',
        required: true %>

    <%= render 'shared/form_input',
        name: 'user[email]',
        label: 'Email Address',
        type: 'email',
        required: true,
        autocomplete: 'email' %>

    <%= render 'shared/form_input',
        name: 'user[password]',
        label: 'Password',
        type: 'password',
        required: true,
        help: 'Password must be at least 8 characters' %>

    <%= render 'shared/button',
        text: 'Create Account',
        type: 'primary',
        classes: 'w-full' %>

  <% end %>
<% end %>
```

### Product Form Example

```erb
<%= render 'shared/card', header: 'Add New Product' do %>
  <%= form_with model: @product, class: 'space-y-4' do |f| %>

    <%= render 'shared/form_input',
        name: 'product[name]',
        label: 'Product Name',
        value: @product.name,
        required: true,
        error: @product.errors[:name].first %>

    <%= render 'shared/form_select',
        name: 'product[category_id]',
        label: 'Category',
        options: @categories.map { |c| [c.name, c.id] },
        selected: @product.category_id,
        prompt: 'Select a category',
        required: true %>

    <div class="flex space-x-4">
      <%= render 'shared/button',
          text: 'Save Product',
          type: 'primary' %>

      <%= render 'shared/button',
          text: 'Cancel',
          type: 'secondary',
          link: products_path %>
    </div>

  <% end %>
<% end %>
```

## JavaScript Features

### Mobile Menu Toggle

```javascript
function toggleMobileMenu() {
  const mobileMenu = document.getElementById('mobile-menu');
  mobileMenu.classList.toggle('hidden');
}
```

### Auto-hide Flash Messages

Flash messages automatically hide after 5 seconds with a fade-out animation.

### Cart Badge Animation

When items are added to cart, the badge bounces to draw attention.

## Best Practices

### Component Usage
1. Always use the shared components for consistency
2. Pass appropriate parameters for accessibility (labels, required fields)
3. Include error handling in forms
4. Use semantic HTML elements

### Styling
1. Use Tailwind CSS utility classes for custom styling
2. Maintain consistent spacing with the design system
3. Ensure responsive design on all components
4. Test accessibility with screen readers

### Performance
1. Components are rendered server-side for better performance
2. CSS animations are hardware-accelerated
3. JavaScript is minimal and optimized

This component system provides a solid foundation for building consistent, accessible, and beautiful user interfaces throughout the EcommerceStore application.
