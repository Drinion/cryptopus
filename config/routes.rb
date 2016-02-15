# encoding: utf-8

#  Copyright (c) 2008-2016, Puzzle ITC GmbH. This file is part of
#  Cryptopus and licensed under the Affero General Public License version 3 or later.
#  See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/cryptopus.

Cryptopus::Application.routes.draw do
  scope "(:locale)", locale: /en|de|fr/ do
    resources :recryptrequests
    resources :teams do
      resources :teammembers
      resources :groups do
        resources :accounts do
          resources :items
        end
      end
    end

    namespace :admin do
      resource :settings do
        post 'update_all'
        get 'index'
      end
      resources :users do
        member do
          get 'unlock'
          post 'update_admin'
        end
      end
      resources :recryptrequests do
        collection do
          post 'resetpassword'
        end
      end
    end

    resource :login do
      get 'login'
      get 'show_update_password'
      post 'update_password'
      get 'logout'
      get 'noaccess'
      post 'authenticate'
      post 'changelocale'
    end

    get 'wizard', to: 'wizard#index'
    post 'wizard/apply'

    get 'search', to: 'search#index'
    get 'search/account', to: 'search#account'

    root to: 'search#index'
  end

  scope '/api', module: 'api' do
    resources :teams, except: [:new, :edit]  do
      resources :members, expect: [:new, :edit], module: 'team' do
        collection do
          get :candidates
        end
      end
    end
  end
end
