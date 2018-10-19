#encoding: utf-8

class AdminEstudianteController < ApplicationController

  before_action :filtro_logueado
  before_action :filtro_administrador

  def index
    
  end     


  def estudiantes
    @estudiantes_total = Estudiante.all.count

    @total_estudiantes = Hash.new()
    Idioma.all.each do |idioma|
      case idioma.id
      when 'IN'
        @total_estudiantes["IN-AD"] = "#{idioma.descripcion.capitalize}-Adultos(#{EstudianteCurso.where(:idioma_id => idioma.id, :tipo_categoria_id => "AD").count})"
        @total_estudiantes["IN-NI"] = "#{idioma.descripcion.capitalize}-Niños(#{EstudianteCurso.where(:idioma_id => idioma.id, :tipo_categoria_id => "NI").count})"
        @total_estudiantes["IN-TE"] = "#{idioma.descripcion.capitalize}-Teens(#{EstudianteCurso.where(:idioma_id => idioma.id, :tipo_categoria_id => "TE").count})"
      when 'OR'
        # @total_estudiante[idioma.id] = "Otros (#{Estudiante.all.delete_if{|e| e.estudiante_cursos.count > 0}.count})"
        @total_estudiantes['OR'] = "Otros (#{EstudianteCurso.where('idioma_id <> ? and idioma_id <> ? and idioma_id <> ? and idioma_id <> ? and idioma_id <> ?', 'IN', 'AL', 'FR', 'IT', 'PG').count})"
      else
        @total_estudiantes[idioma.id] = "#{idioma.descripcion.capitalize} (#{EstudianteCurso.where(:idioma_id => idioma.id).count})"
      end
    end
    if params[:id]
      if params[:id].include? "IN"
        idioma_id = (params[:id].split"-").first
        tipo_categoria_id = (params[:id].split"-").second

        @estudiantes_cursos = EstudianteCurso.where(:idioma_id => idioma_id, :tipo_categoria_id => tipo_categoria_id).limit(1000)
      else
        @estudiantes_cursos = EstudianteCurso.where(:idioma_id => params[:id])      
      end

      @estudiantes = Estudiante.all.delete_if{|e| e.estudiante_cursos.count > 0} if params[:id].eql? 'OR'
      @id = params[:id]
    end
  end


  def limpiar_lista_estudiantes
    eliminar_estudiantes_cursos_vacios
    total_eliminados = 0
    con_otro_rol = 0
    Estudiante.all.each do |estudiante|
      if estudiante.estudiante_cursos.count.eql? 0
        u = estudiante.usuario
        if u.administrador.nil? and u.instructor.nil? 
          u.destroy
          total_eliminados +=1 if estudiante.destroy
        else
          con_otro_rol += 1
        end
      end
    end

    flash[:mensaje] += "#{total_eliminados} Estudiantes (Usuarios) elimininados. Existen #{con_otro_rol} Estudiantes que no han sido eliminados ya que tienen otro rol como Administrador o Instructor."
    redirect_to :action => "estudiantes"
  end

  def eliminar_estudiante
    @estudiante = Estudiante.find(params[:ci]) 
    @estudiante.estudiante_cursos.each do |ec|
      ec.historiales_academicos.each do |historial|
        historial.destroy
      end
      ec.destroy
    end
    u = @estudiante.usuario
    if u.administrador.nil? and u.instructor.nil? 
      u.destroy
    else
      @estudiante.destroy
    end
    # usuario = @estudiante.usuario
    # usuario.destroy
    
    flash[:mensaje] = "Usuario eliminado con éxito"
    redirect_to :action =>"estudiantes", :id => params[:id]
  end


=begin
def autocomplete
  term = params[:term]                                                
  busqueda = "#{term}%"
  usuarios = Usuario.all(
    :conditions => ["nombres LIKE ? OR apellidos LIKE ? OR ci LIKE ?",busqueda,busqueda,busqueda],
    :limit => 50, :order => "apellidos, nombres, ci")
  render :text => usuarios.collect{|x| {:label => x.descripcion, :value => x.ci }}.to_json  
