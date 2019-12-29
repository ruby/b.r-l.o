Rails.application.routes.draw do
  resources :mailing_lists do
    resources :uses, controller: 'uses_of_mailing_list'
  end
  resources :mail_to_issue, only: [:new, :create]
end
