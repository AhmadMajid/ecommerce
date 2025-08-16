module ApplicationHelper
  def current_user_review_for(product)
    return nil unless user_signed_in?
    @current_user_reviews ||= {}
    @current_user_reviews[product.id] ||= current_user.reviews.find_by(product: product)
  end

  # Generate hierarchical category options for select dropdown
  def hierarchical_category_options(categories = nil, level = 0)
    categories ||= Category.active.roots.includes(:children).ordered
    options = []

    categories.each do |category|
      # Create indentation using Unicode box-drawing characters for a tree-like appearance
      prefix = level == 0 ? '' : ('│   ' * (level - 1)) + '├── '

      options << [prefix + category.name, category.id]

      # Recursively add children
      if category.children.any?
        child_categories = category.children.active.ordered
        options += hierarchical_category_options(child_categories, level + 1)
      end
    end

    options
  end

  # Alternative version using simple spaces for indentation (more compatible)
  def simple_hierarchical_category_options(categories = nil, level = 0)
    categories ||= Category.active.roots.includes(:children).ordered
    options = []

    categories.each do |category|
      # Create indentation using spaces and dashes
      prefix = '  ' * level
      prefix += '└─ ' if level > 0

      options << [prefix + category.name, category.id]

      # Recursively add children
      if category.children.any?
        child_categories = category.children.active.ordered
        options += simple_hierarchical_category_options(child_categories, level + 1)
      end
    end

    options
  end

  def country_name(country_code)
    case country_code
    when 'US' then 'United States'
    when 'CA' then 'Canada'
    when 'GB' then 'United Kingdom'
    when 'AU' then 'Australia'
    when 'DE' then 'Germany'
    when 'FR' then 'France'
    when 'JP' then 'Japan'
    when 'BR' then 'Brazil'
    when 'MX' then 'Mexico'
    when 'IN' then 'India'
    else country_code
    end
  end

  def country_options
    [
      ['United States', 'US'],
      ['Canada', 'CA'],
      ['United Kingdom', 'GB'],
      ['Australia', 'AU'],
      ['Germany', 'DE'],
      ['France', 'FR'],
      ['Japan', 'JP'],
      ['Brazil', 'BR'],
      ['Mexico', 'MX'],
      ['India', 'IN']
    ]
  end
end
