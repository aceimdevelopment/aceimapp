Rails.application.routes.draw do
	# For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
	# root 'welcome#index'

   	root 'inicio#index'

	# get "controller#action"

	# OJO: Actualizar para Rails 6
	# match ':controller(/:action(/:id(.:format)))', via: [:get, :post]

	get '/principal/index'
	post '/inicio/validar'
	get '/inicio/un_rol'
	get '/inicio/olvido_clave'
	get '/inicio/cerrar_sesion'
	
	get '/principal_admin/index'
	get '/principal_admin/capturar_ci'
	get '/principal_admin/redactar_correo'
	get '/principal_admin/estado_instructores'
	get '/principal_admin/generar_carnets'

	get '/reportes/index_reportes_convenios'
	get '/reportes/index_reporte_congelados'
	get '/reportes/alumnos_por_edificio'
	get '/reportes/nomina_instructores'
	get '/reportes/index_reporte_secciones_cerradas'

	get '/gestionar_cartelera/visualizar'
	get '/gestionar_cartelera/modificar'
	get '/gestionar_cartelera/validar'

	get '/cartelera/show'
	get '/cartelera/edit'
	post '/cartelera/save'


	resources :facturas #get '/gestionar_cartelera/modificar'
	# resources :cartelera

	get '/admin_estudiante/index'
	get '/admin_estudiante/estudiantes'
	get '/estudiante_nivelaciones/index'

	get '/archivos/index'

	get '/admin_instructor/index'
	get '/admin_instructor/nuevo'
	get '/admin_instructor/ingresar_horario_disponible_instructores'

	get '/estado_inscripcion/ver_secciones'

	get '/calificacion/seleccionar_curso'

	get '/inscripcion_admin/paso0'




	# resources :welcome do
	# 	collection do
	# 		post 'guardar_cartelera'
	# 		get 'cartelera'
	# 	end
	# end

	match ':controller/:action/:id', via: [:get, :post]
	# match ':controller[/*:action[/*:id]]', via: [:get, :post]
end
