# encoding: utf-8

class InscripcionController < ApplicationController
  
  #before_action :filtro_inscripcion_abierta, :except => ["paso0","paso0_guardar","planilla_inscripcion"] 
  #before_action :filtro_primer_dia, :only => ["paso1","paso2"]
  before_action :filtro_logueado, :except => ["paso0_ingles", "paso0","paso0_guardar", 'ingrese_ci', 'ingrese_ci_guardar']
  #before_action :filtro_nuevos

  def ingrese_ci
    reset_session
    cargar_parametros_generales

    @inscripcion = Inscripcion.find(params[:id]) 
    periodo_id =  ParametroGeneral.periodo_inscripcion.id

    horario_inscripcion_activo = ParametroGeneral.horario_inscripcion_activo

    secciones = Seccion.where(:periodo_id => periodo_id, 
      :idioma_id => @inscripcion.tipo_curso.idioma_id, 
      :tipo_categoria_id => @inscripcion.tipo_curso.tipo_categoria_id, 
      :esta_abierta => true).delete_if{|s| s.curso.grado != 1}.delete_if{|s| !s.hay_cupo?} 

    secciones = secciones.delete_if{|s| s.horario == 'Sábado (08:30AM - 12:45PM)'} if horario_inscripcion_activo.eql? 'SEMANAL'
    secciones = secciones.delete_if{|s| s.horario != 'Sábado (08:30AM - 12:45PM)'} if horario_inscripcion_activo.eql? 'SABATINOS'
    
    if @inscripcion.nil? or (!@inscripcion.abierta?) or secciones.count < 1
      reset_session
      flash[:mensaje] = "Cupos agotados para el idioma solicitado" if secciones.count < 1
      flash[:mensaje] = "Error, No hay cursos abiertos para el idioma solicitado" if @inscripcion.nil? or (!@inscripcion.abierta?)
      redirect_to :controller => "inicio"
      return
    else
      session[:inscripcion_id] = @inscripcion.id.to_a
      @titulo_pagina = "Inscripción de Curso #{@inscripcion.tipo_curso.descripcion}"  
      @subtitulo_pagina = "Paso 0: Registro de Cédula de Identidad"
    end
    render :layout => "nuevo"
  end

  def ingrese_ci_guardar
    usuario_ci = params[:usuario][:ci].delete(" ")
    # Implementar Ruby Regex para validacion de string con Expresiones regulares
    @inscripcion = Inscripcion.find(session[:inscripcion_id])
    periodo_id =  ParametroGeneral.periodo_inscripcion.id
    secciones = Seccion.where(:periodo_id => periodo_id, 
      :idioma_id => @inscripcion.tipo_curso.idioma_id, 
      :tipo_categoria_id => @inscripcion.tipo_curso.tipo_categoria_id, 
      :esta_abierta => true).delete_if{|s| s.curso.grado != 1}.delete_if{|s| !s.hay_cupo?} 

    if @inscripcion.nil? or (!@inscripcion.abierta?) or secciones.count < 1
      reset_session
      flash[:mensaje] = "Cupos agotados para el idioma solicitado" if secciones.count < 1
      flash[:mensaje] = "Error, No hay cursos abiertos para el idioma solicitado" if @inscripcion.nil? or (!@inscripcion.abierta?)
      redirect_to :controller => "inicio"
      return
    end    
    # Si hay idioma_categoria y TipoCurso correspondiente:
    # procedemos a localizar el usuario o a crearlo si no existe
    unless usuario = Usuario.where(:ci => usuario_ci).limit(1).first
      usuario = Usuario.new
      usuario.ci = usuario_ci
      usuario.nombres = usuario.apellidos = usuario.telefono_movil = ""
      usuario.contrasena = usuario_ci      
      usuario.fecha_nacimiento = "1990-01-01"
      usuario.save! :validate => false
    end

    # procedemos a localizar o crear el estudiante
    unless est = usuario.estudiante
      # Estudiante.create(:usuario_ci => usuario.ci, :tipo_nivel_academico_id => nil) 
      est = Estudiante.new
      est.usuario_ci = usuario_ci
      est.save!
    end

    unless estudiante_curso = est.estudiante_cursos.where(:idioma_id => @inscripcion.idioma_id, :tipo_categoria_id => @inscripcion.tipo_categoria_id).limit(1).first
      estudiante_curso = EstudianteCurso.new
      estudiante_curso.usuario_ci = usuario_ci
      estudiante_curso.idioma_id = @inscripcion.idioma_id
      estudiante_curso.tipo_categoria_id = @inscripcion.tipo_categoria_id
      estudiante_curso.tipo_convenio_id = "REG"
      estudiante_curso.save!
    end

    session[:usuario] = usuario
    # session[:estudiante] = est
    # session[:rol] = estudiante_curso.descripcion
    info_bitacora "Preinscripción: Paso 0 realizado en #{@inscripcion.descripcion}"
    redirect_to :action => "seleccionar_horario"
    return

  end

  def seleccionar_horario

    @inscripcion = Inscripcion.find(session[:inscripcion_id])
    periodo_id =  ParametroGeneral.periodo_inscripcion.id
    secciones = Seccion.where(:periodo_id => periodo_id, 
      :idioma_id => @inscripcion.tipo_curso.idioma_id, 
      :tipo_categoria_id => @inscripcion.tipo_curso.tipo_categoria_id, 
      :esta_abierta => true).delete_if{|s| s.curso.grado != 1}.delete_if{|s| !s.hay_cupo?} 
    if @inscripcion.nil? or (!@inscripcion.abierta?) or secciones.count < 1
      reset_session
      flash[:mensaje] = "Cupos agotados para el idioma solicitado" if secciones.count < 1
      flash[:mensaje] = "Error, No hay cursos abiertos para el idioma solicitado" if @inscripcion.nil? or (!@inscripcion.abierta?)
      redirect_to :controller => "inicio"
      return
    end

    horario_inscripcion_activo = ParametroGeneral.horario_inscripcion_activo

    secciones = secciones.delete_if{|s| s.horario == 'Sábado (08:30AM - 12:45PM)'} if (horario_inscripcion_activo.eql? 'SEMANAL')
    secciones = secciones.delete_if{|s| s.horario != 'Sábado (08:30AM - 12:45PM)'} if (horario_inscripcion_activo.eql? 'SABATINOS')

    # Se buscan los horarios que tienen las secciones selccionadas
    @horarios = secciones.collect{|s| s.horario}.uniq.sort

    @titulo_pagina = "Preinscripción: Paso 1 de 3 - Selección de Horario"

    # @titulo_pagina = "Inscripción de Curso #{@inscripcion.descripcion}"  
    # @subtitulo_pagina = "Paso 1 de 3: Selección de horario"
    if @horarios.size == 0
      flash[:mensaje] = "En este momento no tenemos cupos."
      redirect_to :controller => 'inicio'
      return
    end
  end


  def seleccionar_horario_guardar
    @inscripcion = Inscripcion.find(session[:inscripcion_id])
    periodo_id =  ParametroGeneral.periodo_inscripcion.id
    secciones = Seccion.where(:periodo_id => periodo_id, 
      :idioma_id => @inscripcion.tipo_curso.idioma_id, 
      :tipo_categoria_id => @inscripcion.tipo_curso.tipo_categoria_id, 
      :esta_abierta => true).delete_if{|s| s.curso.grado != 1}.delete_if{|s| !s.hay_cupo?} 

    if @inscripcion.nil? or (!@inscripcion.abierta?) or secciones.count < 1
      reset_session
      flash[:mensaje] = "Cupos agotados para el idioma solicitado" if secciones.count < 1
      flash[:mensaje] = "Error, No hay cursos abiertos para el idioma solicitado" if @inscripcion.nil? or (!@inscripcion.abierta?)
      redirect_to :controller => "inicio"
      return
    end

    # seccion = session[:seccion]  
    ec = EstudianteCurso.find(session[:usuario], 
      @inscripcion.tipo_curso.idioma_id, 
      @inscripcion.tipo_curso.tipo_categoria_id)
    
    # se busca el proximo historial correspondiente al Estudiante Curso en cuestion
    @historial = ec.proximo_historial
    # Se buscan la seccion para este usuario y en ese horario
    seccion = @historial.buscar_seccion(params[:usuario][:horario]) unless seccion
    unless seccion 
      flash[:mensaje] = "Lo sentimos pero no hay secciones disponibles en ese horario"
      info_bitacora "No hay secciones disponible para su horario"
      redirect_to :action => "seleccionar_horario"
      return
    end
    @historial.seccion_numero = seccion

    if HistorialAcademico.where(
      :usuario_ci => @historial.usuario_ci,
      :idioma_id => @historial.idioma_id,
      :tipo_categoria_id => @historial.tipo_categoria_id,
      :periodo_id => @historial.periodo_id
      ).limit(1).first
      flash[:mensaje] = "Usted ya estaba inscrito en el curso: #{@inscripcion.descripcion}. Ingrese en su sesión para mayor información."
      info_bitacora "Usuario ya estaba inscrito en este periodo"
      redirect_to :controller => "inicio"
      return
    end
    
    if @historial.save
      session[:tipo_curso] = @inscripcion.tipo_curso
      info_bitacora "Paso 1 realizado preinscripcion realizada en #{@historial.seccion.descripcion_con_periodo}"
      flash[:mensaje] = "Preinscripción realizada, Su cupo está reservado"
      redirect_to :action => "actualizar_datos_personales"
    else
      flash[:mensaje] = "Error inesperado, no se pudo realizar la inscripción"
      redirect_to :action => "seleccionar_horario"
    end

  end

  def actualizar_datos_personales
    @titulo_pagina = "Preinscripción: Paso 2 de 3 - Actualización de Datos Personales"
    @usuario = session[:usuario]
  end


  def guardar_datos_personales
    @inscripcion = Inscripcion.find(session[:inscripcion_id])
    usr = params[:usuario]
    if @usuario = Usuario.where(:ci => usr[:ci]).limit(1).first
      @usuario.ultima_modificacion_sistema = Time.now
      @usuario.nombres = usr[:nombres]
      @usuario.apellidos = usr[:apellidos]
      @usuario.correo = usr[:correo]
      @usuario.tipo_sexo_id = usr[:tipo_sexo_id]
      @usuario.telefono_movil = usr[:telefono_movil]
      
      if session[:nuevo]
        @usuario.telefono_habitacion = ""
        @usuario.direccion = ""
        @usuario.contrasena = usr[:ci]
        @usuario.contrasena_confirmation = usr[:ci]
        @usuario.fecha_nacimiento = "1990-01-01"
        @usuario.fecha_nacimiento = usr[:fecha_nacimiento]
      else
        @usuario.telefono_movil = usr[:telefono_movil]
        @usuario.telefono_habitacion = usr[:telefono_habitacion]
        @usuario.direccion = usr[:direccion]
        @usuario.contrasena = usr[:contrasena]
        @usuario.contrasena_confirmation = usr[:contrasena_confirmation]
        @usuario.fecha_nacimiento = usr[:fecha_nacimiento]
      end
      
      session[:usuario] = @usuario
      
      # if (@usuario.edad < 9 || @usuario.edad > 11) && @inscripcion.tipo_categoria_id == "NI" #&& session[:nuevo]
      #   flash[:mensaje] = "Usted no tiene la edad para el curso de niños"
      #   redirect_to :action => "actualizar_datos_personales"
      #   return
      # end

      # if (@usuario.edad < 12 || @usuario.edad > 14) && @inscripcion.tipo_categoria_id == "TE" #&& session[:nuevo]
      #   flash[:mensaje] = "Usted no tiene la edad para el curso de adolecentes"
      #   redirect_to :action => "actualizar_datos_personales"
      #   return
      # end

      # if (@usuario.edad < 15 ) && session[:tipo_curso].tipo_categoria_id == "AD" #&& session[:nuevo]
      #   flash[:mensaje] = "Usted no tiene la edad para el curso de adultos"
      #   redirect_to :action => "actualizar_datos_personales"
      #   return
      # end
      
      if @usuario.save 
        info_bitacora "Paso2 realizado"
        flash[:mensaje] = "Preinscripción realizada, recuerde imprimir su planilla"
        redirect_to :action => "imprimir_planilla"
      else
        @titulo_pagina = "Preinscripción - Paso 2 de 3"  
        @subtitulo_pagina = "Actualización de Datos Personales"
        render :action => "actualizar_datos_personales"
      end
    else
      flash[:mensaje] = "Error Usuario no encontrado #{usr[:ci]}"
      render :action => "actualizar_datos_personales"
    end    
  end

  def imprimir_planilla

    @titulo_pagina = "Preinscripción: Paso 3 de 3 - Normativa e Impresión de Planilla"

    @texto = "<ul><li>La inscripción es válida UNICAMENTE para el período indicado. NO SE CONGELAN CUPOS POR NINGÚN MOTIVO.</li><li>La asistencia a clases es obligatoria: Cursos <b>LUN-MIE</b>: Con 3 inasistencias se pierde el curso. Cursos <b>MAR-JUE</b>: Con 3 inasistencias se pierde el curso. Cursos <b>SÁBADOS</b>: Con 2 inasistencias se pierde el curso.</li><li>La nota mínima aprobatoria es de 15 puntos. El cupo mínimo es de 15 participantes.</li><li>NO SE PERMITEN CAMBIOS DE SECCIÓN.</li><li>El horario, sección y aula se reserva hasta la fecha indicada.</li><li>Pago únicamente DEPOSITOS en EFECTIVO (NO CHEQUES, NI TRANSFERENCIAS).</li>"

    @inscripcion = Inscripcion.find(session[:inscripcion_id])

    @historial = HistorialAcademico.where(
      :usuario_ci => session[:usuario].ci,
      :idioma_id => @inscripcion.idioma_id,
      :tipo_categoria_id => @inscripcion.tipo_categoria_id,
      :periodo_id => session[:parametros][:periodo_inscripcion]).limit(1).first 

    if @historial.tipo_categoria_id.eql? 'TE' or @historial.tipo_categoria_id.eql? 'NI'
      @texto += "<p><b>NORMATIVA PARA ADOLESCENTES Y NIÑOS</b></p><p><b>Estimado representante:</b></p><p><b>Le informamos que para poder inscribir a su representado en los cursos, debe apegarse a las siguientes condiciones:</b></p><ul><li>Traer su merienda para hacer el receso en el salón de clase. Sólo podrán ir al cafetín con una autorización escrita de su representante por cada sesión de clase.</li><li>Cumplir el horario de entrada y salida de clase. Si necesitan ausentarse y/o retirarse antes de la clase deben presentar una autorización escrita de su representante o presentarse y hablar directamente con el profesor.</li><li>No llevar pelotas, patinetas, videojuegos u objetos similares al salón de clase.</li></ul>"
      @texto += "<p><b>****Es importante que usted conozca al profesor y a los coordinadores del curso de su representado y esté en comunicación con los mismos****</b></p>"
    end

  end


  def finalizar_inscripcion
    flash[:mensaje] = "Preinscripción finalizada"
    inscripcion = Inscripcion.find(session[:inscripcion_id])
    session[:tipo_curso] = inscripcion.tipo_curso
    session[:inscripcion_id] = nil
    redirect_to :action => "principal", :controller => "principal"
  end


  def paso1
    unless params[:id]
      flash[:mensaje] = "Debe especificar el curso a inscribir"
      redirect_to :controller => "principal", :action => "principal"
    else
      @inscripcion = Inscripcion.where(:tipo_inscripcion_id => params[:id][0],
        :idioma_id => params[:id][1],
        :tipo_categoria_id => params[:id][2]).first
      if @inscripcion.nil? || !@inscripcion.abierta?
        flash[:mensaje] = "En este momento no se encuentra disponible la inscripcion para el curso seleccionado"
        redirect_to :controller => "principal", :action => "principal"
        return
      end
      @titulo_pagina = "Preinscripción - Paso 1 de 3"
      @subtitulo_pagina = "Selección de Horario"
      session[:inscripcion_id] = @inscripcion.id.to_a

      ec = EstudianteCurso.find(session[:usuario].ci, 
        @inscripcion.idioma_id, 
        @inscripcion.tipo_categoria_id)

      @historial = nil
      begin
        @historial = ec.proximo_historial
      rescue Exception => e
        flash[:mensaje] = e.message
        redirect_to :controller => "principal", :action => "principal"
        return
      end

      if @historial
        if @historial.tipo_nivel_id == "BI"
          @incripcion_nuevo_abierta = Inscripcion.where(:tipo_inscripcion_id => 'NU', 
            :idioma_id => @inscripcion.idioma_id, :tipo_categoria_id => @inscripcion.tipo_categoria_id).first
          if @incripcion_nuevo_abierta.nil? || !@incripcion_nuevo_abierta.abierta?
            flash[:mensaje] = "Para Inscribirse en el nivel Básico I debe dirigirse a la pantalla inicial en la fecha estipulada para tal fin"
            redirect_to :controller => "principal", :action => "principal"
            return
          end
        end

        @horarios = @historial.horarios_disponibles(
          # session[:parametros][:inscripcion_permitir_cambio_horario] == "NO"
          !@inscripcion.cambio_horario?
        )

        horario_inscripcion_activo = ParametroGeneral.horario_inscripcion_activo

        @horarios = @horarios.delete_if{|s| s == 'Sábado (08:30AM - 12:45PM)'} if (horario_inscripcion_activo.eql? 'SEMANAL')
        @horarios = @horarios.delete_if{|s| s != 'Sábado (08:30AM - 12:45PM)'} if (horario_inscripcion_activo.eql? 'SABATINOS')


        if @horarios.size == 0
          flash[:mensaje] = "Sin disponibilidad de cupos"
          redirect_to :controller => "principal", :action => "principal"
          return
        end
        # session[:seccion] = @historial.seccion_numero
      else # le toca nuevo
        flash[:mensaje] = "Error con el estudiante y su curso"
        redirect_to :controller => "principal", :action => "principal"
        return
      end
    end
  end

  def paso1_guardar
    # Verifico si estoy pasando el id como parametro
    unless params[:id]
      flash[:mensaje] = "Debe especificar el curso a inscribir"
      redirect_to :action => "paso1"
    else
      # Busco la inscripcion correspondiente
      tipo,idioma,categoria = params[:id].split(" ")
      @inscripcion = Inscripcion.where(:tipo_inscripcion_id => tipo,
        :idioma_id => idioma,
        :tipo_categoria_id => categoria).first

      # Veriico si no hay inscripcion
      if @inscripcion.nil?
        flash[:mensaje] = "En este momento no se encuentra disponible la inscripcion para el curso seleccionado"
        redirect_to :controller => "principal", :action => "principal"
        return
      end
      # Asigno la seccion ultima del curso realizado
      # seccion = session[:seccion]

      # Busco el EstudianteCurso correspondiente
      ec = EstudianteCurso.find(session[:usuario].ci, 
        @inscripcion.idioma_id, 
        @inscripcion.tipo_categoria_id)

      # Busco el proximo historial
      @historial = nil
      begin
        @historial = ec.proximo_historial
      rescue Exception => e
        flash[:mensaje] = e.message
        redirect_to :controller => "principal", :action => "principal"
        return
      end

      # Pregunto si está inscrito
      if HistorialAcademico.where(
        :usuario_ci => @historial.usuario_ci,
        :idioma_id => @historial.idioma_id,
        :tipo_categoria_id => @historial.tipo_categoria_id,
        :periodo_id => @historial.periodo_id
        ).limit(1).first
        flash[:mensaje] = "Usted ya estaba inscrito en este periodo"
        info_bitacora "Usuario ya estaba inscrito en este periodo"
        redirect_to :action => "principal", :controller => "principal"
        return
      end      

      # Busco la seccion 
      seccion = @historial.buscar_seccion(params[:usuario][:horario]) # unless seccion

      # pregunto si hay seccion
      unless seccion
        flash[:mensaje] = "Lo sentimos pero no hay secciones disponibles en ese horario"
        info_bitacora "No hay secciones disponible para su horario"
        redirect_to :action => "principal", :controller => "principal"
        return
      end

      # Asigno seccion al historial
      @historial.seccion_numero = seccion

      # Inscribo
      if @historial.save 
        session[:tipo_curso] = @inscripcion.tipo_curso 
        info_bitacora "Paso 1 realizado, preinscripcion realizada en #{@historial.seccion.descripcion_con_periodo}"
        flash[:mensaje] = "Preinscripción realizada, Su cupo está reservado"
        redirect_to :action => "paso2"
      else
        redirect_to :action => 'paso1'
      end

    end

  end


  def paso2      
    @titulo_pagina = "Preinscripción - Paso 2 de 3"  
    @subtitulo_pagina = "Actualización de Datos Personales"
    @usuario = session[:usuario]
  end  

  def paso2_guardar
    usr = params[:usuario]
    if @usuario = Usuario.where(:ci => usr[:ci]).limit(1).first
      @usuario.ultima_modificacion_sistema = Time.now
      @usuario.nombres = usr[:nombres]
      @usuario.apellidos = usr[:apellidos]
      @usuario.correo = usr[:correo]
      @usuario.tipo_sexo_id = usr[:tipo_sexo_id]
      @usuario.telefono_movil = usr[:telefono_movil]
      
      if session[:nuevo]
        @usuario.telefono_habitacion = ""
        @usuario.direccion = ""
        @usuario.contrasena = usr[:ci]
        @usuario.contrasena_confirmation = usr[:ci]
        @usuario.fecha_nacimiento = "1990-01-01"
        @usuario.fecha_nacimiento = usr[:fecha_nacimiento]
      else
        @usuario.telefono_movil = usr[:telefono_movil]
        @usuario.telefono_habitacion = usr[:telefono_habitacion]
        @usuario.direccion = usr[:direccion]
        @usuario.contrasena = usr[:contrasena]
        @usuario.contrasena_confirmation = usr[:contrasena_confirmation]
        @usuario.fecha_nacimiento = usr[:fecha_nacimiento]
      end
      
      session[:usuario] = @usuario
      
      if (@usuario.edad < 9 || @usuario.edad > 11) && session[:tipo_curso].tipo_categoria_id == "NI" #&& session[:nuevo]
        flash[:mensaje] = "Usted no tiene la edad para el curso de niños"
        redirect_to :action => "paso2"
        return
      end

      if (@usuario.edad < 12 || @usuario.edad > 14) && session[:tipo_curso].tipo_categoria_id == "TE" #&& session[:nuevo]
        flash[:mensaje] = "Usted no tiene la edad para el curso de adolecentes"
        redirect_to :action => "paso2"
        return
      end

      if (@usuario.edad < 15 ) && session[:tipo_curso].tipo_categoria_id == "AD" #&& session[:nuevo]
        flash[:mensaje] = "Usted no tiene la edad para el curso de adultos"
        redirect_to :action => "paso2"
        return
      end
      
      if @usuario.save 
        info_bitacora "Paso2 realizado"
        flash[:mensaje] = "Preinscripción realizada, recuerde imprimir su planilla"
        redirect_to :action => "paso3"
      else
        @titulo_pagina = "Preinscripción - Paso 2 de 3"  
        @subtitulo_pagina = "Actualización de Datos Personales"
        render :action => "paso2"
      end
    else
      flash[:mensaje] = "Error Usuario no encontrado #{usr[:ci]}"
      render :action => "paso2"
    end
  end


  def paso3 

    @titulo_pagina = "Preinscripción: Paso 3 de 3 - Normativa e Impresión de Planilla"

    @texto = "<ul><li>La inscripción es válida UNICAMENTE para el período indicado. NO SE CONGELAN CUPOS POR NINGÚN MOTIVO.</li><li>La asistencia a clases es obligatoria: Cursos <b>LUN-MIE</b>: Con 3 inasistencias se pierde el curso. Cursos <b>MAR-JUE</b>: Con 3 inasistencias se pierde el curso. Cursos <b>SÁBADOS</b>: Con 2 inasistencias se pierde el curso.</li><li>La nota mínima aprobatoria es de 15 puntos. El cupo mínimo es de 15 participantes.</li><li>NO SE PERMITEN CAMBIOS DE SECCIÓN.</li><li>El horario, sección y aula se reserva hasta la fecha indicada.</li><li>Pago únicamente DEPOSITOS en EFECTIVO (NO CHEQUES, NI TRANSFERENCIAS).</li></ul>"
    @historial = HistorialAcademico.where(
      :usuario_ci => session[:usuario].ci,
      :idioma_id => session[:tipo_curso].idioma_id,
      :tipo_categoria_id => session[:tipo_curso].tipo_categoria_id,
      :periodo_id => session[:parametros][:periodo_inscripcion]).limit(1).first
    if @historial.tipo_categoria_id.eql? 'TE' or @historial.tipo_categoria_id.eql? 'NI'
      @texto += "<p><b>NORMATIVA PARA ADOLESCENTES Y NIÑOS</b></p><p><b>Estimado representante:</b></p><p><b>Le informamos que para poder inscribir a su representado en los cursos, debe apegarse a las siguientes condiciones:</b></p><ul><li>Traer su merienda para hacer el receso en el salón de clase. Sólo podrán ir al cafetín con una autorización escrita de su representante por cada sesión de clase.</li><li>Cumplir el horario de entrada y salida de clase. Si necesitan ausentarse y/o retirarse antes de la clase deben presentar una autorización escrita de su representante o presentarse y hablar directamente con el profesor.</li><li>No llevar pelotas, patinetas, videojuegos u objetos similares al salón de clase.</li></ul>"
      @texto += "<p><b>****Es importante que usted conozca al profesor y a los coordinadores del curso de su representado y esté en comunicación con los mismos****</b></p>"
    end


  end

  def paso3_guardar                                              
    flash[:mensaje] = "Preinscripción finalizada"
    redirect_to :action => "principal", :controller => "principal"
  end     
  
  def planilla_inscripcion

    tipo_curso = session[:tipo_curso]

    @historial = HistorialAcademico.where(
      :usuario_ci => session[:usuario].ci,
      :idioma_id => tipo_curso.idioma_id,
      :tipo_categoria_id => tipo_curso.tipo_categoria_id,
      :periodo_id => session[:parametros][:periodo_inscripcion]).limit(1).first
    info_bitacora "Se busco la planilla de inscripcion en #{@historial.seccion.descripcion_con_periodo}"
    pdf = DocumentosPDF.planilla_inscripcion(@historial)
    send_data pdf.render,:filename => "planilla_inscripcion_#{session[:usuario].ci}.pdf",
                         :type => "application/pdf", :disposition => "attachment"
  end
  
  def comprobante
    render :layout => false
  end

  private
  def hay_chance (id, accion)


    reset_session
    cargar_parametros_generales

    @inscripcion = Inscripcion.find(id) 
    periodo_id =  ParametroGeneral.periodo_inscripcion.id
    # # @inscripcion = Inscripcion.where(:tipo_inscripcion_id => params[:id][0], :idioma_id => params[:id][1], :tipo_categoria_id => params[:id][2]).first 

    secciones = Seccion.where(:periodo_id => periodo_id, 
      :idioma_id => @inscripcion.tipo_curso.idioma_id, 
      :tipo_categoria_id => @inscripcion.tipo_curso.tipo_categoria_id, 
      :esta_abierta => true).delete_if{|s| s.curso.grado != 1}.delete_if{|s| !s.hay_cupo?} 
    
    if @inscripcion.nil? or (!@inscripcion.abierta?) or secciones.count < 1
      reset_session
      flash[:mensaje] = "Cupos agotados para el idioma solicitado" if secciones.count < 1
      flash[:mensaje] = "Error, No hay cursos abiertos para el idioma solicitado" if @inscripcion.nil? or (!@inscripcion.abierta?)
      redirect_to :controller => "inicio"
      return
    else
      redirect_to :action => accion
    end
    
  end




  # def paso0                    
  #   reset_session
  #   cargar_parametros_generales
  #   @titulo_pagina = "Inscripción de Nuevo en Idioma"  
  #   @subtitulo_pagina = "Datos Básicos"    
  #   @usuario = Usuario.new                    
  #   categorias = []
  #   # categorias << "NI" if ParametroGeneral.inscripcion_ninos_abierta
  #   categorias << "NI" if Inscripcion.where(:tipo_categoria_id => 'NI', :idioma_id => 'IN').first.ninos_abierta?

  #   # comentar esta siguoiente linea cuando este lista la inscripcion de ingles adultos
  #   categorias << "AD" if ParametroGeneral.inscripcion_nuevos_abierta
  #   categorias << "TE" if ParametroGeneral.inscripcion_nuevos_abierta
  #   tipo_curso = Seccion.where(:periodo_id => session[:parametros][:periodo_inscripcion],
  #     :tipo_categoria_id => categorias).delete_if{|x|
  #     x.curso.grado != 1
  #     }.collect{|y| y.tipo_curso.id}.sort.uniq                                          
  #   #puts tipo_curso.inspect
  #   #if session[:parametros][:inscripcion_modo_ninos] == "SI"
  #   #tipo_curso = Seccion.where(:periodo_id => session[:parametros][:periodo_inscripcion], :tipo_categoria_id => "NI").delete_if{|x|
  #   #  x.curso.grado != 1
  #   #  }.collect{|y| y.tipo_curso.id}.sort.uniq
  #   #end
  #   #puts tipo_curso.inspect
  #   #puts session.inspect
  #   @idiomas = TipoCurso.all.delete_if{|x| !tipo_curso.index(x.id)}
  #   if @idiomas.size == 0
  #     flash[:mensaje] = "No hay cursos disponibles"
  #     redirect_to :controller => "inicio"
  #     return
  #   end
  #   render :layout => "nuevo"
  # end
  
  # def paso0_guardar
  #   session[:nuevo] = true
  #   usuario_ci = params[:usuario][:ci]
  #   idioma_id, tipo_categoria_id = params[:seleccion][:idioma_id].split","
    
  #   @tipo_curso = TipoCurso.where(
  #      :idioma_id => idioma_id,
  #      :tipo_categoria_id => tipo_categoria_id).limit(1).first
  #   #buscar en usuario
  #   if usuario = Usuario.where(:ci => usuario_ci).limit(1).first
  #     @usuario = usuario      
      
  #     if estudiante = Estudiante.where(:usuario_ci => usuario_ci).limit(1).first
  #       @estudiante = estudiante           
        
  #       if ec = EstudianteCurso.where(:usuario_ci => usuario_ci,
  #          :idioma_id => idioma_id,
  #          :tipo_categoria_id => tipo_categoria_id).limit(1).first
  #         @estudiante_curso = ec
  #       else
  #         @estudiante_curso = EstudianteCurso.new
  #         @estudiante_curso.usuario_ci = usuario_ci
  #         @estudiante_curso.idioma_id = idioma_id
  #         @estudiante_curso.tipo_categoria_id = tipo_categoria_id
  #         @estudiante_curso.tipo_convenio_id = "REG"
  #         @estudiante_curso.save!
  #       end
  #     else
  #       @estudiante = Estudiante.new
  #       @estudiante.usuario_ci = usuario_ci
  #       @estudiante.save!

  #       @estudiante_curso = EstudianteCurso.new
  #       @estudiante_curso.usuario_ci = usuario_ci
  #       @estudiante_curso.idioma_id = idioma_id
  #       @estudiante_curso.tipo_categoria_id = tipo_categoria_id
  #       @estudiante_curso.tipo_convenio_id = "REG"
  #       @estudiante_curso.save!
  #     end
  #   else
  #     @usuario = Usuario.new
  #     @usuario.ci = usuario_ci
  #     @usuario.nombres = ""
  #     @usuario.apellidos = ""
  #     @usuario.telefono_movil = ""
  #     @usuario.fecha_nacimiento = "1990-01-01"
  #     @usuario.save! :validate => false

  #     @estudiante = Estudiante.new
  #     @estudiante.usuario_ci = usuario_ci
  #     @estudiante.save!

  #     @estudiante_curso = EstudianteCurso.new
  #     @estudiante_curso.usuario_ci = usuario_ci
  #     @estudiante_curso.idioma_id = idioma_id
  #     @estudiante_curso.tipo_categoria_id = tipo_categoria_id
  #     @estudiante_curso.tipo_convenio_id = "REG"
  #     @estudiante_curso.save!


  #   end
  #   session[:usuario] = @usuario
  #   session[:estudiante] = @estudiante
  #   session[:rol] = @estudiante_curso.descripcion
  #   session[:tipo_curso] = @tipo_curso
  #   info_bitacora "Paso 0 realizado en #{@tipo_curso.descripcion}"
  #   redirect_to :action => "paso1"
  #   return
  # end


end
