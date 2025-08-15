Rails.application.routes.draw do
  # Devise routes for user authentication
  devise_for :users, controllers: {
    registrations: 'users/registrations',
    sessions: 'users/sessions',
    passwords: 'users/passwords',
    confirmations: 'users/confirmations',
    unlocks: 'users/unlocks'
  }

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Root route
  root "home#index"

  # Customer-facing routes
  resources :products, only: [:index, :show], param: :slug do
    collection do
      get :search
    end
    resources :reviews, only: [:new, :create, :edit, :update, :destroy]
  end

  resources :categories, only: [:index, :show], param: :slug

  # Cart functionality
  resource :cart, only: [:show, :update, :destroy] do
    post :merge
    get :mini
    patch :remove_coupon
  end

  resources :cart_items, only: [:create, :update, :destroy] do
    collection do
      delete :clear
    end
  end

  # Wishlist functionality
  resources :wishlists, only: [:index] do
    collection do
      post 'add/:product_id', to: 'wishlists#create', as: 'add_product'
      delete 'remove/:product_id', to: 'wishlists#destroy', as: 'remove_product'
    end
  end

  # Checkout routes
  resources :checkout, only: [:new, :destroy] do
    collection do
      get :shipping
      patch :update_shipping
      get :payment
      patch :update_payment
      get :review
      post :complete
      post :apply_coupon
      delete :remove_coupon
    end
  end

  # Public pages
  get "about", to: "pages#about"
  get "contact", to: "pages#contact"
  post "contact", to: "pages#create_contact"
  get "privacy-policy", to: "pages#privacy_policy"
  get "terms-of-service", to: "pages#terms_of_service"
  get "shipping-info", to: "pages#shipping_info"
  get "returns", to: "pages#returns"
  get "size-guide", to: "pages#size_guide"
  get "faq", to: "pages#faq"
  get "track-order", to: "pages#track_order"
  get "support-center", to: "pages#support_center"
  get "wholesale", to: "pages#wholesale"
  get "gift-cards", to: "pages#gift_cards"

  # Newsletter subscription
  resources :newsletters, only: [:create]
  
  # User profile routes
  resource :profile, only: [:show, :edit, :update], controller: 'users/profile' do
    member do
      patch :update_password
      patch :update_preferences
    end
  end

  # Address management
  resources :addresses do
    member do
      patch :set_default
    end
  end

  # Admin routes
  namespace :admin do
    root 'dashboard#index'

    resources :categories do
      member do
        patch :toggle_active
        patch :toggle_featured
      end

      collection do
        patch :bulk_update
        delete :bulk_destroy
      end
    end

    resources :products do
      member do
        patch :toggle_active
        patch :toggle_featured
        post :duplicate
        patch :update_inventory
      end

      collection do
        patch :bulk_update
        delete :bulk_destroy
        get :export
      end
    end

    resources :contact_messages, only: [:index, :show, :destroy] do
      member do
        patch :mark_as_pending
        patch :mark_as_read
        patch :mark_as_replied
        patch :archive
        post :send_reply
      end

      collection do
        post :bulk_action
      end
    end
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
