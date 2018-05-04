Rails.application.routes.draw do
	# For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
	root 'welcome#index'

	resources :welcome do
		collection do
			post 'guardar_cartelera'
			get 'cartelera'
		end
	end

end
