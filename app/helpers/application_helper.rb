module ApplicationHelper

	def info titulo, subtitulo

		haml_tag :h5, titulo
		haml_tag :h6, subtitulo, {class: 'card-subtitle mb-2 text-muted'}

	end

	def card_to_info tipo_inscripcion, dias, fecha_inscripcion='Por definir', fecha_planilla='Por definir', arancel='Por definir' 

		capture_haml do
			haml_tag :div, {class: 'card'} do
				haml_tag :div, {class: 'card-header'} do
					haml_tag :span, tipo_inscripcion
					haml_tag :span, dias, {class: 'badge badge-info'}
				end
				haml_tag :div, {class: 'card-body'} do
					haml_tag :ul do
						haml_tag :li do
							info 'Fecha y Hora de Inscripción:', fecha_inscripcion 
						end
						haml_tag :li do
							info 'Fecha y Hora de Entrega de Planilla:', fecha_planilla
						end
						haml_tag :li do
							info 'Arancel por nivel:', fecha_planilla
						end
					end
				end
			end
		end
	end


end
