#encoding: utf-8

class PrincipalAdminController < ApplicationController
  before_action :filtro_logueado
  before_action :filtro_administrador

  def index
    if params[:ci]
      flash[:mensaje] = "Correo enviado satisfactoriamente"
    end
    @titulo_pagina = "Opciones del administrador"
    session[:instructor_ci] = nil
    session[:estudiante_ci] = nil
    session[:especial_usuario] = nil
    session[:especial_estudiante] = nil
    session[:especial_rol] = nil
    session[:especial_tipo_curso] = nil
    
    @admin = Administrador.find session[:administrador_ci]

    # @cursos = Curso.where(:tipo_categoria_id => 'AD').order(:grado).delete_if{|c| c.tipo_nivel_id.eql? "CC" or c.tipo_nivel_id.eql? "NI" or c.tipo_nivel_id.eql? "BBVA";}.sort_by{|c| "#{c.idioma_id} #{c.grado}"}

    @cursos = Curso.where( "tipo_categoria_id = 'AD' and tipo_nivel_id != 'CC' and tipo_nivel_id != 'NI' and tipo_nivel_id != 'BBVA' ").order([:idioma_id, :grado])
  end
  
  def estado_instructores
    @titulo_pagina = "Estado de los Instructores"
    
    notificados = NotificacionCalificacion.where(:periodo_id => session[:parametros][:periodo_calificacion],
                                                 :correo_enviado => true).collect{|n| n.usuario_ci}
                                                 
    @instructores= Seccion.where("periodo_id = ? AND esta_abierta = ?", session[:parametros][:periodo_calificacion],1).collect{|x| x.instructor}.uniq.compact.sort_by{|i| "#{i.estado} #{i.fecha_que_califico(session[:parametros][:periodo_calificacion])}"}
    @instructores = @instructores.delete_if{|x| notificados.index x.usuario_ci}
    @instructores_notificados = Instructor.where(:usuario_ci => notificados).sort_by{|x| x.fecha_notificacion(session[:parametros][:periodo_calificacion])}
  end
  
  def enviar_notificaciones
    no_notificados = NotificacionCalificacion.where(:periodo_id => session[:parametros][:periodo_calificacion],
                                                 :correo_enviado => false).collect{|n| n.usuario_ci}
    @instructores_no_notificados = Instructor.where(:usuario_ci => no_notificados)
    @texto = ""
    @instructores_no_notificados.each{ |ins|
      cantidad = 39 - ins.nombre_completo.size
      @texto = @texto + "#{ins.nombre_completo}"
      cantidad.times{|can|
        @texto+= " "
      }
       @texto += "CI: #{ins.usuario_ci} \n"
    }
    @texto = @texto.strip
    render :layout => false
  end
  
  def enviar_correos
    no_notificados = NotificacionCalificacion.where(:periodo_id => session[:parametros][:periodo_calificacion],
                                                 :correo_enviado => false).collect{|n| n.usuario_ci}
    @instructores_no_notificados = Instructor.where(:usuario_ci => no_notificados).sort_by{|x| x.usuario.nombre_completo}
    texto = "Se notificó a los siguientes instructores: "
    @instructores_no_notificados.each{ |ins|
      ins.guardar_notificacion(session[:parametros][:periodo_calificacion])
      texto += "#{ins.nombre_completo} ci: #{ins.usuario_ci} --- "
    }
    AdministradorMailer.enviar_notificacion(@instructores_no_notificados).deliver
    flash[:mensaje] = "El correo se ha enviado satisfactoriamente"
    info_bitacora(texto)
    redirect_to :action => "estado_instructores"
  end
  
  def habilitar_honorarios
    candidatos = NotificacionCalificacion.where(:periodo_id => session[:parametros][:periodo_calificacion]).collect{|n| n.usuario_ci}
    instructores= Seccion.where("periodo_id = ? AND esta_abierta = ?", session[:parametros][:periodo_calificacion],1).collect{|x| x.instructor}.uniq.delete_if{|x| candidatos.index x.usuario_ci}
    p instructores
    
  end

  def capturar_ci
  end
  
  def confirmacion_rapida
    ci = params[:historial][:usuario_ci]
    periodo_actual=session[:parametros][:periodo_actual]
    periodo_actual_sabatino = ParametroGeneral.periodo_actual_sabatino
    cursos = EstudianteCurso.where(:usuario_ci=>ci)
    
    if cursos.size<1
      flash[:mensaje]="Cédula no encontrada"
      redirect_to :action => "capturar_ci"
      return
    end
    if cursos.size>1
      flash[:mensaje]="Tiene varios idiomas, debe hacerlo por gestionar estudiante"
      redirect_to :action => "validar", :controller => "admin_estudiante", :usuario => {:ci => ci}
      return
    end    
    @historial = cursos.first.ultimo_historial
    if @historial.periodo_id!=periodo_actual or @historial.periodo_id!=periodo_actual_sabatino.id
      flash[:mensaje]="No está preinscrito en ningún periodo actual "
      redirect_to :action => "capturar_ci"
      return
    end
    if @historial.tipo_estado_inscripcion_id!="PRE"
      flash[:mensaje]="Ya está confirmado"
      redirect_to :action => "capturar_ci"
      return
    end
    
  end
  
  def confirmacion_rapida_guardar
    idioma_id = params[:historial][:idioma_id]
    tipo_categoria_id = params[:historial][:tipo_categoria_id]
    tipo_nivel_id = params[:historial][:tipo_nivel_id]
    ci = params[:historial][:usuario_ci]
    periodo = params[:historial][:periodo_id]
    #periodo = session[:parametros][:periodo_actual]
    depositos = HistorialAcademico.where(periodo_id: periodo).collect{|h| h.numero_deposito}
    unless params[:historial][:numero_deposito].eql? ""
      if depositos.include? params[:historial][:numero_deposito].to_s
        flash[:mensaje]="Número de depósito ya usado para este período"
        respond_to :action=>"capturar_ci"
      else
        @historial = HistorialAcademico.where(:periodo_id=>periodo, :idioma_id=>idioma_id, :tipo_categoria_id=>tipo_categoria_id, :usuario_ci=>ci, :tipo_nivel_id=>tipo_nivel_id).limit(1).first
        @historial.tipo_estado_inscripcion_id = "INS"
        @historial.numero_deposito = params[:historial][:numero_deposito]
        @historial.tipo_transaccion_id = params[:historial][:tipo_transaccion_id]
        @historial.cuenta_bancaria_id = params[:historial][:cuenta_bancaria_id]
    
        if @historial.save
          info_bitacora("Confirmación de Curos: #{@historial.curso.descripcion}")
          flash[:mensaje]="Confirmacion de Inscripcion Exitosa"
          redirect_to :action=> "capturar_ci"
        else
          flash[:mensaje]="No se pudo confirmar la seccion"
          redirect_to :action=> "capturar_ci"
        end
      end
    else
      flash[:mensaje]="Debe agregar un numero de depósito"
      respond_to :action=>"capturar_ci"
    end
  end
  
  def redactar_correo
    @titulo_pagina = "Enviar Correo a Instructores"
    @instructor = Instructor.all.delete_if{|i| i.seccion_periodo.count < 1}
    @instructor = @instructor.sort_by{|i| i.usuario.nombre_completo}
    
  end
  
  def enviar_correo
    titulo = params[:correo][:titulo]
    #1/0
    seleccion = params[:seleccion]
    contenido = params[:correo][:contenido]
    intructores_ci = []
    seleccion.each do |s|
      intructores_ci << s.at(0) if s.at(1).eql? "1"
    end
    
    instructores = Instructor.where(:usuario_ci=>intructores_ci)
    #mail=[]
    #instructores.each do |i|
    mail = AdministradorMailer.aviso_general(instructores.collect{|i| "<"+i.usuario.correo+">"},titulo,contenido).deliver
    #end 
    if mail
      info_bitacora("correo enviado a instructores: #{titulo}")
      flash[:mensaje] = "se ha enviado el correo a los instructores seleccionadas" 
    else
      flash[:mensaje] = "en estos momentos no es posible efectuar el envío de correos" 
    end
    redirect_to :action=>"redactar_correo"
  end
  
  def generar_carnets
    consulta = Seccion.where(:periodo_id=>session[:parametros][:periodo_actual],:esta_abierta => true)
    secciones = []
    consulta.each{|s|
      aula = s.horario_seccion2.aula
      secciones << s if aula && aula.tipo_ubicacion_id == 'ING' #&& s.horario_seccion.first.tipo_dia_id == 'SA'
    }          
          
    consulta = secciones.delete_if{|x| x.instructor == nil}.collect{|x| x.instructor}.uniq

    if consulta.size == 0
      flash[:mensaje] = "Actualmente no hay instructores asignados en el edificio de Ingeniería los días sábados"
      redirect_to :action => :index
      return
    end
    
    consulta = consulta.sort_by{|x| x.usuario.nombre_completo}
    pdf = DocumentosPDF.generar_carnets_instructores(consulta,session[:parametros][:periodo_actual])
    send_data pdf.render,:filename => "carnet_instructores.pdf",:type => "application/pdf", :disposition => "attachment"
  end

  def cargar_pdf
    @idioma_id = params[:idioma_id]
    @nivel_id = params[:nivel_id]
  end


  def actualizar_pdf
    begin
      data = params[:archivo][:datafile].tempfile
      archivo = "#{params[:idioma_id]}/#{params[:nivel_id]}.pdf"
      File.open("#{Rails.root}/attachments/syllabus/#{archivo}", "wb") {|file| file.write data.read}
      flash[:mensaje] = "Archivo '#{archivo}' Actualizado."
    rescue Exception => e
      flash[:mensaje] = "Error: #{e.message}"
    end
    redirect_to :action => 'index'
  end
  
end
