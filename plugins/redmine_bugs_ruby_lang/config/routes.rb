Rails.application.routes.draw do

  get '/projects/ruby-trunk:path', to: redirect('/projects/ruby-master%{path}'), constraints: { path: %r{(|/.*)} }

  resources :mailing_lists do
    resources :uses, controller: 'uses_of_mailing_list'
  end
  resources :mail_to_issue, only: [:new, :create]

end
