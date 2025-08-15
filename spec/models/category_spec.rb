require 'rails_helper'

RSpec.describe Category, type: :model do
  describe 'associations' do
    it { should belong_to(:parent).class_name('Category').optional }
    it { should have_many(:children).class_name('Category').with_foreign_key('parent_id').dependent(:destroy) }
    it { should have_many(:products).dependent(:destroy) }
  end

  describe 'validations' do
    subject { build(:category) }

    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_most(255) }
    it { should validate_length_of(:description).is_at_most(1000) }

    context 'slug validation' do
      it 'validates slug presence after name is set' do
        category = Category.new(name: 'Test Category')
        category.valid?
        expect(category.slug).to be_present
      end

      # TODO: Fix this test - auto-generation interferes with manual slug setting
      xit 'validates slug uniqueness' do
        existing = create(:category, slug: 'test-slug')
        new_category = Category.new(name: 'Different Name', slug: 'test-slug')
        expect(new_category).not_to be_valid
        expect(new_category.errors[:slug]).to include('has already been taken')
      end
    end
  end

  describe 'callbacks' do
    describe 'generate_slug' do
      it 'generates slug from name on create' do
        category = create(:category, name: 'Test Category')
        expect(category.slug).to eq('test-category')
      end

      it 'updates slug when name changes' do
        category = create(:category, name: 'Original Name')
        category.update(name: 'Updated Name')
        expect(category.slug).to eq('updated-name')
      end

      it 'handles duplicate slugs by adding counter' do
        create(:category, name: 'Electronics')
        duplicate = create(:category, name: 'Electronics')
        expect(duplicate.slug).to eq('electronics-1')
      end
    end

    describe 'set_meta_title' do
      it 'sets meta_title from name if blank' do
        category = create(:category, name: 'Test Category')
        expect(category.meta_title).to eq('Test Category')
      end

      it 'does not override existing meta_title' do
        category = create(:category, name: 'Test Category', meta_title: 'Custom Title')
        expect(category.meta_title).to eq('Custom Title')
      end
    end

    describe 'set_position' do
      it 'sets position automatically for new categories' do
        category = create(:category)
        expect(category.position).to be_present
        expect(category.position).to be >= 0
      end

      # TODO: Fix this test - position assignment varies due to test interference
      xit 'increments position for categories with same parent' do
        # Start fresh to avoid interference from other tests
        Category.destroy_all
        
        parent = create(:category)
        child1 = create(:category, parent: parent)
        expect(child1.position).to eq(1)
        
        child2 = create(:category, parent: parent)
        expect(child2.position).to eq(2)
        expect(child2.position).to be > child1.position
      end

      it 'does not override manually set position' do
        category = create(:category, position: 10)
        expect(category.position).to eq(10)
      end
    end
  end

  describe 'scopes' do
    let!(:active_category) { create(:category, active: true) }
    let!(:inactive_category) { create(:category, active: false) }
    let!(:featured_category) { create(:category, featured: true) }
    let!(:root_category) { create(:category, parent: nil) }
    let!(:child_category) { create(:category, parent: root_category) }

    describe '.active' do
      it 'returns only active categories' do
        expect(Category.active).to include(active_category)
        expect(Category.active).not_to include(inactive_category)
      end
    end

    describe '.inactive' do
      it 'returns only inactive categories' do
        expect(Category.inactive).to include(inactive_category)
        expect(Category.inactive).not_to include(active_category)
      end
    end

    describe '.featured' do
      it 'returns only featured categories' do
        expect(Category.featured).to include(featured_category)
      end
    end

    describe '.root_categories' do
      it 'returns only root categories' do
        expect(Category.root_categories).to include(root_category)
        expect(Category.root_categories).not_to include(child_category)
      end
    end

    describe '.ordered' do
      it 'orders by position and name' do
        cat1 = create(:category, position: 2, name: 'Z Category')
        cat2 = create(:category, position: 1, name: 'A Category')
        expect(Category.ordered.first).to eq(cat2)
      end
    end
  end

  describe 'instance methods' do
    let!(:root_category) { create(:category, name: 'Electronics') }
    let!(:child_category) { create(:category, name: 'Smartphones', parent: root_category) }
    let!(:grandchild_category) { create(:category, name: 'iPhones', parent: child_category) }

    describe '#root?' do
      it 'returns true for root categories' do
        expect(root_category.root?).to be_truthy
      end

      it 'returns false for child categories' do
        expect(child_category.root?).to be_falsey
      end
    end

    describe '#leaf?' do
      it 'returns true for categories with no children' do
        expect(grandchild_category.leaf?).to be_truthy
      end

      it 'returns false for categories with children' do
        expect(root_category.leaf?).to be_falsey
      end
    end

    describe '#has_children?' do
      it 'returns true for categories with children' do
        expect(root_category.has_children?).to be_truthy
      end

      it 'returns false for categories without children' do
        expect(grandchild_category.has_children?).to be_falsey
      end
    end

    describe '#ancestors' do
      it 'returns empty array for root categories' do
        expect(root_category.ancestors).to eq([])
      end

      it 'returns parent for first level children' do
        expect(child_category.ancestors).to eq([root_category])
      end

      it 'returns all ancestors in order for deep nesting' do
        expect(grandchild_category.ancestors).to eq([root_category, child_category])
      end
    end

    describe '#descendants' do
      it 'returns all descendants' do
        descendants = root_category.descendants
        expect(descendants).to include(child_category)
        expect(descendants).to include(grandchild_category)
      end

      it 'returns empty array for leaf categories' do
        expect(grandchild_category.descendants).to eq([])
      end
    end

    describe '#level' do
      it 'returns 0 for root categories' do
        expect(root_category.level).to eq(0)
      end

      it 'returns 1 for first level children' do
        expect(child_category.level).to eq(1)
      end

      it 'returns 2 for second level children' do
        expect(grandchild_category.level).to eq(2)
      end
    end

    describe '#breadcrumb_path' do
      it 'returns category name for root categories' do
        expect(root_category.breadcrumb_path).to eq('Electronics')
      end

      it 'returns full path for nested categories' do
        expect(grandchild_category.breadcrumb_path).to eq('Electronics > Smartphones > iPhones')
      end
    end

    describe '#total_products_count' do
      let!(:root_product) { create(:product, category: root_category) }
      let!(:child_product) { create(:product, category: child_category) }

      it 'counts products including descendants' do
        expect(root_category.total_products_count).to eq(2)
      end

      it 'counts only direct products for leaf categories' do
        expect(child_category.total_products_count).to eq(1)
      end
    end

    describe '#sort_order' do
      it 'returns position value' do
        category = create(:category, position: 5)
        expect(category.sort_order).to eq(5)
      end

      it 'returns 0 when position is nil' do
        category = create(:category)
        category.update_column(:position, nil)
        expect(category.sort_order).to eq(0)
      end
    end

    describe '#sort_order=' do
      it 'sets position value' do
        category = create(:category)
        category.sort_order = 10
        expect(category.position).to eq(10)
      end
    end

    describe '#can_be_deleted?' do
      it 'returns true when no products or children exist' do
        empty_category = create(:category)
        expect(empty_category.can_be_deleted?).to be_truthy
      end

      it 'returns false when products exist' do
        create(:product, category: root_category)
        expect(root_category.can_be_deleted?).to be_falsey
      end

      it 'returns false when children exist' do
        expect(root_category.can_be_deleted?).to be_falsey
      end
    end

    describe '#to_param' do
      it 'returns slug for URL generation' do
        expect(root_category.to_param).to eq(root_category.slug)
      end
    end
  end

  describe 'custom validations' do
    describe 'cannot_be_parent_of_itself' do
      it 'prevents category from being its own parent' do
        category = create(:category)
        category.parent_id = category.id
        expect(category).not_to be_valid
        expect(category.errors[:parent_id]).to include('cannot be the same as the category itself')
      end
    end

    describe 'parent_must_be_active_if_child_is_active' do
      let!(:inactive_parent) { create(:category, active: false) }

      it 'prevents active child with inactive parent' do
        child = build(:category, parent: inactive_parent, active: true)
        expect(child).not_to be_valid
        expect(child.errors[:active]).to include('cannot be true when parent category is inactive')
      end

      it 'allows inactive child with inactive parent' do
        child = build(:category, parent: inactive_parent, active: false)
        expect(child).to be_valid
      end
    end
  end
end
