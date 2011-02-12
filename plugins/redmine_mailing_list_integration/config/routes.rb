ActionController::Routing::Routes.draw do |map|
  map.resources :mailing_lists do |ml| 
    ml.resources :uses, :controller => 'uses_of_mailing_list'
  end
end

