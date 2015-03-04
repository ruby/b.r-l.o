Rails.application.routes.draw do
  resources :mail_to_issue, only: [:new, :create]
end
