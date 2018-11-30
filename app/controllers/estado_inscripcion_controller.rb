# encoding: utf-8

class EstadoInscripcionController < ApplicationController
  before_action :filtro_logueado
  before_action :filtro_administrador

  def nivel1
    periodo = ParametroGeneral.periodo_actual
    @nombre = params[:id]
    @titulo_pagina = "Estado por #{@nombre} del periodo #{periodo.id}"
    if @nombre=="Idiomas" 
      @tipo = Idioma.all
      @otro = "Niveles"
    elsif @nombre =="Niveles"
      @tipo = TipoNivel.all
      @otro = "Idiomas"
    end
       
  end
  
  def nivel2
    periodo = ParametroGeneral.periodo_actual
    if @tipo2 = Idioma.where(:id => params[:id]).limit(1).first
      @tipo = TipoNivel.all
      @nombre = "Idiomas"
      @otro = "Niveles"    
    elsif @tipo2 = TipoNivel.where(:id => params[:id]).limit(1).first
      @tipo = Idioma.all
      @nombre = "Niveles"
      @otro = "Idiomas" 
    end
    @titulo_pagina = "Estado de Inscripcion de #{@otro} de #{@tipo2.descripcion} del #{periodo.id}"

  end
  
  def nivel3
    periodo = ParametroGeneral.periodo_actual
    @tipo1, @tipo2 = params[:id].split(",")
    
    @seccion = Seccion.where(:idioma_id => @tipo2, :tipo_nivel_id => @tipo1, :periodo_id => periodo.id)
    if @seccion.first 
      @seccion = Seccion.where(:idioma_id => @tipo1, :tipo_nivel_id => @tipo2,:periodo_id => periodo.id)
      @nombre="Niveles"
      @otro="Idiomas"
    else       
      @nombre="Idiomas"
      @otro="Niveles"
    end
    @titulo_pagina = "Secciones de #{@seccion.first.idiomas.descripcion} en #{@seccion.first.tipo_nivel.descripcion}"
  end
  
  def nivel4
    periodo_id, idioma_id, tipo_categoria_id, tipo_nivel_id, seccion_numero = params[:seccion].split(",")

    @historiales = HistorialAcademico.where(:periodo_id=>periodo_id,:idioma_id => idioma_id, :tipo_categoria_id=>tipo_categoria_id,:tipo_nivel_id=>tipo_nivel_id, :seccion_numero=>seccion_numero, :tipo_estado_inscripcion_id=>"INS")
    if  @historiales.size == 0
      flash[:mensaje] = "No hay estudiantes confirmados en esta sección"
      redirect_to :action => "ver_secciones"
      return
    end         
    @historiales = @historiales.sort_by{|x| x.usuario.nombre_completo}
    @titulo_pagina = "Periodo #{@historiales.first.periodo_id}"
    @tipo1 = @historiales.first.idioma_id
    @tipo2 = @historiales.first.tipo_nivel_id
  end

  def ver_pdf_estudiantes
    periodo_id, idioma_id, tipo_categoria_id, tipo_nivel_id, seccion_numero = params[:seccion].split(",")
    if pdf = DocumentosPDF.generar_listado_estudiantes(periodo_id,idioma_id,tipo_nivel_id,tipo_categoria_id,seccion_numero,false, params[:admin])
      send_data pdf.render,:filename => "#{periodo_id}_#{idioma_id}_#{tipo_categoria_id}_#{tipo_nivel_id}_#{seccion_numero}.pdf",:type => "application/pdf", :disposition => "attachment"
    end
  end
  
  def ver_secciones

    #verificando el envio de correos
    if params[:ce]
      flash[:mensaje] = "Los correos se han enviado satisfactoriamente"
    end
    @titulo_pagina = "Estado de la Inscripción"

    @filtro = params[:filtrar] 
    @filtro = nil if @filtro == nil || @filtro.strip.size == 0
    @filtro2 = params[:filtrar2] 
    @filtro2 = nil if @filtro2 == nil || @filtro2.strip.size == 0
    @filtro3 = params[:filtrar3] 
    @filtro3 = nil if @filtro3 == nil || @filtro3.strip.size == 0
    @filtro4 = params[:filtrar4] 
    @filtro4 = nil if @filtro4 == nil || @filtro4.strip.size == 0
    @filtro5 = params[:filtrar5] 
    @filtro5 = nil if @filtro5 == nil || @filtro5.strip.size == 0


    # puts session[:parametros]

    periodo = session[:parametros][:periodo_actual]
    @subtitulo_pagina = "Período #{periodo}"  
    @seccion = Seccion.where(:periodo_id=>periodo)

    # cambiar todo en función a delete_if

    @tipos_curso = @seccion.collect{|y| y.tipo_curso}.uniq
    @tipos_nivel = @seccion.collect{|y| y.tipo_nivel}.uniq
    #render :text => "#{@seccion.collect{|x| x.horario_seccion2}.delete_if{|r| r.nil?}.inspect}"
    #return
    @ubicaciones = @seccion.collect{|x| x.horario_seccion2}.delete_if{|r| r.nil?}.collect{|w| w.aula }.compact.collect{|y| y.tipo_ubicacion }.uniq

    @tipo_inscripcion = %W(Sabatinos Semanal)

    # Filtro por Idioma
    if @filtro
      idioma_id , tipo_categoria_id = @filtro.split ","
      @seccion = @seccion.delete_if{|x| !(x.periodo_id == periodo && x.idioma_id == idioma_id && x.tipo_categoria_id == tipo_categoria_id)}
    end  

    # Filtro por Ubicacion
    if @filtro2
      @seccion = @seccion.delete_if{|s| s.horario_seccion2.aula.nil? || s.horario_seccion2.aula.tipo_ubicacion_id != @filtro2}
    end
    
    # Filtro por Horario
    @seccion = @seccion.delete_if{|s| s.horario != @filtro3} if (@filtro3 and @filtro3!= 'undefined')
    # Filtro de Nivel

    @seccion = @seccion.delete_if{|s| s.tipo_nivel_id != @filtro4 } if @filtro4

    if @filtro5
      @seccion = @seccion.delete_if{|s| s.horario == 'Sábado (08:30AM - 12:45PM)'} if @filtro5.eql? 'Semanal'
      @seccion = @seccion.delete_if{|s| s.horario != 'Sábado (08:30AM - 12:45PM)'} if @filtro5.eql? 'Sabatinos'
    end
    @horarios = @seccion.collect{|z| z.horario}.uniq

  end
  
  def ver_pdf_secciones
    @filtro = params[:filtrar] 
    @filtro = nil if @filtro == nil || @filtro.strip.size == 0
    @filtro2 = params[:filtrar2] 
    @filtro2 = nil if @filtro2 == nil || @filtro2.strip.size == 0
    @filtro3 = params[:filtrar3] 
    @filtro3 = nil if @filtro3 == nil || @filtro3.strip.size == 0
    
    periodo_actual = ParametroGeneral.periodo_actual
    if pdf = DocumentosPDF.generar_listado_secciones(session[:parametros][:periodo_actual],false,@filtro,@filtro2,@filtro3)
      send_data pdf.render,:filename => "Secciones_periodo_#{session[:parametros][:periodo_actual]}.pdf",:type => "application/pdf", :disposition => "attachment"
    end
  end 
  
  def ver_pdf_secciones_2
    @filtro = params[:filtrar] 
    @filtro = nil if @filtro == nil || @filtro.strip.size == 0
    @filtro2 = params[:filtrar2] 
    @filtro2 = nil if @filtro2 == nil || @filtro2.strip.size == 0
    @filtro3 = params[:filtrar3] 
    @filtro3 = nil if @filtro3 == nil || @filtro3.strip.size == 0
    @filtro4 = params[:filtrar4] 
    @filtro4 = nil if @filtro4 == nil || @filtro4.strip.size == 0
    #periodo_actual = ParametroGeneral.periodo_actual
    if pdf = DocumentosPDF.generar_listado_secciones(session[:parametros][:periodo_actual],false,@filtro,@filtro2,@filtro3,@filtro4)
      send_data pdf.render,:filename => "Secciones_periodo_#{session[:parametros][:periodo_actual]}.pdf",:type => "application/pdf", :disposition => "attachment"
    end
  end
  


  def cambiar_aula

    @p = params[:parametros]
    session[:indice_cambiar_aula] = @p[:indice]


    periodo_id, idioma_id,tipo_categoria_id,tipo_nivel_id,numero,tipo_hora_id,tipo_dia_id = @p[:seccion_horario].split(",")

		horario_sec = HorarioSeccion.where(:periodo_id => periodo_id, :tipo_hora_id => tipo_hora_id, :tipo_dia_id => tipo_dia_id).collect{|hs| hs.aula_id}

		@aulas = BloqueAulaDisponible.where(["aula_id NOT IN (?) AND asignada = ? AND tipo_dia_id = ? AND tipo_hora_id = ? ", horario_sec, 1, tipo_dia_id, tipo_hora_id])
		

    @seccion_horario = HorarioSeccion.where(:periodo_id=>periodo_id, :idioma_id=>idioma_id, :tipo_categoria_id=>tipo_categoria_id,:tipo_nivel_id=>tipo_nivel_id,:seccion_numero=>numero,:tipo_dia_id=>tipo_dia_id, :tipo_hora_id=>tipo_hora_id).limit(1).first

    numero_pareja = BloqueAulaDisponible.where(:tipo_hora_id => tipo_hora_id, :tipo_dia_id => tipo_dia_id, :aula_id => @seccion_horario.aula_id).first

    @aula_pareja = BloqueAulaDisponible.where(["pareja = ? AND tipo_dia_id != ?", numero_pareja.pareja, tipo_dia_id]).first
    render :layout => false
  end
  

  def cambiar_aula_guardar
  
    periodo_id, idioma_id,tipo_categoria_id,tipo_nivel_id,numero,tipo_hora_id,tipo_dia_id = params[:seccion_completa].split(",")

    aula_id=params[:seccion_horario][:aula_id]
		controlador = params[:controlador]
		accion = params[:accion]
		periodo = params[:periodo]
		idioma = params[:idioma]
		categoria = params[:categoria]

    seccion_horario = HorarioSeccion.where(:periodo_id=>periodo_id, :idioma_id=>idioma_id, :tipo_categoria_id=>tipo_categoria_id,:tipo_nivel_id=>tipo_nivel_id,:seccion_numero=>numero,:tipo_dia_id=>tipo_dia_id, :tipo_hora_id=>tipo_hora_id).limit(1).first

    if(tipo_dia_id != "SA")

			#Se busca el dia complemento, para modificar ambos registros en la tabla horario_seccion

			seccion_horario_comp = HorarioSeccion.where(["periodo_id = ? AND idioma_id = ? AND tipo_categoria_id = ? AND tipo_nivel_id = ? AND seccion_numero = ? AND tipo_dia_id != ? AND tipo_hora_id = ? ", periodo_id, idioma_id, tipo_categoria_id, tipo_nivel_id, numero, tipo_dia_id, tipo_hora_id]).limit(1).first

			#A ambos dias se les asigna el aula nueva
		  if aula_id=="" 
		    seccion_horario.aula_id = "PD"
				seccion_horario_comp.aula_id = "PD"
		  else

        pareja = BloqueAulaDisponible.select("pareja").where(:tipo_dia_id => tipo_dia_id, :tipo_hora_id => tipo_hora_id, :aula_id => aula_id).first

        aula_id_comp = BloqueAulaDisponible.select("aula_id").where(["pareja = ? AND tipo_dia_id != ? ", pareja.pareja, tipo_dia_id]).first

		    seccion_horario.aula_id = aula_id
				seccion_horario_comp.aula_id = aula_id_comp.aula_id
		  end

		  if seccion_horario.save and seccion_horario_comp.save
		    info_bitacora("Cambio de aula: #{seccion_horario.seccion.descripcion} #{seccion_horario.aula_id}")
		    flash[:mensaje]="Aula actualizada Satisfactoriamente"
				redirect_to :action=> accion, :controller => controlador,:anchor => "ins#{session[:indice_cambiar_aula]}", :controlador => controlador, :periodo => periodo, :idioma => idioma, :categoria => categoria, :filtrar => params[:f],:filtrar2 => params[:f2],:filtrar3 => params[:f3]
		  else
		    flash[:mensaje]="no se pudo confirmar la seccion"
				redirect_to :action=> accion, :controller => controlador, :controlador => controlador, :periodo => periodo, :idioma => idioma, :categoria => categoria
		  end

		else #Si el dia que va a modificarse es Sabado

		  if aula_id=="" 
		    seccion_horario.aula_id = "PD"
		  else
		    seccion_horario.aula_id = aula_id
		  end

		  if seccion_horario.save
		    info_bitacora("Cambio de aula: #{seccion_horario.seccion.descripcion} #{seccion_horario.aula_id}")
		    flash[:mensaje]="Aula actualizada Satisfactoriamente"
				redirect_to :action=> accion, :controller => controlador,:anchor => "ins#{session[:indice_cambiar_aula]}", :controlador => controlador, :periodo => periodo, :idioma => idioma, :categoria => categoria, :filtrar => params[:f],:filtrar2 => params[:f2],:filtrar3 => params[:f3]
		  else
		    flash[:mensaje]="no se pudo confirmar la seccion"
				redirect_to :action=> accion, :controller => controlador, :controlador => controlador, :periodo => periodo, :idioma => idioma, :categoria => categoria
		  end #endif seccion_horario.save

		end #endif(tipo_dia_id != "SA")

  end



  def cambiar_instructor
   
    @p = params[:parametros]
    session[:indice_cambiar_instructor] = @p[:indice]
    periodo_id, idioma_id,tipo_categoria_id,tipo_nivel_id,numero = @p[:seccion].split(",")

		@accion = @p[:accion]
		@controlador = @p[:controlador]

    @seccion = Seccion.where(:periodo_id=>periodo_id, :idioma_id=>idioma_id, :tipo_categoria_id=>tipo_categoria_id,:tipo_nivel_id=>tipo_nivel_id,:seccion_numero=>numero).limit(1).first

    instructores_secciones = Seccion.where(["periodo_id = ? AND bloque_horario_id = ? AND instructor_ci IS NOT NULL", periodo_id,@seccion.bloque_horario_id]).collect{|is| is.instructor_ci}

    if instructores_secciones.size == 0
      @instructores = HorarioDisponibleInstructor.where(["disponible = ? AND bloque_horario_id = ? AND idioma_id = ? ", 1, @seccion.bloque_horario_id, idioma_id])
    else
      @instructores = HorarioDisponibleInstructor.where(["instructor_ci NOT IN (?) AND disponible = ? AND bloque_horario_id = ? AND idioma_id = ? ",instructores_secciones, 1, @seccion.bloque_horario_id, idioma_id])
    end
    @instructores = @instructores.sort_by{|x| x.instructor.usuario.nombre_completo}

 render :layout => false

  end
  

  def cambiar_instructor_guardar
    
		periodo_id, idioma_id,tipo_categoria_id,tipo_nivel_id,numero = params[:seccion_completa].split(",")
    instructor_ci=params[:seccion][:instructor_ci]
		accion = params[:accion]
		controlador = params[:controlador]
    
    seccion = Seccion.where(:periodo_id=>periodo_id, :idioma_id=>idioma_id, :tipo_categoria_id=>tipo_categoria_id,:tipo_nivel_id=>tipo_nivel_id,:seccion_numero=>numero).limit(1).first

    if instructor_ci=="" or instructor_ci=="-----"
      seccion.instructor_ci = nil
    else
      seccion.instructor_ci = instructor_ci
    end

    if seccion.save
      info_bitacora("Cambio de Instructor: #{seccion.descripcion} #{seccion.instructor_ci}")
      flash[:mensaje]="Instructor actualizado Satisfactoriamente"
      redirect_to :action=> accion, :controller => controlador, :anchor => "ins#{session[:indice_cambiar_instructor]}", :filtrar => params[:f],:filtrar2 => params[:f2],:filtrar3 => params[:f3]
      session[:indice_cambiar_instructor] = nil
    else
      flash[:mensaje]="no se pudo confirmar el Instructor"
      redirect_to :action=> accion, :controller => controlador
    end

  end
  
  
  def confirmar_eliminar

    p=params[:parametros]
		@accion = p[:accion]
		@controlador = p[:controlador]

    periodo_id, idioma_id,tipo_categoria_id,tipo_nivel_id,seccion_numero = p[:seccion].split(",")

    @seccion = Seccion.where(:periodo_id=>periodo_id, :idioma_id=>idioma_id,:tipo_categoria_id=>tipo_categoria_id,:tipo_nivel_id=>tipo_nivel_id, :seccion_numero=>seccion_numero).limit(1).first
    @historiales = HistorialAcademico.where(:periodo_id=>periodo_id, :idioma_id=>idioma_id,:tipo_categoria_id=>tipo_categoria_id,:tipo_nivel_id=>tipo_nivel_id, :seccion_numero=>seccion_numero)
    if @seccion.esta_abierta
      @alerta = "¡ALERTA: Esta Sección aún esta abierta!"
    end
    render :layout => false
  end


