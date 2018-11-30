class InicioController < ApplicationController
# encoding: utf-8
# 10264009 Carlos
# 14519813 Joyce
# 81738607 Lucius
# layout "visitante"
  
  def index
		reg = ContenidoWeb.where(:id => 'INI_CONTENT').first
    @content = reg.contenido
    @tipo_cursos = TipoCurso.where("idioma_id != 'OR' or idioma_id != 'BBVA' or idioma_id != 'NI'")

    @nivelaciones = TipoInscripcion.where(id: 'NI').first.inscripciones.order('apertura')

    @cursos_abiertos_nuevo = Inscripcion.where(tipo_inscripcion_id: 'NU', tipo_estado_inscripcion_curso_id: 'AB')

    @periodo_inscripcion_id = ParametroGeneral.periodo_inscripcion.id

    @inscripcion_activa = ParametroGeneral.horario_inscripcion_activo

    @titulo = ParametroGeneral.horario_inscripcion_activo
    @titulo = "Semanal y Sabatino" if(@titulo.eql? 'AMBOS')
    @titulo = "" if @titulo.eql? 'NINGUNO'
  end
  
  def validar  
    unless params[:usuario]
      redirect_to :action => "index"
      return
    end

    ci = params[:usuario][:cedula]
    login = params[:usuario][:cedula]
    clave = params[:usuario][:clave]     
    reset_session

    if usuario = Usuario.autenticar(login,clave)
      session[:usuario_ci] = usuario.ci
      roles = []
      roles << "Administrador" if usuario.administrador
      roles << "Instructor" if usuario.instructor
      ests = EstudianteCurso.where(:usuario_ci => login)
      ests.each{ |ec|
        roles << "Estudiante"
      }
      niv = EstudianteNivelacion.where(:usuario_ci=>login)

      niv.each{ |ec|
        roles << "Nivelacion"
      }

      if roles.size == 0
        info_bitacora "No tiene roles el usuario #{login}"
        flash[:danger] = "Usuario sin rol"
        redirect_to :action => "index"          
        return
      elsif roles.size == 1 
        cargar_parametros_generales   
        redirect_to :action => "un_rol", :tipo => roles.first
        return
      else   
        info_bitacora "Tiene mas de un rol el usuario #{login}"
        cargar_parametros_generales   
        flash[:warning] = "Usted tiene más de un rol, debe seleccionar un rol"
        redirect_to :action => "seleccionar_rol"
        return
      end
    end           

    @usuario = Usuario.where(:ci => login).first

    if @usuario and !@usuario.activo
      flash[:danger] = "Usuario Bloqueado. Las Autoridades sarán notificadas de su intento de ingreso."
    end

    info_bitacora "Error en el login o clave #{login}"
    flash[:danger] = "Error en cédula o contraseña"

    redirect_to :action => "index"
  end  
  
  def seleccionar_rol
    usuario_ci = session[:usuario_ci]
    usuario = Usuario.find(usuario_ci)
    @roles = []
    @roles << { :tipo => "Administrador", :descripcion => "Administrador"} if usuario.administrador
    @roles << { :tipo => "Instructor", :descripcion => "Instructor"} if usuario.instructor

    usuario.estudiante_cursos.each{|ec|
      @roles << { 
        :tipo => "Estudiante",
        :descripcion => ec.descripcion,
        :tipo_categoria_id => ec.tipo_categoria_id,
        :idioma_id => ec.idioma_id
      }
    }

    usuario.nivelaciones.each{|n|
      @roles << {
        :tipo => "Nivelacion",
        :descripcion => n.descripcion_con_periodo,
        :tipo_categoria_id => n.tipo_categoria_id,
        :idioma_id => n.idioma_id
      }
    }

  end 
  
  def un_rol 
    tipo = params[:tipo]
    usuario_ci = session[:usuario_ci]
    usuario = Usuario.find(usuario_ci)
    if tipo ==  "Administrador" && usuario.administrador
      session[:rol] = tipo
      session[:administrador_ci] = usuario.administrador.usuario_ci 
      info_bitacora "Inicio de sesion del adminitrador"
      redirect_to :controller => "principal_admin"
      return
    elsif tipo ==  "Instructor" && usuario.instructor
      session[:rol] = tipo
      session[:instructor_ci] = usuario.instructor.ci 
      info_bitacora "Inicio de sesion del instructor"
      redirect_to :controller => "principal_instructor"
      return  
    elsif tipo ==  "Estudiante"
      ec = nil
      if params[:tipo_categoria_id] && params[:idioma_id]
        ec = EstudianteCurso.where(
          :usuario_ci => usuario.ci,
          :tipo_categoria_id => params[:tipo_categoria_id],
          :idioma_id => params[:idioma_id]).limit(1).first
      else
        ec = EstudianteCurso.where(
          :usuario_ci => usuario.ci).limit(1).first
      end
      if ec      
        session[:estudiante] = usuario.estudiante
        session[:rol] = ec.descripcion
        session[:tipo_curso] = ec.tipo_curso  
        info_bitacora "Inicio de sesion del estudiante"
        redirect_to :controller => "principal"
        return
      end
    elsif tipo ==  "Nivelacion"
      en = nil
      if params[:tipo_categoria_id] && params[:idioma_id]
        en = EstudianteNivelacion.where(
          :usuario_ci => usuario.ci,
          :tipo_categoria_id => params[:tipo_categoria_id],
          :idioma_id => params[:idioma_id]).limit(1).first
      else
        en = EstudianteNivelacion.where(
          :usuario_ci => usuario.ci).limit(1).first
      end
      if en      
        session[:estudiante] = usuario.estudiante
        session[:rol] = en.descripcion
        session[:tipo_curso] = en.tipo_curso  
        info_bitacora "Inicio de sesion del estudiante nivelacion"
        redirect_to :controller => "principal"
        return
      end
    end



    flash[:mensaje_login] = "Inicio inválido"
    redirect_to :action => "index"
    return
  end
  
  def cerrar_sesion
    reset_session
    redirect_to :action => "index", :controller => "inicio"
  end 
  
  def autenticacion_nuevo
    #redirect_to :action => "paso0", :controller => "inscripcion"
  end
  
  def validar_nuevo
    unless params[:usuario]
      redirect_to :action => "index"
      return
    end
    usuario = params[:usuario][:usuario]
    clave = params[:usuario][:clave]   
    
    if usuario == "new" && clave == "coursesa12" || usuario == "invitado" && clave == "invitado"
      redirect_to :action => "paso0", :controller => "inscripcion"
    else
      flash[:error] = "Datos Inválidos"
      redirect_to :action => "autenticacion_nuevo"
    end
  end

  def olvido_clave_guardar
    cedula = params[:usuario][:ci]
    usuario = Usuario.where(:ci => cedula).limit(0).first
    if usuario
      EstudianteMailer.olvido_clave(usuario).deliver  
      info_bitacora "El usuario #{usuario.descripcion} olvido su clave y la pidio recuperar"
      flash[:mensaje] = "Se ha enviado la clave al correo: #{usuario.correo}. Favor revise en su carpeta de Spam de no encontrar el correo en su bandeja."
      redirect_to :action => :index
    else
      flash[:mensaje] = "Usuario no registrado"
      redirect_to :action => :olvido_clave
    end
    
  end


  def clave_set_ci_guardar
    cedula = params[:usuario][:ci]
    usuario = Usuario.where(:ci => cedula).limit(0).first
    if usuario
      usuario.contrasena = usuario.ci
      usuario.save
      info_bitacora "Se le asigno la ci por contrasena al usuario #{usuario.descripcion}."
      flash[:mensaje] = "Su contraseña es ahora su cédula."
      redirect_to :action => :index
    else
      flash[:mensaje] = "Usuario no registrado"
      redirect_to :action => :olvido_clave
    end
    
  end


end
