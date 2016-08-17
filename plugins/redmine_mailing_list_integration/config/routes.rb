Rails.application.routes.draw do
  resources :mailing_lists do
    resources :uses, controller: 'uses_of_mailing_list'
  end
end
