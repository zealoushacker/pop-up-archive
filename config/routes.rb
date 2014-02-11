PopUpArchive::Application.routes.draw do

  use_doorkeeper do
    controllers :applications => 'oauth/applications'
  end

  get '/*path' => redirect {|params, request| "https://www.popuparchive.org/#{params[:path]}" }, constraints: { host: 'pop-up-archive.herokuapp.com' }
  get '/*path' => redirect {|params, request| "https://www.popuparchive.org/#{params[:path]}" }, constraints: { host: 'beta.popuparchive.org' }
  get '/*path' => redirect {|params, request| "https://www.popuparchive.org/#{params[:path]}" }, constraints: { host: 'www.popuparchive.org', protocol: "http://" }
  root to: redirect('https://www.popuparchive.org/'), constraints: { host: 'www.popuparchive.org', protocol: 'http://' }
  root to: redirect('https://www.popuparchive.org/'), constraints: { host: 'beta.popuparchive.org' }
  root to: redirect('https://www.popuparchive.org/'), constraints: { host: 'pop-up-archive.herokuapp.com' }

  devise_for :users, controllers: { registrations: 'users/registrations', invitations: 'users/invitations', omniauth_callbacks: 'users/omniauth_callbacks', sessions: 'users/sessions' }

  namespace :admin do
    resources :task_list
    resources :soundcloud_callback
    resources :accounts
  end

  get 'media/:token/:expires/:use/:class/:id/:name.:extension', controller: 'media', action: 'show'
  
  get 'embed_player/:name/:file_id/:item_id/:collection_id', to: 'embed_player', action: 'show'

  post 'fixer_callback/:audio_file_id', controller: 'callbacks', action: 'fixer', as: 'fixer_callback'

  post 'amara_callback', controller: 'callbacks', action: 'amara', as: 'amara_callback'

  namespace :api, defaults: { format: 'json' }, path: 'api' do
    scope module: :v1, constraints: ApiVersionConstraint.new(version: 1, default: true) do
      root to: 'status#info'

      get '/me' => 'users#me'
      put '/me/credit_card' => 'credit_cards#update'
      put '/me/subscription' => 'subscriptions#update'
      get '/users/me' => 'users#me'
      put '/users/me/credit_card' => 'credit_cards#update'
      put '/users/me/subscription' => 'subscriptions#update'

      post '/credit_card' => 'credit_cards#save_token'

      resource :last_items
      resource :search
      resources :items do
        resources :audio_files do
          post '',                     action: 'update'
          get  'transcript_text',      action: 'transcript_text'
          get  'upload_to',            action: 'upload_to'
          post 'order_transcript',     action: 'order_transcript'
          post 'add_to_amara',         action: 'add_to_amara'
          post 'listens',              action: 'listens'

          # s3 upload actions
          get  'chunk_loaded',         action: 'chunk_loaded'
          get  'get_init_signature',   action: 'init_signature'
          get  'get_chunk_signature',  action: 'chunk_signature'
          get  'get_end_signature',    action: 'end_signature'
          get  'get_list_signature',   action: 'list_signature'
          get  'get_delete_signature', action: 'delete_signature'
          get  'get_all_signatures',   action: 'all_signatures'
          get  'upload_finished',      action: 'upload_finished'

          resource :transcript
        end
        resources :entities
        resources :contributions
      end

      resources :timed_texts

      resources :organizations

      resources :plans

      resources :collections do
        collection do
          resources :public_collections, path: 'public', only: [:index]
        end
        resources :items
        resources :people
      end
      resources :csv_imports
    end
  end

  # used only for dev and test
  mount JasmineRails::Engine => "/jasmine" if defined?(JasmineRails)

  if Rails.env.development? || Rails.env.staging?
    require 'sidekiq/web'
    mount Sidekiq::Web => '/sidekiq'
  end

  match '*path', to: 'directory/dashboard#user', constraints: HtmlRequestConstraint.new()
  root to: 'directory/dashboard#guest', constraints: GuestConstraint.new(true)
  root to: 'directory/dashboard#user', constraints: GuestConstraint.new(false)
end
