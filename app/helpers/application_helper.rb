module ApplicationHelper

	def info titulo, subtitulo

		haml_tag :h5, titulo
		haml_tag :h6, subtitulo, {class: 'card-subtitle mb-2 text-muted'}

	end

	def card_to_info tipo_inscripcion, dias, apertura=nil, cierre=nil, apertura_planilla=nil, cierre_planilla=nil, arancel='Por definir' 

		capture_haml do
			haml_tag :div, {class: 'card'} do
				haml_tag :div, {class: 'card-header'} do
					haml_tag :span, tipo_inscripcion
					haml_tag :span, dias, {class: 'badge badge-info'}
				end
				haml_tag :div, {class: 'card-body'} do
					haml_tag :ul do
						haml_tag :li do
							if apertura.nil?
								info 'Fecha y Hora de Inscripción:', 'Por definir'
							else
								info 'Fecha y Hora de Inscripción:', (formato_fecha_inscripcion apertura, cierre).to_s
							end
						end
						haml_tag :li do

							if apertura_planilla.nil?
								info 'Fecha y Hora de Entrega de Planilla:', 'Por definir'
							else
								info 'Fecha y Hora de Entrega de Planilla:', (formato_fecha_entrega_planilla apertura_planilla, cierre_planilla).to_s
							end
						end
						haml_tag :li do
							info 'Arancel por nivel:', arancel
						end
					end
				end
			end
		end
	end



	def formato_fecha_inscripcion apertura, cierre
		fecha_formato apertura, cierre
	end

	def formato_fecha_entrega_planilla apertura, cierre
		fecha_formato apertura, cierre
	end

	def fecha_formato (fecha_inicial, fecha_final)
		if fecha_inicial.blank? or fecha_final.blank?
			return "Por definir"
		else
			if fecha_inicial.to_date.eql? fecha_final.to_date		
				fecha = I18n.localize(fecha_inicial, :format => "El %A, %d de %B de %Y ")
				if (fecha_inicial.hour < 12) and (fecha_final.hour > 12)
					fecha += I18n.localize(fecha_inicial, :format => "desde las %I:%M %p hasta las 12:00 M y desde las 2:00 PM hasta las ")
					fecha += I18n.localize(fecha_final, :format => "%I:%M %p")
				else
					fecha += I18n.localize(fecha_inicial, :format => "desde las %I:%M %p hasta las ")
					fecha += I18n.localize(fecha_final, :format => "%I:%M %p")					
				end	
			else
				fecha = "Desde el #{fecha_apertura} hasta el #{fecha_cierre}"
			end			
			return fecha
		end
	end



end