end
=end  
  def autocomplete
    term = params[:term] 
    a,b = term.split
    busqueda_a = "#{a}%"
    
    if b
      busqueda_b = "#{b}%"
      usuarios = Usuario.all(
        :conditions => ["(nombres LIKE ? OR apellidos LIKE ? OR ci LIKE ?) AND \
          (nombres LIKE ? OR apellidos LIKE ? OR ci LIKE ?)",
          busqueda_a,busqueda_a,busqueda_a,
          busqueda_b,busqueda_b,busqueda_b
          ],
        :limit => 50, :order => "apellidos, nombres, ci")
      render :text => usuarios.collect{|x| {:label => x.descripcion, :value => x.ci }}.to_json  
      return
    else                                               
      usuarios = Usuario.all(
        :conditions => ["nombres LIKE ? OR apellidos LIKE ? OR ci LIKE ?",busqueda_a,busqueda_a,busqueda_a],
        :limit => 50, :order => "apellidos, nombres, ci")
      render :text => usuarios.collect{|x| {:label => x.descripcion, :value => x.ci }}.to_json  
      return
    end
  end
  
  def validar
    ci = params[:usuario][:ci]    
    if session[:estudiante]=Estudiante.where(:usuario_ci=>ci).limit(1).first
      session[:estudiante_ci] = ci
      redirect_to :action=> "opciones_menu"
    else
      flash[:mensaje]="Estudiante no encontrado"
      redirect_to :action=> "index"
    end
  end
  
  def opciones_menu
    @ci = session[:estudiante_ci] 
    periodo_actual = [ParametroGeneral.periodo_actual.id, ParametroGeneral.periodo_actual_sabatino.id]
    @usuario = Usuario.where(:ci=>@ci).limit(1).first
    @historial = HistorialAcademico.where(:usuario_ci=>@ci).sort_by{|x| "#{x.periodo.ano} #{x.periodo.id}"}.reverse
    @historial_actual = HistorialAcademico.where(:usuario_ci=>@ci, :periodo_id=>periodo_actual)
    @estudiante_curso = EstudianteCurso.where(:usuario_ci=>@ci)
    @nivelaciones = EstudianteNivelacion.where(:usuario_ci=>@ci)
    @titulo_pagina = "Modificar Estudiante: #{@usuario.descripcion}" if @usuario
    flash[:mensaje] = "Estudiante Bloqueado" unless @usuario and @usuario.activo
    @estudiante_examenes = EstudianteExamen.joins(:examen).where('estudiante_examen.estudiante_ci' => @ci, "examen.periodo_id" => periodo_actual)


  end
  
  def cambiar_convenio_sel_curso
    periodo = [session[:parametros][:periodo_actual], ParametroGeneral.periodo_actual_sabatino.id]
    ci = session[:estudiante_ci]
    @usuario = Usuario.where(:ci=>ci).limit(1).first
    @cursos = EstudianteCurso.where(:usuario_ci => ci).collect{|c| c.tipo_curso}
    @titulo_pagina = "Modificar Estudiante: #{@usuario.descripcion}"
    @subtitulo_pagina = "Seleccione el Curso"
  end
  
  def cambiar_convenio
    idioma_id,tipo_categoria_id = params[:parametros][:tipo_curso].split(",")
    ci = params[:parametros][:usuario_ci]
    @estudiante_curso= EstudianteCurso.where(:usuario_ci=>ci,:idioma_id=>idioma_id,:tipo_categoria_id=>tipo_categoria_id).limit(1).first
    render :layout => false
  end

  def cambiar_convenio_guardar
    tipo_convenio_id = params[:estudiante_curso][:tipo_convenio_id]
    periodo = session[:parametros][:periodo_actual]
    idioma_id = params[:estudiante_curso][:idioma_id]
    tipo_categoria_id = params[:estudiante_curso][:tipo_categoria_id]
    ci = params[:estudiante_curso][:usuario_ci]
    estudiante_curso= EstudianteCurso.where(:usuario_ci=>ci,
    :idioma_id=>idioma_id, 
    :tipo_categoria_id=>tipo_categoria_id).limit(1).first
    
    if estudiante_curso.tipo_convenio_id != tipo_convenio_id
      historial = HistorialAcademico.where(:usuario_ci=>ci,
        :idioma_id=>idioma_id, 
        :tipo_categoria_id=>tipo_categoria_id, 
        :periodo_id=>periodo).limit(1).first
      estudiante_curso.tipo_convenio_id = tipo_convenio_id
      
      if historial
        historial.tipo_convenio_id = tipo_convenio_id
        historial.save
      end
    
      if estudiante_curso.save
        info_bitacora("Convenio modificado: #{estudiante_curso.tipo_convenio.descripcion}")
        flash[:mensaje]="convenio actualizado"
        redirect_to :action=>"opciones_menu"
      else
        flash[:mensaje]="no se pudo actualizar"
        redirect_to :action=> "cambiar_convenio"
      end
    else
      info_bitacora("Intento de modificar convenio - se mantiene el convenio: #{estudiante_curso.tipo_convenio.descripcion}")
      flash[:mensaje]="se mantiene el convenio"
      redirect_to :action=>"opciones_menu"
    end
  end
  
  def modificar_datos_personales
    if session[:administrador].tipo_rol_id > 3 
      flash[:mensaje] = "Usted no posee los privilegios para acceder a esta función"
      redirect_to :action => 'index'
    end
    ci = session[:estudiante_ci]
    p ci
    @usuario = Usuario.where(:ci=>ci).limit(1).first
    p @usuario
    @accion = "validar_datos"
  end
  
  def modificar_datos_personales_guardar 
    usr = params[:usuario]
    @usuario = Usuario.where(:ci=>usr[:ci]).limit(1).first
    @usuario.nombres = usr[:nombres]
    @usuario.apellidos = usr[:apellidos]
    @usuario.tipo_sexo_id = usr[:tipo_sexo_id]
    @usuario.fecha_nacimiento = usr[:fecha_nacimiento]
    @usuario.correo = usr[:correo]
    @usuario.telefono_movil = usr[:telefono_movil]
    @usuario.telefono_habitacion = usr[:telefono_habitacion]
    @usuario.direccion = usr[:direccion]
    
    respond_to do |format|
      if @usuario.save
        info_bitacora("Datos personales modifcados")
        flash[:mensaje] = "Estudiante Actualizado Satisfactoriamente"
        format.html { redirect_to(:action=>"opciones_menu") }
      else
        flash[:mensaje] = "Errores en el Formulario impiden que el estudiante sea actualizado"
        format.html { render :action => "modificar_datos_personales" }
        format.xml  { render :xml => @usuario.errors, :status => :unprocessable_entity }
      end
    end
  end

  def cambiar_cedula_estudiante
    render :layout => false
  end

  def cambiar_cedula_estudiante_guardar
    if !params[:cedula] || params[:cedula] == "" || !params[:repetir_cedula] || params[:repetir_cedula] == ""
      flash[:mensaje] = "Debe completar todos los campos para el cambio de cédula"
      redirect_to :action => :modificar_datos_personales
      return
    end

    if params[:cedula] != params[:repetir_cedula]
      flash[:mensaje] = "Las cédulas deben ser iguales"
      redirect_to :action => :modificar_datos_personales
      return
    end

    if Usuario.where(:ci => params[:cedula]).size > 0
      flash[:mensaje] = "Ya existe un estudiante registrado con esa cédula"
      redirect_to :action => :modificar_datos_personales
      return
    else
      begin
        cedula = Integer(params[:cedula])
        connection = ApplicationRecord.connection()
        sql = "update usuario set ci = '#{cedula}' where ci = '#{session[:estudiante].usuario_ci}';"
        connection.execute(sql)
        info_bitacora("Cambio de cédula de #{session[:estudiante].usuario_ci} a #{cedula}")
        session[:estudiante] = Estudiante.where(:usuario_ci => cedula).limit(0).first
        session[:estudiante_ci] = session[:estudiante].usuario_ci
        flash[:mensaje] = "Cédula actualizada satisfactoriamente"
        redirect_to :action => :modificar_datos_personales
        return
      rescue Exception => e
        flash[:mensaje] = "La cédula debe ser un número. Error del Sistema: #{e}"
        redirect_to :action => :modificar_datos_personales
        return
      end
    end

  end
  
  def cambiar_seccion_sel_curso
    ci = session[:estudiante_ci]
    @usuario = Usuario.where(:ci=>ci).limit(1).first
    @cursos = EstudianteCurso.where(:usuario_ci => ci).collect{|c| c.tipo_curso}
    @titulo_pagina = "Modificar Estudiante: #{@usuario.descripcion}"
    @subtitulo_pagina = "Seleccione el Curso"
  end
  
  def cambiar_seccion
    p=params[:parametros]
    #periodo = session[:parametros][:periodo_actual]
    periodo_id = p[:periodo_id]#session[:parametros][:periodo_actual]
    idioma_id = p[:idioma_id]
    tipo_categoria_id = p[:tipo_categoria_id]
    ci = p[:usuario_ci]
    @historial = HistorialAcademico.where(:periodo_id=>periodo_id, :idioma_id=>idioma_id, :tipo_categoria_id=>tipo_categoria_id, :usuario_ci=>ci).limit(1).first
    @secciones = Seccion.where(:idioma_id=>idioma_id, :tipo_categoria_id=>tipo_categoria_id, :periodo_id => periodo_id, :tipo_nivel_id=>@historial.tipo_nivel_id)
    render :layout=> false
  end
  
  def cambiar_seccion_guardar
    
    periodo_id,idioma_id,tipo_categoria_id, tipo_nivel_id, numero = params[:historial][:seccion].split(",")
    ci = params[:historial][:usuario_ci]    
    historial = HistorialAcademico.where(:periodo_id=>periodo_id, :idioma_id=>idioma_id, :tipo_categoria_id=>tipo_categoria_id, :usuario_ci=>ci).limit(1).first
    unless historial.seccion_numero.eql? numero
      historial.seccion_numero = numero
      if historial.save
        info_bitacora("Sección Modificada: #{historial.seccion.descripcion}")
        flash[:mensaje]="Sección Modificada Satisfactoriamente"
        redirect_to :action=>"opciones_menu"
      else
        flash[:mensaje]="no se pudo modificar la Seccion"
        redirect_to :action=> "cambiar_seccion"
      end    
    else
      info_bitacora("Intento de modificar sección, se mantien la sección: #{historial.seccion.descripcion}")
      flash[:mensaje]="se mantiene la sección"
      redirect_to :action=>"opciones_menu"
    end
  end
  
  def seleccionar_curso
    periodo = session[:parametros][:periodo_actual]
    ci = session[:estudiante_ci]
    @usuario = Usuario.where(:ci=>ci).limit(1).first
    @cursos = EstudianteCurso.where(:usuario_ci => ci).collect{|c| c.tipo_curso}
    @titulo_pagina = "Modificar Estudiante: #{@usuario.descripcion}"
    @subtitulo_pagina = "Seleccione el Curso"
    @accion = params[:accion]
        
  end
  
  def confirmar_inscripcion
    p=params[:parametros]
    ci = p[:usuario_ci]
    @historial = HistorialAcademico.where(:periodo_id=>p[:periodo_id], :idioma_id=>p[:idioma_id], :tipo_categoria_id=>p[:tipo_categoria_id], :usuario_ci=>ci).limit(1).first
    render :layout => false   
  end

  def cambiar_nota
    if (session[:administrador].usuario_ci != "aceim")
      pa = params[:parametros]
      @historial = HistorialAcademico.find pa[:historial_id]
      render :layout => false   
    else
      redirect_to :action => "opciones_menu"
    end
  end

  def ver_detalle_nota
    if session[:administrador].tipo_rol_id <= 3
      pa = params[:parametros]
      @historial = HistorialAcademico.find pa[:historial_id]

      @evaluaciones = @historial.notas_en_evaluaciones
      @n1 = @historial.nota_en_evaluacion("EXA_ESC_1").nota_valor if @historial.nota_en_evaluacion("EXA_ESC_1")
      @n2 = @historial.nota_en_evaluacion("EXA_ESC_2").nota_valor if @historial.nota_en_evaluacion("EXA_ESC_2")
      @n3 = @historial.nota_en_evaluacion("EXA_ORA").nota_valor if @historial.nota_en_evaluacion("EXA_ORA")
      @n5 = @historial.nota_en_evaluacion("REDACCION").nota_valor if @historial.nota_en_evaluacion("REDACCION")
      @n4 = @historial.nota_en_evaluacion("OTRAS").nota_valor if @historial.nota_en_evaluacion("OTRAS")

      render :layout => false
    else
      redirect_to :action => "opciones_menu"
    end
  end
  
  def confirmar_inscripcion_guardar
    idioma_id = params[:historial][:idioma_id]
    tipo_categoria_id = params[:historial][:tipo_categoria_id]
    tipo_nivel_id = params[:historial][:tipo_nivel_id]
    ci = params[:historial][:usuario_ci]
    periodo = params[:historial][:periodo_id]
    depositos = HistorialAcademico.where(periodo_id: periodo).collect{|h| h.numero_deposito}
    unless params[:historial][:numero_deposito].eql? ""
      if depositos.include? params[:historial][:numero_deposito].to_s
        flash[:mensaje]="Número de pago ya usado para este período"
        redirect_to :action=> "opciones_menu"
      else
        @historial = HistorialAcademico.where(:periodo_id=>periodo, :idioma_id=>idioma_id, :tipo_categoria_id=>tipo_categoria_id, :usuario_ci=>ci, :tipo_nivel_id=>tipo_nivel_id).limit(1).first
        @historial.tipo_estado_inscripcion_id = "INS"
        @historial.numero_deposito = params[:historial][:numero_deposito]
        @historial.tipo_transaccion_id = params[:historial][:tipo_transaccion_id]
        @historial.cuenta_bancaria_id = params[:historial][:cuenta_bancaria_id]
    
        if @historial.save
          info_bitacora("Confirmación de Curos: #{@historial.curso.descripcion}")
          flash[:mensaje]="Confirmacion de Inscripcion Exitosa"
          redirect_to :action=> "opciones_menu"
        else
          flash[:mensaje]="no se pudo confirmar la seccion"
          redirect_to :action=> "opciones_menu"
        end
      end
    else
      flash[:mensaje]="debe agregar un numero de pago"
      redirect_to :action=> "opciones_menu"
    end
  end
  
  def confirmar_eliminar
    pa = params[:parametros]
    @historial = HistorialAcademico.find pa[:historial_id]
    render :layout => false
  end
  
  def eliminar_curso
    h = HistorialAcademico.find params[:historial_id]
    ci = h.usuario_ci
    if h.destroy
      session[:estudiante] = Estudiante.find(ci)
      info_bitacora("Eliminado Curso: #{h.curso.descripcion}")
      flash[:mensaje] = "curso eliminado corréctamente"
      redirect_to  :action=>"opciones_menu"
    else
      flash[:mensaje] = "el curso no pudo ser eliminado"
      redirect_to  :action=>"opciones_menu"
    end
   
   
  end
  
  def confirmar_resetear
    @usuario = Usuario.where(:ci =>session[:estudiante_ci]).limit(1).first
    render :layout=> false
  end
  
  def resetear_contrasena
    @usuario = Usuario.where(:ci =>session[:estudiante_ci]).limit(1).first
    @usuario.contrasena = @usuario.ci
    
    if @usuario.save
      info_bitacora("Contraseña reseteada, estudiante: #{@usuario.ci}")
      AdministradorMailer.aviso_general("#{@usuario.correo}","Su Contraseña fue Reseteada II", "su contraseña fue reseteada, ahora es:#{@usuario.contrasena}. Si ud. no solicitó este servicio dirijase a nuestras oficinas a fin de aclarar la situación").deliver
      flash[:mensaje] = "Contraseña reseteada corréctamente, un correo electrónico con la información fue enviado a la cuenta de correo del estudiante"
      redirect_to  :action=>"opciones_menu"
    else
      flash[:mensaje] = "no se pudo resetear la contraseña"
      redirect_to  :action=>"opciones_menu"
    end
    
  end
  
  def generar_constancia_notas

    idioma_id,tipo_categoria_id = params[:tipo_curso].split(",")
    ci = session[:estudiante_ci]
    
    
    periodo_actual = session[:parametros][:periodo_actual]

    if HistorialAcademico.where(:usuario_ci=>ci, :idioma_id=>idioma_id, :tipo_categoria_id=>tipo_categoria_id).delete_if{|x| !x.aprobo_curso?}.count > 0 &&  pdf = DocumentosPDF.generar_constancia_notas(ci,idioma_id,tipo_categoria_id,false)
        send_data pdf.render,:filename => "constancia_notas_#{idioma_id}-#{tipo_categoria_id} #{ci}.pdf",:type => "application/pdf", :disposition => "attachment"
        info_bitacora("Constancia de Notas generada: #{idioma_id}-#{tipo_categoria_id} #{ci}")
    else
      flash[:mensaje] = "No dispone de niveles aprobados para generar constancia de este curso"
      redirect_to :action=>"opciones_menu"
    end
  end

  def remitente
    @p = params[:parametros]
    render :layout=>false
  end

  def generar_constancia_estudio
    idioma_id,tipo_categoria_id = params[:tipo_curso].split(",")
    remitente = params[:remitente]
    ci = session[:estudiante_ci]
    
    periodo_actual = session[:parametros][:periodo_actual]

    if HistorialAcademico.where(:usuario_ci=>ci, :idioma_id=>idioma_id, :tipo_categoria_id=>tipo_categoria_id).count > 0 &&  pdf = DocumentosPDF.generar_constancia_estudio(ci,idioma_id,tipo_categoria_id,remitente,periodo_actual)
        send_data pdf.render,:filename => "constancia_estudio_#{idioma_id}-#{tipo_categoria_id} #{ci}.pdf"
        info_bitacora("Constancia de Estudio generada: #{idioma_id}-#{tipo_categoria_id} #{ci}")
    else
      flash[:mensaje] = "No dispone de niveles aprobados para generar constancia de este curso"
      redirect_to :action=>"opciones_menu"
    end
  end


  
  def generar_certificado
    idioma_id,tipo_categoria_id = params[:tipo_curso].split(",")
    ci = session[:estudiante_ci]
    if pdf = DocumentosPDF.generar_certificado_curso(ci,idioma_id,tipo_categoria_id,false)
      send_data pdf.render,:filename => "certificado_#{idioma_id}-#{tipo_categoria_id} #{ci}.pdf",:type => "application/pdf", :disposition => "attachment"
      info_bitacora("Certificado generado: #{idioma_id}-#{tipo_categoria_id} #{ci}")
    else
      flash[:mensaje] = "en estos momentos no se puede generar el certificado"
      redirect_to :action=>"opciones_menu"
    end
    
  end
  

  def confirmar_congelar_curso

    p=params[:parametros]
    ci = p[:usuario_ci]
    periodo = session[:parametros][:periodo_actual]
    @historial = HistorialAcademico.where(:idioma_id=>p[:idioma_id],:tipo_categoria_id=>p[:tipo_categoria_id],:periodo_id=>periodo,:usuario_ci=>ci).limit(1).first
    render :layout => false
 

  end
  
  def congelar_curso

    periodo = session[:parametros][:periodo_actual]
    idioma_id,tipo_categoria_id = params[:tipo_curso].split(",")
    ci = params[:usuario_ci]
    h = HistorialAcademico.where(:usuario_ci=>ci, :periodo_id=>periodo, :idioma_id=>idioma_id, :tipo_categoria_id=>tipo_categoria_id).limit(1).first
  
    h.tipo_estado_calificacion_id = "CO"
    h.tipo_estado_inscripcion_id = "CON"
        
    if h.save
      session[:estudiante] = Estudiante.find(ci)
      info_bitacora("Congelando Curso: #{h.curso.descripcion}")
      flash[:mensaje] = "curso congelado correctamente"
    else
      flash[:mensaje] = "el curso no pudo ser congelado"
    end
    
    redirect_to  :action=>"opciones_menu"

  end  

  private

  def eliminar_estudiantes_cursos_vacios
    eliminados = 0
    EstudianteCurso.all.each do |ec|
      if ec.historiales_academicos.count.eql? 0
        eliminados += 1 if ec.destroy 
      end
    end
    flash[:mensaje] = "Eliminados #{eliminados} Cursos sin historiales academicos;"
  end



end
