# encoding: utf-8

class DescargaController < ApplicationController
	before_action :filtro_logueado


	def archivo
		archivo = Archivo.find params[:id]
		send_file archivo.url, :x_sendfile => true, :disposition => "attachment"
	end

	def fechas
		send_file "#{Rails.root}/attachments/FECHAS.pdf", :type => "application/pdf", :x_sendfile => true, :disposition => "attachment"
	end

	def syllabus
		ha = HistorialAcademico.where(:idioma_id => params[:idioma_id], :usuario_ci => session[:usuario].ci, :tipo_nivel_id => params[:nivel], :periodo_id => ParametroGeneral.periodo_actual.id).first
		if ha or session[:administrador]

			archivo = "#{params[:idioma_id]}/#{params[:nivel]}.pdf"

			if archivo
				send_file "#{Rails.root}/attachments/syllabus/#{archivo}", :type => "application/pdf", :x_sendfile => true, :disposition => "attachment"
			else
				flash[:mensaje] = "Nivel de curso sin Sílabo."	
				redirect_to :back
			end
		else
		    flash[:mensaje] = "En este momento el Sílabo para su curso actual no se encuentran disponibles."
		    redirect_to :back
    	end		
	end


	# def syllabus

	# 	if ha  = HistorialAcademico.where(:idioma_id => 'IN', :usuario_ci => session[:usuario].ci, :tipo_categoria_id => 'AD', :periodo_id => ParametroGeneral.periodo_actual.id).first
	# 		case ha.tipo_nivel_id
	# 		when "BI" 
	# 			archivo = "BI_American Cutting Edge.pdf"
	# 		when "BII" 
	# 			archivo = "BII_American Cutting Edge.pdf"
	# 		when "BIII" 
	# 			archivo = "BIII_American Cutting Edge.pdf"
	# 		when "CB" 
	# 			# casos especiales
	# 			if ha.seccion.bloque_horario.id.eql? 'H5'
	# 				archivo = "BASIC CONV_Sabados.pdf"
	# 			else
	# 				archivo = "BASIC CONV_WEEK DAYS.pdf"
	# 			end
	# 		when "MI" 
	# 			archivo = "INT I_American Cutting Edge.pdf"
	# 		when "MII" 
	# 			archivo = "INT II_American Cutting Edge.pdf"
	# 		when "MIII" 
	# 			archivo = "INT_III American Cutting Edge.pdf"
	# 		when "CI" 
	# 			# casos especiales
	# 			if ha.seccion.bloque_horario.id.eql? 'H5'
	# 				archivo = "INT CONV_Sabados.pdf"
	# 			else
	# 				archivo = "INT CONV_WEEK DAYS.pdf"
	# 			end
	# 		when "AI" 
	# 			archivo = "ADV I_ Summit.pdf"
	# 		when "AII" 
	# 			archivo = "ADV II_ Summit.pdf"
	# 		when "AIII" 
	# 			archivo = "ADV III_Summit.pdf"
	# 		when "CA" 
	# 			archivo = "ADV CONV.pdf"
	# 		end

	# 		if archivo
	# 			send_file "#{Rails.root}/attachments/syllabus/#{archivo}", :type => "application/pdf", :x_sendfile => true, :disposition => "attachment"
	# 		else
	# 			flash[:mensaje] = "Nivel de curso sin Syllabus."	
	# 			redirect_to :back
	# 		end
	# 	else
	# 	    flash[:mensaje] = "No hay Syllabus disponibles para ud."
	# 	    redirect_to :back
 #    	end
	# end
end