def eliminar_seccion

		accion = params[:accion]
		controlador = params[:controlador]
    periodo_id, idioma_id,tipo_categoria_id,tipo_nivel_id,seccion_numero = params[:seccion].split(",")

    seccion = Seccion.where(:periodo_id=>periodo_id, :idioma_id=>idioma_id,:tipo_categoria_id=>tipo_categoria_id,:tipo_nivel_id=>tipo_nivel_id, :seccion_numero=>seccion_numero).limit(1).first
    historiales = HistorialAcademico.where(:periodo_id=>periodo_id,:idioma_id=>idioma_id,:tipo_categoria_id=>tipo_categoria_id,:tipo_nivel_id=>tipo_nivel_id, :seccion_numero=>seccion_numero)
    unless historiales.size==0
      historiales.each do |h|
        if h.destroy
          info_bitacora("Eliminado Curso: #{h.curso.descripcion} a #{h.usuario.descripcion}")
        else
          flash[:mensaje] = "el curso: #{h.curso.descripcion} del estudiante: #{h.usuario.descripcion}  no pudo ser eliminado, falló la eliminación de la sección"
          redirect_to :action=> accion, :controller => controlador
          return
        end        
      end      
    end
    descripcion = seccion.descripcion
    if seccion.destroy
      info_bitacora("Seccion Eliminada: #{descripcion}")    
      flash[:mensaje] = "Sección eliminada correctamente"
      redirect_to :action=> accion, :controller => controlador
    else
      flash[:mensaje] = "La sección no pudo ser eliminada"
      redirect_to :action=> accion, :controller => controlador
    end
  
  end
  

  def liberar_todo
    periodo = session[:parametros][:periodo_actual]
    @total_no_confirmados = HistorialAcademico.where(periodo_id: periodo, tipo_estado_inscripcion_id: "PRE")
    @total_no_confirmados.each{|h| h.destroy}
    flash[:mensaje] = "#{@total_no_confirmados.count} cupos liberados."
    redirect_to :back
  end

  def confirmar_liberar_cupos
    p=params[:parametros]
		@accion = p[:accion]
		@controlador = p[:controlador]
    periodo_id, idioma_id,tipo_categoria_id,tipo_nivel_id,seccion_numero = p[:seccion].split(",")

    @seccion = Seccion.where(:periodo_id=>periodo_id, :idioma_id=>idioma_id,:tipo_categoria_id=>tipo_categoria_id,:tipo_nivel_id=>tipo_nivel_id, :seccion_numero=>seccion_numero).limit(1).first
    @historiales = HistorialAcademico.where(:periodo_id=>periodo_id, :idioma_id=>idioma_id,:tipo_categoria_id=>tipo_categoria_id,:tipo_nivel_id=>tipo_nivel_id, :seccion_numero=>seccion_numero, :tipo_estado_inscripcion_id=>"PRE")

    render :layout => false
  end



  def liberar_cupos
		accion = params[:accion]
		controlador = params[:controlador]
    periodo_id, idioma_id,tipo_categoria_id,tipo_nivel_id,seccion_numero = params[:seccion].split(",")
    seccion = Seccion.where(:periodo_id=>periodo_id, :idioma_id=>idioma_id,:tipo_categoria_id=>tipo_categoria_id,:tipo_nivel_id=>tipo_nivel_id, :seccion_numero=>seccion_numero).limit(1).first
    historiales = HistorialAcademico.where(:periodo_id=>periodo_id,:idioma_id=>idioma_id,:tipo_categoria_id=>tipo_categoria_id,:tipo_nivel_id=>tipo_nivel_id, :seccion_numero=>seccion_numero, :tipo_estado_inscripcion_id=>"PRE")
    unless historiales.size==0
      historiales.each do |h|
        if h.destroy
          flash[:mensaje] = "Cupos de preinscritos liberados exitosamente"
          info_bitacora("Liberado cupos del curso: #{h.curso.descripcion} a #{h.usuario.descripcion}")
        else
          flash[:mensaje] = "El curso: #{h.curso.descripcion} del estudiante: #{h.usuario.descripcion}  no pudo ser eliminado, falló la liberación de cupos de la sección"
          redirect_to :action=> accion, :controller => controlador
          return
        end        
      end
      redirect_to :action=> accion, :controller => controlador     
    end

  end



  def datos_enviar_correo
    datos = params[:correos]
    p datos
    if datos.size > 0
    	ids = datos.split("_").compact 
      secciones = []
      ids.each{|iden|
        periodo_id, idioma_id, tipo_categoria_id, tipo_nivel_id, seccion_numero = iden.split(",")
        secciones << Seccion.where(
          :periodo_id => periodo_id,
          :idioma_id => idioma_id,
          :tipo_categoria_id => tipo_categoria_id,
          :tipo_nivel_id => tipo_nivel_id,
          :seccion_numero => seccion_numero
        ).limit(1).first
      }
      
      @correos = []
      
      secciones.each{|sec|
        @correos << sec.instructor.usuario.correo if sec.instructor 
        sec.estudiantes_inscritos.each{|ins|
          @correos << ins.usuario.correo
        }
      }
    else
      flash[:mensaje] = "Error, no se ha seleccionado ninguna sección"
      redirect_to :action => "ver_secciones"
      return
    end
  	render :layout => false
  end
  
  def enviar_correo
    para = asunto = mensaje = adjunto = archivo = nil
    if params[:correo_para_instructores]
      asunto = params[:correo][:titulo]
      seleccion = params[:seleccion]
      mensaje = params[:correo][:contenido]
      intructores_ci = []
      seleccion.each do |s|
        intructores_ci << s.at(0) if s.at(1).eql? "1"
      end
      instructores = Instructor.where(:usuario_ci=>intructores_ci)
      para = instructores.collect{|i| i.usuario.correo}.to_a
    else
      para = params[:para].split(" ")
      asunto = params[:asunto]
      mensaje = params[:mensaje]
    end

    adjunto = params[:archivo_adjunto]
    archivo = nil
    if adjunto 
      archivo =  adjunto.original_filename
      directorio = "attachments"
      ruta = File.join(directorio, archivo)
      File.open(ruta, "wb") { |f| f.write(adjunto.read)}
    end    

    #trabajo = MailJob.enqueue(para,asunto,mensaje,archivo)
    #session[:meta_id] = trabajo.meta_id

    AdministradorMailer.enviar_correo_general_masivo(para,asunto,mensaje,adjunto).deliver


    #borrando archivo
    #File.delete("#{ruta}") if File.exist?("#{ruta}")

    # if params[:correo_para_instructores]
    #   redirect_to :action => "ver_estado_envio", :correo_para_instructores => "true"
    # else
    #   redirect_to :action => "ver_estado_envio"
    # end
    # return

    redirect_to :back
  end
  
  def ver_estado_envio
    @valor = nil
    if params[:correo_para_instructores]
      @valor = "true"
    end
  end
  
  def actualizar_estado
    algo = MailJob.get_meta(session[:meta_id])
    @estado = algo.progress[:percent]
    render :text => @estado, :layout => false
  end
  
end
