# encoding: utf-8

class InscripcionAdminController < ApplicationController
  
  before_action :filtro_logueado
  before_action :filtro_administrador
  
  def paso0                    
    #cargar_parametros_generales
    @titulo_pagina = "Inscripción"  
    @subtitulo_pagina = "Datos Básicos"    
    if usuario = Usuario.where(:ci => session[:estudiante_ci]).limit(1).first
      @usuario = usuario      
    else                      
      @usuario = Usuario.new
    end
    #tipo_curso = Seccion.where(:periodo_id => session[:parametros][:periodo_actual], esta_abierta: true).collect{|y| y.tipo_curso.id}.sort.uniq
    tipo_curso = Seccion.where("periodo_id = ? and esta_abierta IS TRUE", session[:parametros][:periodo_actual]).collect{|y| y.tipo_curso.id}.sort.uniq
    @idiomas = TipoCurso.all.delete_if{|x| !tipo_curso.index(x.id)}

    #para predeterminar un idioma
    if idi = params[:idioma]                       
        if indice = @idiomas.collect{|x| x.id }.index(idi)
          elemento = @idiomas.delete_at(indice)
          @idiomas.insert(0, elemento)
         end     
    end                          
    
    @convenios = TipoConvenio.all
  end
  
  def paso0_guardar
    usuario_ci = params[:usuario][:ci]
    idioma_id, tipo_categoria_id = params[:seleccion][:idioma_id].split","
    tipo_convenio_id = params[:seleccion][:tipo_convenio_id]
    @tipo_curso = TipoCurso.where(
       :idioma_id => idioma_id,
       :tipo_categoria_id => tipo_categoria_id).limit(1).first
    #buscar en usuario
    if usuario = Usuario.where(:ci => usuario_ci).limit(1).first
      @usuario = usuario      
      
      if estudiante = Estudiante.where(:usuario_ci => usuario_ci).limit(1).first
        @estudiante = estudiante           
        
        if ec = EstudianteCurso.where(:usuario_ci => usuario_ci,
           :idioma_id => idioma_id,
           :tipo_categoria_id => tipo_categoria_id).limit(1).first 
          if ec.tipo_convenio_id != tipo_convenio_id
            ec.tipo_convenio_id = tipo_convenio_id
            ec.save
          end
          @estudiante_curso = ec
        else
          @estudiante_curso = EstudianteCurso.new
          @estudiante_curso.usuario_ci = usuario_ci
          @estudiante_curso.idioma_id = idioma_id
          @estudiante_curso.tipo_categoria_id = tipo_categoria_id
          @estudiante_curso.tipo_convenio_id = tipo_convenio_id
          @estudiante_curso.save!
        end
      else
        @estudiante = Estudiante.new
        @estudiante.usuario_ci = usuario_ci
        @estudiante.save!

        @estudiante_curso = EstudianteCurso.new
        @estudiante_curso.usuario_ci = usuario_ci
        @estudiante_curso.idioma_id = idioma_id
        @estudiante_curso.tipo_categoria_id = tipo_categoria_id
        @estudiante_curso.tipo_convenio_id = tipo_convenio_id
        @estudiante_curso.save!
      end
    else
      @usuario = Usuario.new
      @usuario.ci = usuario_ci
      @usuario.nombres = ""
      @usuario.apellidos = ""
      @usuario.telefono_movil = ""
      @usuario.fecha_nacimiento = "1990-01-01"
      @usuario.save! :validate => false

      @estudiante = Estudiante.new
      @estudiante.usuario_ci = usuario_ci
      @estudiante.save!

      @estudiante_curso = EstudianteCurso.new
      @estudiante_curso.usuario_ci = usuario_ci
      @estudiante_curso.idioma_id = idioma_id
      @estudiante_curso.tipo_categoria_id = tipo_categoria_id
      @estudiante_curso.tipo_convenio_id = tipo_convenio_id
      @estudiante_curso.save!


    end
    session[:especial_usuario] = @usuario
    session[:especial_estudiante] = @estudiante
    session[:especial_rol] = @estudiante_curso.descripcion
    session[:especial_tipo_curso] = @tipo_curso
    info_bitacora "Paso 0 realizado en ADMIN #{@tipo_curso.descripcion}"
    redirect_to :action => "paso1"
    return
  end
  
  def paso1      
    @titulo_pagina = "Preinscripción - Admin"  
    @subtitulo_pagina = "Actualización de Datos Personales"
    @usuario = session[:especial_usuario]
  end  

  def paso1_guardar
    usr = params[:usuario]
    if @usuario = Usuario.where(:ci => usr[:ci]).limit(1).first
      @usuario.ultima_modificacion_sistema = Time.now
      @usuario.nombres = usr[:nombres]
      @usuario.apellidos = usr[:apellidos]
      @usuario.correo = usr[:correo]
      @usuario.telefono_habitacion = usr[:telefono_habitacion]
      @usuario.telefono_movil = usr[:telefono_movil]
      @usuario.direccion = usr[:direccion] 
      if @usuario.contrasena == nil || @usuario.contrasena == "" || @usuario.contrasena.empty?
        @usuario.contrasena = usr[:ci]
        @usuario.contrasena_confirmation = usr[:ci]
      else                                         
        @usuario.contrasena_confirmation = @usuario.contrasena
      end                                                     
      
      @usuario.tipo_sexo_id = usr[:tipo_sexo_id]
      @usuario.fecha_nacimiento = usr[:fecha_nacimiento]
      session[:especial_usuario] = @usuario
      
      if @usuario.save 
        info_bitacora "Paso1 realizado"
        redirect_to :action => "paso1_1"
      else
        @titulo_pagina = "Preinscripción - Admin"  
        @subtitulo_pagina = "Actualización de Datos Personales"
        render :action => "paso1"
      end
    else
      flash[:mensaje] = "Error Usuario no encontrado #{usr[:ci]}"
      render :action => "paso1"
    end
  end
  
  def paso1_1
    @titulo_pagina = "Preinscripción - Admin"  
    @subtitulo_pagina = "Selección de Nivel"
    @usuario = session[:especial_usuario]
    @tipo_curso = session[:especial_tipo_curso] 
    @niveles = Seccion.where(:idioma_id => @tipo_curso.idioma_id,
      :tipo_categoria_id => @tipo_curso.tipo_categoria_id,
      :periodo_id => session[:parametros][:periodo_actual]).collect{|x| x.curso}.uniq.sort_by{|y| y.grado}.collect{|w| w.tipo_nivel}
  end
  
  def paso1_1_guardar
    session[:especial_nivel] = params[:seleccion][:nivel]
    redirect_to :action => "paso2"
  end
  
  def paso2
    @horario_inscripcion_activo = ParametroGeneral.horario_inscripcion_activo
    @titulo_pagina = "Preinscripción - Admin"
    @subtitulo_pagina = "Selección de Sección"
    @tipo_nivel = TipoNivel.find session[:especial_nivel]
    ec = EstudianteCurso.find(session[:especial_usuario].ci, 
      session[:especial_tipo_curso].idioma_id, 
      session[:especial_tipo_curso].tipo_categoria_id)
    @ec = ec
    @secciones = Seccion.where(
      :periodo_id => session[:parametros][:periodo_actual],
      :idioma_id => ec.idioma_id,
      :tipo_categoria_id => ec.tipo_categoria_id,
      :tipo_nivel_id => session[:especial_nivel],
      :esta_abierta => true).sort_by{|s| s.cupo}
  end

  def paso2_guardar
    ec = EstudianteCurso.find(session[:especial_usuario].ci, 
      session[:especial_tipo_curso].idioma_id, 
      session[:especial_tipo_curso].tipo_categoria_id) 
    periodo_id, idioma_id, tipo_categoria_id, tipo_nivel_id, seccion_numero = params[:datos][:seccion].split","
    @historial = HistorialAcademico.new
    @historial.usuario_ci = session[:especial_usuario].ci
    @historial.tipo_categoria_id = tipo_categoria_id
    @historial.idioma_id = idioma_id
    @historial.periodo_id = periodo_id
    @historial.tipo_convenio_id = ec.tipo_convenio_id 
    @historial.tipo_nivel_id = tipo_nivel_id 
    @historial.tipo_estado_calificacion_id = "SC"
    @historial.tipo_estado_inscripcion_id = "PRE"
    @historial.cuenta_bancaria_id = @historial.cuenta_nueva
    @historial.nota_final = -2
    @historial.numero_deposito = ""
    @historial.seccion_numero = seccion_numero
    
    if HistorialAcademico.where(
      :usuario_ci => @historial.usuario_ci,
      :idioma_id => @historial.idioma_id,
      :tipo_categoria_id => @historial.tipo_categoria_id,
      :periodo_id => @historial.periodo_id
      ).limit(1).first
      flash[:mensaje] = "El estudiante ya estaba inscrito en este periodo"
      info_bitacora "El estudiante ya estaba inscrito en este periodo"
      redirect_to :action => "principal", :controller => "principal"
      return
    end
    
    @historial.save  

    #correo de asignacion
    if EstudianteNivelacion.where(:usuario_ci => @historial.usuario_ci, 
      :idioma_id => @historial.idioma_id, :tipo_categoria_id => @historial.tipo_categoria_id,
      :periodo_id => @historial.periodo_id).first
      EstudianteMailer.nivelacion(@historial.usuario,@historial).deliver
    end


    info_bitacora "Paso 2 realizado preinscripcion realizada en #{@historial.seccion.descripcion_con_periodo}"
    flash[:mensaje] = "Preinscripción realizada, recuerde imprimir su planilla"
    redirect_to :action => "paso3"
  end

  def paso3 
    @titulo_pagina = "Preinscripción - Admin"  
    @subtitulo_pagina = "Impresión de Planilla"
    @historial = HistorialAcademico.where(
      :usuario_ci => session[:especial_usuario].ci,
      :idioma_id => session[:especial_tipo_curso].idioma_id,
      :tipo_categoria_id => session[:especial_tipo_curso].tipo_categoria_id,
      :periodo_id => session[:parametros][:periodo_actual]).limit(1).first
    @nivelacion = EstudianteNivelacion.where(:usuario_ci => @historial.usuario_ci)
  end

  def paso3_guardar                                              
    flash[:mensaje] = "Preinscripción finalizada"
    redirect_to :action => "principal", :controller => "principal"
  end     
  
  def planilla_inscripcion
    ci, idioma_id, tipo_categoria_id, tipo_nivel_id, periodo_id, seccion_numero = params[:historial].split","
    @historial = HistorialAcademico.where(
      :usuario_ci => ci,
      :idioma_id => idioma_id,
      :tipo_categoria_id => tipo_categoria_id,
      :periodo_id => periodo_id).limit(1).first
    info_bitacora "Se busco la planilla de inscripcion desde el  ADMIN en #{@historial.seccion.descripcion_con_periodo}"
    pdf = DocumentosPDF.planilla_inscripcion(@historial)
    send_data pdf.render,:filename => "planilla_inscripcion_#{ci}.pdf",
                         :type => "application/pdf", :disposition => "attachment"
  end  
end
