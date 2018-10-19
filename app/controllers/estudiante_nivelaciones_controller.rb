# encoding: utf-8

class EstudianteNivelacionesController < ApplicationController
  # GET /estudiante_nivelaciones
  # GET /estudiante_nivelaciones.json
  def index 
    @titulo_pagina = "Estudiantes con nivelación - Periodo #{session[:parametros][:periodo_actual]}"
    @estudiante_nivelaciones = EstudianteNivelacion.all#here(periodo_id: "E-2017")#sort_by{|x| x.usuario.descripcion}
    @periodo_id = session[:parametros][:periodo_actual]

    @idiomas = Idioma.all.delete_if{|i| i.id.eql? 'OR' }

  end

  # GET /estudiante_nivelaciones/1
  # GET /estudiante_nivelaciones/1.json
  def buscar
    @titulo_pagina = "Agregar estudiante con nivelación"
    @usuario = Usuario.where(:ci => params[:usuario][:ci]).first
    unless @usuario                      
      @usuario = Usuario.new
      @usuario.ci = params[:usuario][:ci]
    end
    @tipo_curso = TipoCurso.all.sort_by{|x| x.descripcion}
  end
  
  def agregar
    begin
      @usuario = Usuario.where(:ci => params[:usuario][:ci]).first
       unless @usuario                      
         @usuario = Usuario.new
         @usuario.ci = params[:usuario][:ci]
         @usuario.telefono_habitacion = ""
         @usuario.direccion = ""
         @usuario.contrasena = params[:usuario][:ci]  
         @usuario.contrasena_confirmation = params[:usuario][:ci]  
         @usuario.fecha_nacimiento = "1990-01-01"
      end                
      usr = params[:usuario]
      @usuario.nombres = usr[:nombres]
      @usuario.apellidos = usr[:apellidos]
      @usuario.correo = usr[:correo]
      @usuario.tipo_sexo_id = usr[:tipo_sexo_id]
      @usuario.telefono_movil = usr[:telefono_movil]                    
      if @usuario.save  
        unless Estudiante.where(:usuario_ci => params[:usuario][:ci]).first
          est = Estudiante.new
          est.usuario_ci = params[:usuario][:ci]
          est.save
        end                   
        
                     
        en = EstudianteNivelacion.new
        en.usuario_ci = @usuario.ci
        en.periodo_id = session[:parametros][:periodo_actual]
        en.observaciones = params[:varios][:observaciones]
        idioma_id, tipo_categoria_id = params[:varios][:tipo_curso_id].split","
        en.idioma_id = idioma_id
        en.tipo_categoria_id = tipo_categoria_id
        en.save!
        
        flash[:mensaje] = "El estudiante con nivelación ha sido agregado"
        redirect_to :action => "index"
      else                       
        @tipo_curso = TipoCurso.all.sort_by{|x| x.descripcion}
        render :action => "buscar"
      end
    rescue Exception => e

      flash[:mensaje] = "Error al intentar agregar nivelación: #{e}"
      @tipo_curso = TipoCurso.all.sort_by{|x| x.descripcion}
      render :action => "buscar"
    
    end
  end

  # GET /estudiante_nivelaciones/new
  # GET /estudiante_nivelaciones/new.json
  def new
    @estudiante_nivelacion = EstudianteNivelacion.new
  end 
  
  
  def inscribir
    session[:estudiante_ci] = params[:id]
    redirect_to :controller => "inscripcion_admin", :action => "paso0", :idioma => params[:idioma]
  end


  def inscribir_paso1
    @titulo_pagina = "Preinscripción - Admin"  
    @subtitulo_pagina = "Actualización de Datos Personales"
    @usuario = Usuario.where(:ci => params[:id]).limit(1).first
    @idioma_id = params[:idioma]

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
      # session[:especial_usuario] = @usuario
      
      if @usuario.save 
        info_bitacora "Paso1 (Actualización de Datos Personales) realizado con éxito."
        flash[:mensaje] = "Paso1 (Actualización de Datos Personales) realizado con éxito."
        redirect_to :action => "inscribir_paso2" , :id => "#{@usuario.ci}", :idioma_id => "#{params[:idioma_id]}"
      else
        @titulo_pagina = "Preinscripción - Admin"
        @subtitulo_pagina = "Actualización de Datos Personales"
        render :action => "inscribir_paso1"
      end
    else
      flash[:mensaje] = "Error Usuario no encontrado #{usr[:ci]}."
      render :action => "inscribir_paso1"
    end
  end


  def inscribir_paso2
    @convenios = TipoConvenio.all
    @estudiante_curso = EstudianteCurso.new

    @estudiante_curso.usuario_ci = params[:id]
    idioma_id, cat_id = params[:idioma_id].split

    @estudiante_curso.idioma_id = idioma_id
    @estudiante_curso.tipo_categoria_id = cat_id

    @niveles = Seccion.where(:idioma_id => idioma_id,
      :tipo_categoria_id => cat_id,
      :periodo_id => session[:parametros][:periodo_actual]).collect{|x| x.curso}.uniq.sort_by{|y| y.grado}.collect{|w| w.tipo_nivel}

  end

  def paso2_guardar
    usuario_ci = params[:estudiante_curso][:usuario_ci]
    idioma_id = params[:estudiante_curso][:idioma_id]
    tipo_categoria_id = params[:estudiante_curso][:tipo_categoria_id]
    # idioma_id, tipo_categoria_id = params[:seleccion][:idioma_id].split","
    # tipo_convenio_id = params[:seleccion][:tipo_convenio_id]
    @tipo_curso = TipoCurso.where(:idioma_id => idioma_id, :tipo_categoria_id => tipo_categoria_id).limit(1).first

    # Busco o creo Usuario 
    @usuario = Usuario.find_or_create_by_ci(usuario_ci)
    @usuario.save! :validate => false

    # Busco o creo estudiente
    @estudiante = Estudiante.find_or_create_by_usuario_ci(usuario_ci)
    @estudiante.save! :validate => false

    # Busco o creo EstudianteCurso

    @estudiante_curso = EstudianteCurso.where(params[:estudiante_curso]).limit(1).first
    @estudiante_curso = EstudianteCurso.new(params[:estudiante_curso]) unless @estudiante_curso

    if @estudiante_curso.save
      flash[:mensaje] = "Paso2 (Selección de Convenio y recibo de pago) realizado con éxito."
      redirect_to :action => "inscribir_paso3", :recibo => params[:recibo], :id => @estudiante_curso.id, :tipo_nivel => params[:nivel][:id]
    else
      render :action => "inscribir_paso2"
    end

  end

  def inscribir_paso3


    @titulo_pagina = "Preinscripción - Admin - Nivelación"
    @subtitulo_pagina = "Selección de Sección"
    recibo = params[:recibo]
    tipo_nivel = TipoNivel.find params[:tipo_nivel]
    estudiante_curso = EstudianteCurso.find (params[:id])
    @secciones = Seccion.where(
      :periodo_id => session[:parametros][:periodo_actual],
      :idioma_id => estudiante_curso.idioma_id,
      :tipo_categoria_id => estudiante_curso.tipo_categoria_id,
      :tipo_nivel_id => tipo_nivel.id
      ).sort_by{|s| s.cupo}

    @historial = HistorialAcademico.new
    @historial.usuario_ci = estudiante_curso.usuario_ci
    @historial.tipo_categoria_id = estudiante_curso.tipo_categoria_id
    @historial.idioma_id = estudiante_curso.idioma_id
    @historial.periodo_id = session[:parametros][:periodo_actual]
    @historial.tipo_convenio_id = estudiante_curso.tipo_convenio_id
    @historial.tipo_nivel_id = tipo_nivel.id
    @historial.numero_deposito = recibo


  end

  def paso3_guardar
    @historial = HistorialAcademico.new(params[:historial_academico])

    @historial.tipo_estado_calificacion_id = "SC"
    @historial.tipo_estado_inscripcion_id = "INS"
    @historial.cuenta_bancaria_id = @historial.cuenta_nueva
    @historial.nota_final = -2
    
    if @historial.save
      flash[:mensaje] = "Estudiante Inscrito Satisfactoriamente."
      info_bitacora "Estudiante de nivelación inscrito #{@historial.usuario_ci}"
      EstudianteMailer.nivelacion(@historial.usuario,@historial).deliver
      redirect_to :action => "index"
    else
      render :action => "inscribir_paso3"
    end 

  end


  def eliminar
    @estudiante_nivelacion = EstudianteNivelacion.find(params[:id])
    @estudiante_nivelacion.destroy
    flash[:mensaje] = "Se ha eliminado la nivelación"
    redirect_to :action => "index"
  end

  def confirmar
    @estudiante_nivelacion = EstudianteNivelacion.find(params[:id])
    @estudiante_nivelacion.confirmado = 1
    @estudiante_nivelacion.save
    flash[:mensaje] = "Se ha confirmado al estudiante"
    redirect_to :action => "index"
  end

  def planilla_nivelacion
    
    usuario_ci,periodo_id,idioma_id,tipo_categoria_id = params[:id]
    @historial = EstudianteNivelacion.where(
      :usuario_ci => usuario_ci,
      :idioma_id => idioma_id,
      :tipo_categoria_id => tipo_categoria_id,
      :periodo_id => periodo_id).limit(1).first
    info_bitacora "Se busco la planilla de nivelacion en #{@historial.usuario_ci}"
    pdf = DocumentosPDF.planilla_nivelacion(@historial)
    send_data pdf.render,:filename => "planilla_nivelacion_#{usuario_ci}.pdf",
                         :type => "application/pdf", :disposition => "attachment"
  end

  def listado_confirmados
    periodo_id = params[:periodo_id]
    idioma_id = params[:idioma_id]
    if pdf = DocumentosPDF.generar_listado_nivelacion_confirmados(periodo_id, idioma_id)
      send_data pdf.render,:filename => "nivelacion_confirmados_#{periodo_id}.pdf",:type => "application/pdf", :disposition => "attachment"
    end
  end

  def listado_confirmados_excel
    periodo_id = params[:periodo_id]
    idioma_id = params[:idioma_id]

    ruta_excel = ReportesExcel.generar_listado_nivelacion_confirmados(periodo_id, idioma_id)
    send_file ruta_excel,
      :filename => "nivelacion_confirmados_#{periodo_id}.xls",
      :type => "application/excel", :disposition => "attachment"
    
  end
end
