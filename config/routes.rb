Rails.application.routes.draw do
  devise_for :users
  root to: "pages#home"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
  resources :memos do
    member do
      patch :toggle_visibility
      patch :toggle_favorite
    end

    collection do
      get :publics
    end

    resources :memo_shares, only: [:create, :destroy]
    resources :cards, only: [:new, :create, :destroy, :edit, :update]
    resources :chats, only: [:new, :create, :show]
  end

  resources :chats, only: [] do
    resources :messages, only: [:create]
  end

  get "play", to: "plays#start", as: :play_start
  get "play/:id", to: "plays#show", as: :play
  get "play/reveal/:id", to: "plays#reveal", as: :reveal_play
  patch "play/:id/knew", to: "plays#knew", as: :knew_play
  patch "play/:id/did_not_know", to: "plays#did_not_know", as: :did_not_know_play

  resources :answers, only: [:update]
end
