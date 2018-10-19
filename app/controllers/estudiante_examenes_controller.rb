# encoding: utf-8

class EstudianteExamenesController < ApplicationController

	before_action :filtro_logueado
	before_action :filtro_administrador, :except => ['presentar', 'indicaciones', 'resultado', 'guardar_respuesta', 'completar']
	skip_before_action  :verify_authenticity_token  

	layout :resolver_layout

	HOST = "/aceim/assets/examenes/"

	def indicaciones
		# @estudiante_examen = EstudianteExamen.first
		# La linea anterior debe ser sustituida con esta:
		begin
			@usuario = session[:usuario]
			@examen_id = params[:id]
			id = "#{@usuario.ci},#{@examen_id}"
			@estudiante_examen = EstudianteExamen.find id
		rescue Exception => e
			redirect_to :action => 'index'
		end
	end

	def presentar
	usuario = session[:usuario]

	@examen = Examen.where(:id => params[:id]).limit(1).first

	if not @examen 

	  flash[:mensaje] = 'Examen no encontrado'
	  redirect_to :controller => 'principal'
	else
	  @estudiante_examen = @examen.estudiante_examenes.where(:estudiante_ci => usuario.ci).limit(1).first
	  @estudiante_examen.tipo_estado_estudiante_examen_id = 'PREPARADO' if @examen.prueba
	  if @estudiante_examen and @examen.se_puede_presentar? and @estudiante_examen.preparado? or @estudiante_examen.resagado?
	    @estudiante_examen.tipo_estado_estudiante_examen_id = 'INICIADO'
	    @estudiante_examen.tiempo = @examen.duracion if @estudiante_examen.tiempo.nil? or (@estudiante_examen.tiempo.eql? 0) or (@examen.prueba)
	    @estudiante_examen.save
		@estudiante_examen.generar_eers2	    
	    # session[:tiempo] = @examen.duracion
	    @titulo = @examen.descripcion_simple
	    if @examen.prueba
	      @estudiante_examen.estudiante_examen_respuestas.delete_all
	    end
	    # session[:estudiante_examen] = @estudiante_examen
		session[:estudiante_examen_id] = @estudiante_examen.id
		@estudiante_examen.estado_parte_id = @examen.parte_examenes.first.parte_id
	    # @estudiante_examen.save!

		@parte_examenes = @examen.parte_examenes.joins(:parte).order('parte.orden ASC')
		@host = "#{request.protocol}#{request.host_with_port}"+HOST
		info_bitacora "Estudiante #{@estudiante_examen.estudiante_ci} Inició Examen #{@estudiante_examen.examen.curso_periodo.descripcion}."

	  else
	    flash[:mensaje] = 'Examen no disponible'
	    redirect_to :controller => 'principal'
	  end
	end
	end

	def guardar_respuesta
		eer = params[:eer]
		estudiante_ci = eer[:estudiante_ci]
		examen_id = eer[:examen_id]
		@respuesta_id = eer[:respuesta_id]
		@eer = EstudianteExamenRespuesta.find_or_initialize_by_estudiante_ci_and_examen_id_and_respuesta_id(estudiante_ci,examen_id,@respuesta_id)
		# valor = eer[:valor].split(" ")
		eer[:valor] = limpiar_string eer[:valor]
		@eer.update_attributes eer
		@ee = @eer.estudiante_examen
		@ee.tiempo = params[:tiempo].to_i + 1
		@eer.estudiante_examen.save

		total_respuestas = @ee.examen.total_preguntas
		contestadas = @ee.eers.count
		@eers_restantes_count = total_respuestas - contestadas


		@ee.transferir_nota_escrita_a_historial unless @ee.examen.prueba

		# @eer.estudiante_examen.transferir_nota_escrita2_a_historial if not @eer.estudiante_examen.examen.prueba

		info_bitacora "Respuesta guardada: #{@eer.descripcion}"

		respond_to do |format|
		  format.html {redirect_to :back}
		  format.js
		end
	end

	def completar
		@ee = EstudianteExamen.find session[:estudiante_examen_id].to_s
		@ee.tipo_estado_estudiante_examen_id = 'COMPLETADO' #unless @estudiante_examen.examen.prueba
		@ee.tiempo = params[:tiempo]

		# PENDIENTE POR GUARDAR EN EXAMEN TEORICO 2 LA NOTA @estudiante_examen.total_puntos_correctos_base_20

		flash[:mensaje] = ""

		if @ee.save
		  session[:estudiante_examen_id] = nil
		  info_bitacora "Estudiante #{@ee.estudiante_ci} Completó Examen #{@ee.examen.curso_periodo.descripcion}."
		  flash[:mensaje] = 'Examen Completado con Éxito.'
		  puts 'Examen Completado con Éxito.'
		end

		@ee.transferir_nota_escrita_a_historial unless @ee.examen.prueba

		# unless @ee.examen.prueba
		#   if @ee.transferir_nota_escrita2_a_historial
		#     flash[:mensaje] += 'Calificación asignada.' 
		#   else
		#     flash[:mensaje] += 'Su calificación no pudo ser asignada. (Notifique al personal administrativo para tomar las correcciones respectivas).'
		#   end
		# end

		redirect_to :action => :resultado, :id => @ee.id.to_s

	end

	def resultado
		# Variables Globales
		@estudiante_examen = EstudianteExamen.find params[:id].to_s

		@usuario = session[:usuario]

		rol = session[:rol]

		@examen = @estudiante_examen.examen
		@titulo = "Resultado del #{@examen.descripcion_simple}"

		@total_actividades = @examen.total_actividades
		@total_preguntas = @examen.total_preguntas
		@total_puntos = @examen.puntaje_total

		@total_puntos_correctos = @estudiante_examen.total_puntos_correctos
		@total_respuestas_correctas = @estudiante_examen.total_respuestas_correctas
		@total_respuestas_incorrectas = @total_preguntas - @total_respuestas_correctas

	end


	def index
		@examen = Examen.find params[:id]
		@estudiante_examenes = @examen.estudiante_examenes
		@total_iniciados = @estudiante_examenes.where(tipo_estado_estudiante_examen_id: 'INICIADO').count
		@total_completados = @estudiante_examenes.where(tipo_estado_estudiante_examen_id: 'COMPLETADO').count
		@total_preparados = @estudiante_examenes.where(tipo_estado_estudiante_examen_id: 'PREPARADO').count
		@titulo = @examen.descripcion_simple
		#@secciones = Seccion.where(:perido_id => @examen.perido_id, :idioma_id => @examen.curso_idioma_id, :tipo_categoria_id => @examen.curso_tipo_categoria_id, :tipo_nivel_id => @examen.curso_tipo_nivel_id)
	end

	def show
		@estudiante_examen = EstudianteExamen.find params[:id].to_s
		@examen = @estudiante_examen.examen
		@host = "#{request.protocol}#{request.host_with_port}"+HOST
		@parte_examenes = @examen.parte_examenes.joins(:parte).order('parte.orden ASC')
	    @titulo = @examen.descripcion_simple

	end

	def new
		
	end

	def create
		@estudiante_examen = EstudianteExamen.new 
		@estudiante_examen.id = params[:id]
		@estudiante_examen.tipo_estado_estudiante_examen_id = 'PREPARADO'
		begin @estudiante_examen.save
			info_bitacora("Agredado Examen #{@estudiante_examen.examen_id} al Estudiante: #{@estudiante_examen.estudiante_ci}")
			flash[:mensaje] = "Agregado Examen al Estudiante"

		rescue Exception => e
			flash[:mensaje] = "No se pudo agregar el Examen al Estudiante. Por favor verifique e intentelo nuevamente. Error Generado por el sistema:#{e}"	
		end 
		redirect_to  :back

	end

	def resolver_layout
		case action_name
		when 'presentar', 'indicaciones', 'resultado'
		  'presentar_examen'
		else
		  'application'
		end
	end


end