# encoding: utf-8

class EstudianteController < ApplicationController
	
	layout "application"
	before_action :filtro_logueado
  
	
  def index
  	usuario = session[:usuario]
  	@estudiante = Estudiante.where(:usuario_ci => usuario[:ci]).limit(1).first
  
  end
  
  def paso1
  	@usuario = session[:usuario]
  end

	def paso1_actualizar_datos
	
		usr = params[:usuario]
		if @usuario = Usuario.where(:ci => usr[:ci]).limit(1).first

		  	@usuario.ultima_modificacion_sistema = Time.now
		  	@usuario.nombres = usr[:nombres]
		  	@usuario.apellidos = usr[:apellidos]
		  	@usuario.correo = usr[:correo]
		  	@usuario.telefono_habitacion = usr[:telefono_habitacion]
		  	@usuario.telefono_movil = usr[:telefono_movil]
		  	@usuario.direccion = usr[:direccion]
		  	@usuario.contrasena = usr[:contrasena]
		  	@usuario.tipo_sexo_id = usr[:tipo_sexo_id]
		  	@usuario.fecha_nacimiento = usr[:fecha_nacimiento]
		  	session[:usuario] = @usuario
		  	
		  	
		  
		  respond_to do |format|	
		    if @usuario.save 
		    	format.html { redirect_to :action => "paso2_regulares"}
		      format.xml  { head :ok }
		    else
		    	flash[:mensaje] = params[:nombres]
		      format.html { render :action => "paso1" }
		      format.xml  { render :xml => @usuario.errors, :status => :unprocessable_entity }
		    end
		  end
		else
			flash[:mensaje] = "Error Usuario no encontrado #{usr[:ci]}"
		  render :action => "paso1"
		end
		
		
  end
  
  
  def paso2_regulares
  	
  	usuario = session[:usuario]
  	tipo_curso = session[:tipo_curso]
  	
  	periodo_anterior = ParametroGeneral.periodo_anterior
    periodo_actual = ParametroGeneral.periodo_actual
    
    h = HistorialAcademico.where(:usuario_ci => usuario.ci, :periodo_id => periodo_anterior.id).limit(1).first
    #, :idioma_id => tipo_curso.idioma_id, :tipo_categoria_id => tipo_curso.tipo_categoria_id
    
    @historial = HistorialAcademico.new
    @historial.usuario_ci = h.usuario_ci
    @historial.tipo_convenio_id = h.tipo_convenio_id
    @historial.periodo_id = periodo_actual.id
    @historial.tipo_categoria_id = h.tipo_categoria_id
    @historial.idioma_id = h.idioma_id
    @historial.tipo_convenio_id = h.tipo_convenio_id
    
    if siguiente_nivel = h.curso.siguiente_nivel
    
    	if seccion = Seccion.where(:periodo_id=>@historial.periodo_id, :idioma_id=>@historial.idioma_id, :tipo_categoria_id=>@historial.tipo_categoria_id, :tipo_nivel_id => siguiente_nivel.tipo_nivel_id,:esta_abierta=>1).limit(1).first
    	
    		@historial.tipo_nivel_id = seccion.tipo_nivel_id
    		@historial.seccion_numero = seccion.seccion_numero    		
    		@horario = seccion.horario
    		session[:historial]=@historial
    	else
    		flash[:mensaje] = "En estos momentos no se disponen de secciones para su siguiente nivel"
    		redirect_to :action => "index"
    		
    	end
    	
    else
    	flash[:mesaje] = "¡Felicidades Ud. aprobó todos los niveles de la categoría #{@historial.tipo_categoria.descripcion}!"
    	
    	
    	if @historial.tipo_categoria_id == "NI"    		
    		@historial.tipo_categoria_id = "TE"
    		@historial.tipo_nivel_id = "BI"
    	elsif @historial.tipo_categoria_id == "TE"
    		@historial.tipo_categoria_id = "AD"
    		@historial.tipo_nivel_id = "BI"
    	end
    		flash[:mensaje] = flash[:mensaje]+", Ahora su Categoría #{@historial.tipo_categoria.descripcion} en el nivel #{@historial.tipo_nivel.descripcion}!"      
    		redirect_to :action => "index"      		
    	
    end

  end
  
  def paso2_seleccionar_curso
  	h = session[:historial]
  	
  	@historial = HistorialAcademico.new
  	
  	@historial.usuario_ci = h.usuario_ci
    @historial.tipo_convenio_id = h.tipo_convenio_id
    @historial.periodo_id = h.periodo_id
    @historial.tipo_categoria_id = h.tipo_categoria_id
    @historial.idioma_id = h.idioma_id
    @historial.tipo_convenio_id = h.tipo_convenio_id
  	@historial.nota_final = "0"
  	@historial.tipo_estado_calificacion_id = "SC"
  	@historial.tipo_estado_inscripcion_id = "PRE"
  	@historial.tipo_nivel_id = h.tipo_nivel_id
   	@historial.seccion_numero = h.seccion.seccion_numero 
  	
		if @historial.save
			session[:historial] = @historial
    	redirect_to :action => "paso3_regulares"
    else
    	flash[:mensaje] = "no se pudo guardar los cambios, intentelo nuevamente"
      render :action => "paso2_regulares"
    end
	end      
	
	def paso3_regulares
		
		usuario = session[:usuario]
  	tipo_curso = session[:tipo_curso]
  	
    periodo_actual = ParametroGeneral.periodo_actual
    
    @historial = HistorialAcademico.where(:usuario_ci => usuario.ci, :periodo_id => periodo_actual.id).limit(1).first
    #, :idioma_id => tipo_curso.idioma_id, :tipo_categoria_id => tipo_curso.tipo_categoria_id
    
    @horario = @historial.seccion.horario
		
		
	end
	
	def paso3_generar_comprobante
		flash[:mensaje] = "inscripción completada correctamente"
		redirect_to :action=>"index"
		
		
	end
	
	def cursos
		@titulo_pagina = "Consultar Historial de Cursos"
		usuario = session[:usuario]
  	tipo_curso = session[:tipo_curso]
  	
    periodo_actual = ParametroGeneral.periodo_actual
    info_bitacora "Esta viendo sus cursos realizados"
    
    @historial = HistorialAcademico.where(:usuario_ci => usuario.ci,
    :idioma_id => tipo_curso.idioma_id,
    :tipo_categoria_id => tipo_curso.tipo_categoria_id)
		if @historial.size == 0
		  flash[:mensaje] = "No tiene cursos en este idioma"
  		redirect_to :action=>"principal", :controller => "principal"
  		return
	  end
		@historial = @historial.sort_by{|x| "#{x.periodo.ano}-#{x.periodo.id}"} 

	end
	
	
end
