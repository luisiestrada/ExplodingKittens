Rails.application.routes.draw do

  get 'chat/message'
  post 'chat/message' => 'chat#message'
  post 'games/play_turn' => 'games#play_turn'

  devise_for :users
  get 'welcome' => 'welcome#index'
  get 'card_list' => 'welcome#card_list'
  get 'instructions' => 'welcome#instructions'
  get 'about_us' => 'welcome#about_us'
  get 'test' => 'welcome#test'
  get 'gamewindow' => 'welcome#gamewindow'

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products
  resources :games do
    get 'join'
    post 'start'
    get 'leave'
    get 'draw'
    post 'send_chat'
  end

  resources :users
  resources :chat

end
