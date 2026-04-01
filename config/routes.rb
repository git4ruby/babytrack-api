Rails.application.routes.draw do
  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Devise JWT auth routes
  devise_for :users,
    path: "",
    path_names: {
      sign_in: "api/v1/auth/sign_in",
      sign_out: "api/v1/auth/sign_out",
      registration: "api/v1/auth/sign_up"
    },
    controllers: {
      sessions: "api/v1/sessions",
      registrations: "api/v1/registrations"
    }

  namespace :api do
    namespace :v1 do
      # Inbound SMS webhook
      post "sms/incoming", to: "sms#incoming"

      # User profile
      resource :profile, only: [:show, :update], controller: "profile" do
        patch :change_password, on: :member
      end

      # CSV Exports
      get "exports/feedings", to: "exports#feedings"
      get "exports/diapers", to: "exports#diapers"
      get "exports/weight", to: "exports#weight"
      get "exports/milestones", to: "exports#milestones"
      get "exports/all", to: "exports#all"

      # Feedings
      resources :feedings, only: [:index, :show, :create, :update, :destroy] do
        collection do
          get :summary
          get :analytics
          get :last
        end
      end

      # Weight Logs
      resources :weight_logs, only: [:index, :show, :create, :update, :destroy] do
        collection do
          get :percentiles
        end
      end

      # Vaccinations
      resources :vaccinations, only: [:index, :show, :update] do
        member do
          post :administer
        end
        collection do
          get :upcoming
        end
      end

      # Appointments
      resources :appointments, only: [:index, :show, :create, :update, :destroy] do
        collection do
          get :next_upcoming
        end
      end

      # Milk Storage Inventory
      resources :milk_stashes, only: [:index, :show, :create, :update] do
        member do
          post :consume
          post :discard
          post :transfer
        end
        collection do
          get :inventory
          get :history
        end
      end

      # Diaper Changes
      resources :diaper_changes, only: [:index, :show, :create, :update, :destroy] do
        collection do
          get :summary
          get :stats
        end
      end

      # Milestones
      resources :milestones, only: [:index, :show, :create, :update, :destroy]

      # Baby info
      resource :baby, only: [:show, :update]   # current baby
      resources :babies, only: [:index, :create, :update, :destroy] # list + CRUD
    end
  end
end
