# encoding: utf-8

class UsuarioController < ApplicationController
  before_action :filtro_logueado
  before_action :filtro_super_administrador, :except => ['modificar', 'modificar_guardar', 'contrasena', 'contrasena_guardar']

  def bitacora
    if session[:administrador].tipo_rol_id > 3
      flash[:mensaje] = "Ud. No dispone de privilegios suficientes para ver esta página"
      info_bitacora "Intento de acceso a bitacora de usuario ci= #{params[:id]}"
      redirect_to :back
    else
      @titulo_pagina = "Info Bitácora"
      ci = params[:id]
      @bitacoras = Bitacora.all(:conditions => ["descripcion LIKE ? OR usuario_ci LIKE ? OR estudiante_usuario_ci LIKE ? OR administrador_usuario_ci LIKE ?",ci,ci,ci,ci],:limit => 100, :order => 'fecha DESC' ) if session[:administrador].tipo_rol_id <= 3
    end
  end

  def bloquear
    begin
      usuario = Usuario.find params[:id]
      usuario.activo = params[:activo]
      usuario.save
      flash[:mensaje] = "Usuario #{usuario.estado_bloqueo}"
      info_bitacora "Usuario #{usuario.estado_bloqueo}: #{usuario.descripcion}. Momento: #{Time.now}"
    rescue Exception => e
      flash[:mensaje] = "No fue posible bloquear al Usuario. Error del sistema: #{e}"
    end
    redirect_to :back
    
  end

  def nuevo
    if session[:administrador].tipo_rol_id > 2 
      flash[:mensaje] = "Usted no posee los privilegios para acceder a esta función"
      redirect_to :action => 'index'
    end
    @titulo_pagina = "Agregar Usuario"
    @usuario = Usuario.new
    @controlador = params[:controlador]
    @accion = params[:accion]
  end

  def nuevo_guardar
    usuario = Usuario.new(params[:administrador])
    if usuario.save
      flash[:mensaje] = "Actualización Correcta"
    else
      flash[:mensaje] = "No se pudo actualizar"
    end
    redirect_to :controller => 'adminstrador', :action => 'index'     
  end

  def modificar
    if session[:administrador] and session[:administrador].tipo_rol_id > 2 
      flash[:mensaje] = "Usted no posee los privilegios para acceder a esta función"
      redirect_to :action => 'index'
    end
    @usuario = session[:usuario] 
    @controlador = params[:controlador]
    @accion = params[:accion]
  end
  
  def modificar_guardar
    controlador = params[:controlador]
    accion = params[:accion]
    usr = params[:usuario]

    @usuario = session[:usuario]

    @usuario.ultima_modificacion_sistema = Time.now
    @usuario.nombres = usr[:nombres]
    @usuario.apellidos = usr[:apellidos]
    @usuario.correo = usr[:correo]
    @usuario.tipo_sexo_id = usr[:tipo_sexo_id]
    @usuario.telefono_movil = usr[:telefono_movil]
    @usuario.fecha_nacimiento = usr[:fecha_nacimiento]
    @usuario.telefono_habitacion = usr[:telefono_habitacion]
    @usuario.direccion = usr[:direccion]
    respond_to do |format|
       p "<#{controlador} #{accion}>"
      if @usuario.save
        info_bitacora "datos personales cambiados"
        flash[:mensaje] = "Datos Personales Actualizados Satisfactoriamente"
        
        format.html { redirect_to(:controller=> controlador, :action=>accion) }
      else
        flash[:mensaje] = "Errores en el formulario impiden completar la acción: #{@usuario.errors.full_messages.join(" | ")}"        
        format.xml  { render :xml => @usuario.errors, :status => :unprocessable_entity }
      end
        format.html { redirect_to(:controller=> controlador, :action=>accion) }      
    end
    
  end
  
  def contrasena
    @usuario = session[:usuario] 
    @controlador = params[:controlador]
    @accion = params[:accion]
    p @controlador
    @controlador = controller_name unless @controlador
    p @controlador
  end
  
  def contrasena_guardar
    controlador = params[:controlador]
    accion = params[:accion]
    usr = params[:usuario]
    @usuario = session[:usuario]
    @usuario.ultima_modificacion_sistema = Time.now
    @usuario.contrasena = usr[:contrasena]
    @usuario.contrasena_confirmation = usr[:contrasena_confirmation]

    respond_to do |format|
     
      if @usuario.save
        info_bitacora "contraseña cambiada"
        flash[:mensaje] = "Contraseña Actualizado Satisfactoriamente"
        format.html { redirect_to(:controller=> controlador, :action=>accion) }
      else
        format.xml  { render :xml => @usuario.errors, :status => :unprocessable_entity }
        
        format.html { render :action => "contrasena"}
      end
    end
    
  end

  def cambiar_cedula
    parametros = params[:parametros]
    @controlador = parametros["controlador"]
    @accion = parametros["accion"]
    render :layout => false
  end

  def cambiar_cedula_guardar
    controlador = params[:controlador]
    accion = params[:accion]
    
    if controlador == "admin_estudiante"
      usuario_ci = session[:estudiante].usuario_ci
    elsif controlador == "admin_instructor"
      usuario_ci = session[:instructor_ci]
    else
      usuario_ci = session[:usuario].ci
    end
    if !params[:cedula] || params[:cedula] == "" || !params[:repetir_cedula] || params[:repetir_cedula] == ""
      flash[:mensaje] = "Debe completar todos los campos para el cambio de cédula"
      redirect_to :controller => controlador, :action => accion
      return
    end

    if params[:cedula] != params[:repetir_cedula]
      flash[:mensaje] = "Las cédulas deben ser iguales"
      redirect_to :controller => controlador, :action => accion
      return
    end

    if Usuario.where(:ci => params[:cedula]).size > 0
      flash[:mensaje] = "Ya existe un usuario registrado con esa cédula"
      redirect_to :controller => controlador, :action => accion
      return
    else
      begin
        cedula = Integer(params[:cedula])
        connection = ActiveRecord::Base.connection()
        sql = "update usuario set ci = '#{cedula}' where ci = '#{usuario_ci}';"
        connection.execute(sql)
        info_bitacora("Cambio de cédula de #{usuario_ci} a #{cedula}")
        if controlador == "admin_estudiante"
          session[:estudiante] = Estudiante.where(:usuario_ci => cedula).limit(0).first
          session[:estudiante_ci] = session[:estudiante].usuario_ci
        elsif controlador == "admin_instructor"
          session[:instructor] = Instructor.where(:usuario_ci => cedula).limit(0).first
          session[:instructor_ci] = session[:instructor].usuario_ci
        else
          session[:usuario] = Usuario.where(:ci => cedula).limit(0).first
        end
        
        flash[:mensaje] = "Cédula actualizada satisfactoriamente"
        redirect_to :controller => controlador, :action => accion
        return
      rescue Exception => e
        flash[:mensaje] = "La cédula debe ser un número. Error del Sistema #{e}"
        redirect_to :controller => controlador, :action => accion
        return
      end
    end

  end

  def resetear_contrasena
    @usuario = Usuario.where(:ci =>params[:ci]).limit(1).first
    @usuario.contrasena = @usuario.ci
    
    if @usuario.save
      info_bitacora("Contraseña reseteada, estudiante: #{@usuario.ci}")
      AdministradorMailer.aviso_general("#{@usuario.correo}","Su Contraseña fue Reseteada II", "su contraseña fue reseteada, ahora es:#{@usuario.contrasena}. Si ud. no solicitó este servicio dirijase a nuestras oficinas a fin de aclarar la situación").deliver
      flash[:mensaje] = "Contraseña reseteada corréctamente, un correo electrónico con la información fue enviado a la cuenta de correo del estudiante"
    else
      flash[:mensaje] = "no se pudo resetear la contraseña"
    end
    redirect_to :back
    
  end  

end