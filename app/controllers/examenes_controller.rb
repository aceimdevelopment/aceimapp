# encoding: utf-8

class ExamenesController < ApplicationController

  before_action :filtro_logueado
  before_action :filtro_administrador, :except => ['presentar', 'indicaciones', 'resultado', 'guardar_respuesta', 'completar']
  skip_before_action  :verify_authenticity_token  

  layout :resolver_layout

  HOST = "/aceim/assets/examenes/"

  def set_idioma
    session[:idioma] = (params[:id].eql? 'ALL') ? nil : params[:id] 
    redirect_to :action => 'index'
  end

  # GET /examenes
  # GET /examenes.json
  def index
    @cursos = Curso.order(['idioma_id', 'grado']).all
    @titulo = "Examentes Listados por Curso"
    # @examenes = Examen.joins(:curso_periodo).order("curso_periodo.periodo_id ASC")
    # @idiomas = Idioma.all.delete_if{|i| i.id.eql? 'OR'}
    if session[:idioma]
      @idiomas = Idioma.where(:id => session[:idioma])
    else  
      @idiomas = Idioma.all.delete_if{|i| i.id.eql? 'OR'}
    end

    @periodo_actual = ParametroGeneral.periodo_actual
    @periodo_anteriores = Periodo.where("id != ?", @periodo_actual.id)# ParametroGeneral.periodo_anterior
    # @aleman = Examen.joins(:curso_periodo).where(:curso_idioma_id => 'AL').order("curso_periodo.periodo_id ASC")
    # @ingles = Examen.where(:curso_idioma_id => 'IN').order("curso_periodo.periodo_id ASC")
    # @italiano = Examen.where(:curso_idioma_id => 'IT').order("curso_periodo.periodo_id ASC")
    # @frances = Examen.where(:curso_idioma_id => 'FR').order("curso_periodo.periodo_id ASC")
    # @portugues = Examen.where(:curso_idioma_id => 'PG').order("curso_periodo.periodo_id ASC")
    # @otros = Examen.all.delete_if{|e| e.curso_idioma_id.eql? 'IN', e.curso_idioma_id.eql? 'IT', e.curso_idioma_id.eql? 'AL', e.curso_idioma_id.eql? 'FR', e.curso_idioma_id.eql? 'PG' }


    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @examenes }
    end
  end
  
  # GET /examenes/1
  # GET /examenes/1.json
  def show
    @titulo = "Vista Previa del Examen"
    @examen = Examen.find(params[:id])
    @host = "#{request.protocol}#{request.host_with_port}"+HOST
    @parte_examenes = @examen.parte_examenes.joins(:parte).order('parte.orden ASC')

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @examen }
    end
  end

  # GET /examenes/new
  # GET /examenes/new.json
  def new


    @titulo = 'Nuevo Examen'
    @examen = Examen.new
    @idiomas = Idioma.all.delete_if{|i| i.id.eql? 'OR'}
    @categorias = TipoCategoria.all.delete_if{|cat| ['BBVA','TR'].include? cat.id}
    @niveles = TipoNivel.where(:id => ['BI','BII','BIII','MI','MII','MIII','AI','AII','AIII', 'CB', 'CI', 'CA'])
    @periodos = Periodo.lista_ordenada

    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @examen }
    end
  end

  # GET /examenes/1/edit
  def edit
    @examen = Examen.find(params[:id])
    @idiomas = Idioma.all.delete_if{|i| i.id.eql? 'OR'}
    @categorias = TipoCategoria.all.delete_if{|cat| ['BBVA','TR'].include? cat.id}
    @niveles = TipoNivel.where(:id => ['BI','BII','BIII','MI','MII','MIII','AI','AII','AIII', 'CB', 'CI', 'CA'])
    @periodos = Periodo.lista_ordenada

  end

  # POST /examenes
  # POST /examenes.json
  # def create
  #   @examen = Examen.new(params[:examen])

  #   respond_to do |format|
  #     if @examen.save
  #       format.html { redirect_to @examen, :notice => 'Examen was successfully created.' }
  #       format.json { render :json => @examen, :status => :created, :location => @examen }
  #     else
  #       format.html { render :action => "new" }
  #       format.json { render :json => @examen.errors, :status => :unprocessable_entity }
  #     end
  #   end
  # end

  def create
    @examen = Examen.new(params[:examen])

    respond_to do |format|
      if @examen.save
        exito = 0
         Parte.order('orden ASC').all.each do |parte|
          exito += 1 if @examen.parte_examenes.create(:parte_id => parte.id)  
        end 
        resultado_bloques = "#{exito} Partes del examen añadidas."
        info_bitacora "Examen Creado con id=#{@examen.id}. #{exito} examen_partes creadas."
        flash[:mensaje] = "Datos básicos almacenados con éxito.#{resultado_bloques}"
        format.html { redirect_to :action => 'wizard_paso2', :id => @examen.id}
        format.json { render :json => @examen, :status => :created, :location => @examen }
      else
        @titulo = "Nueva Examen"
        @accion = "registrar"
        @idiomas = Idioma.all.delete_if{|i| i.id.eql? 'OR'}
        @categorias = TipoCategoria.all.delete_if{|cat| ['BBVA','TR'].include? cat.id}
        @niveles = TipoNivel.where(:id => ['BI','BII','BIII','MI','MII','MIII','AI','AII','AIII'])
        @periodos = Periodo.lista_ordenada    
        flash[:mensaje] = "#{@examen.errors.count} error(es) impiden el registro de la factura: #{@examen.errors.full_messages.join(". ")}."
        format.html { render :action => "new" }
        format.json { render :json => @factura.errors, :status => :unprocessable_entity }
      end
    end

  end




  # PUT /examenes/1
  # PUT /examenes/1.json
  def update
    @examen = Examen.find(params[:id])
    # params[:examen][:tipo_estado_examen_id] = 'PRUEBA' if params[:examen][:tipo_estado_examen_id]
    respond_to do |format|
      if @examen.update_attributes(params[:examen])
        flash[:mensaje] = "Datos editados satisfactoriamente"
        format.html { redirect_to :controller => 'examenes'}
        format.json { head :ok }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @examen.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /examenes/1
  # DELETE /examenes/1.json
  def destroy
    @examen = Examen.find(params[:id])

    flash[:mensaje] = "Examen Eliminado con éxito" if @examen.destroy   

    respond_to do |format|
      format.html { redirect_to examenes_url }
      format.json { head :ok }
    end
  end

# Funcionalidades adicionales a las CRUD Autogeneradas.

  def wizard_paso2
    id = params[:id]
    @titulo = "Nuevo Examen"
    @examen = Examen.find(id)
    @actividad = Actividad.new
    @parte_examenes = @examen.parte_examenes.joins(:parte).order('parte.orden ASC')
  end

  #Funcion para la generación de EstudianteExamenes tanto para examenes de pruebas como oficiales 
  
  def generar_estudiante_examenes
    @examen = Examen.find params[:id]
    # NOTA: Incluir en la Generacion la asignacion al tiempo del examen al estudiante_examen. así como verificar la eliminación de las eer asociadas. 
    total_cursos = total_est_examen = 0 
    if @examen.es_prueba?
      @curso_periodos = CursoPeriodo.where(:periodo_id => @examen.periodo_id, :idioma_id => @examen.curso_idioma_id)
      total_cursos = @curso_periodos.count

      @curso_periodos.each do |curso_periodo|
        curso_periodo.secciones.each do |seccion|
          seccion.historial_academico.each do |historial|
            total_est_examen += 1 if @examen.estudiante_examenes.create(:estudiante_ci => historial.usuario_ci, :tipo_estado_estudiante_examen_id => 'PREPARADO')
          end
        end
      end

    else
      @curso_periodo = @examen.curso_periodo
      total_cursos = 1
      @curso_periodo.secciones.each do |seccion|
        seccion.historial_academico.each do |historial|
          total_est_examen += 1 if @examen.estudiante_examenes.create(:estudiante_ci => historial.usuario_ci, :tipo_estado_estudiante_examen_id => 'PREPARADO')
        end
      end
    end

    @examen.estudiante_examenes.each{|ee| ee.generar_eers2}

    flash[:mensaje] = "#{total_cursos} Curso(s). #{total_est_examen} exámenes generados a estudiantes."
    @examen.tipo_estado_examen_id = 'LISTO'
    flash[:mensaje] += 'Estado del examen actualizado' if @examen.save
    redirect_to :action => 'index'
  end

  def eliminar_estudiante_examenes
    @examen = Examen.find params[:id]

    total = 0
    @examen.estudiante_examenes.each do |ee| 
      ee.estudiante_examen_respuestas.each{|eer| eer.delete}
      total += 1 if ee.delete
    end
    flash[:mensaje] = "#{total} examenes eliminados"
    @examen.tipo_estado_examen_id = 'DISPONIBLE'
    flash[:mensaje] += 'Estado del examen actualizado' if @examen.save
    redirect_to :action => 'index'
  end

  # Avances


  # Funcionalidades CRUD propias de las actividades 

  def registrar_actividad
    @parte_examen = (ParteExamen.where (params[:parte_examen])).limit(1).first

    if @parte_examen

      @actividad = Actividad.new(params[:actividad])
      if @actividad.save and @parte_examen.parte_examen_actividades.create(:actividad_id => @actividad.id)
        flash[:mensaje] = "Actividad agregar con éxito"
      else
        flash[:mensaje] = "No se pudo agregar la actividad. Por favor verifique los campos e intentelo nuevamente."
      end
    else
      flash[:mensaje] = "Falló la inclusión de la nueva actividad, No se encontró la parte del examen requerida. Por Favor Verifique e intentelo nuevamente."
    end
    
    redirect_to :action => 'wizard_paso2', :id => "#{params[:parte_examen][:examen_id]}"
  end

  # Funcionalidades CRUD propias de las preguntas. (Puede trasladarse al controlador apropiado)
  def eliminar_pregunta
    @pregunta = Pregunta.find(params[:id])
    @actividad = @pregunta.actividad
    @pregunta.destroy
    redirect_to :back
      # render :partial => "preguntas/preguntas_text", :locals => {:actividad => @actividad}
  end

  def reseteo_completo

      @estudiante_examen = EstudianteExamen.find params[:id]

      @estudiante_examen.tipo_estado_estudiante_examen_id = 'PREPARADO'
      @estudiante_examen.tiempo = @estudiante_examen.examen.duracion
      @estudiante_examen.estudiante_examen_respuestas.delete_all

      flash[:mensaje] = ""
      flash[:mensaje] += "Reseteo completado con exito." if @estudiante_examen.save
      flash[:mensaje] += "Respuestas limpiadas" if @estudiante_examen.estudiante_examen_respuestas.count.eql? 0
      info_bitacora "Estudiante #{@estudiante_examen.estudiante_ci} reseteo completo para examen #{@estudiante_examen.examen.curso_periodo.descripcion}."
      redirect_to :back    
  end

  def habilitar_para_presentar
      @estudiante_examen = EstudianteExamen.find params[:id]

      @estudiante_examen.tipo_estado_estudiante_examen_id = 'PREPARADO'
      flash[:mensaje] = "Estudiante habilitado para presentar examen: #{@estudiante_examen.examen.descripcion_full}." if @estudiante_examen.save
      info_bitacora "Estudiante #{@estudiante_examen.estudiante_ci} habilitado para presentar examen #{@estudiante_examen.examen.curso_periodo.descripcion}."
      redirect_to :back
  end

  def resetear_tiempo
      @estudiante_examen = EstudianteExamen.find params[:id]

      @estudiante_examen.tiempo = @estudiante_examen.examen.duracion
      info_bitacora "Estudiante #{@estudiante_examen.estudiante_ci} reseteo de tiempo para examen #{@estudiante_examen.examen.curso_periodo.descripcion}."
      flash[:mensaje] = "Tiempo del examen: #{@estudiante_examen.examen.descripcion_full} reiniciado." if @estudiante_examen.save
      redirect_to :back
  end

  def rezagar
    tiempo = Time.now
    @estudiante_examen = EstudianteExamen.find params[:id]    
    @estudiante_examen.resagado_inicio = tiempo
    @estudiante_examen.resagado_fin = tiempo+(params[:horas].to_i).hour
    @estudiante_examen.tipo_estado_estudiante_examen_id = 'RESAGADO'
    if @estudiante_examen.save
      info_bitacora "Estudiante #{@estudiante_examen.estudiante_ci} rezagado para examen #{@estudiante_examen.examen.curso_periodo.descripcion} por #{params[:horas]} hora(s)."
      flash[:mensaje] = "El estudiante dispone ahora de #{params[:horas]} hora(s) para realizar el examen."
    end
    redirect_to :back
  end

  def borrar_respuestas
      @estudiante_examen = EstudianteExamen.find params[:id]
      @estudiante_examen.estudiante_examen_respuestas.delete_all
      info_bitacora "Estudiante #{@estudiante_examen.estudiante_ci} borradas respuestas para examen #{@estudiante_examen.examen.curso_periodo.descripcion}."
      flash[:mensaje] = "Respuestas limpiadas con exito." if @estudiante_examen.estudiante_examen_respuestas.count.eql? 0
      redirect_to :back
  end


# PRESENTAR EXAMENES

  # def indicaciones
  #   # @estudiante_examen = EstudianteExamen.first
  #   # La linea anterior debe ser sustituida con esta:

  #   @usuario = session[:usuario]
  #   @examen_id = params[:id]
  #   id = "#{@usuario.ci},#{@examen_id}"

  #   # id = "21121853,#{@examen_id}" if session[:rol].eql? 'Administrador'

  #   @estudiante_examen = EstudianteExamen.find id
  #   redirect_to :action => 'index' if @estudiante_examen.blank?

  # end

  # def presentar
  #   usuario = session[:usuario]

  #   @examen = Examen.where(:id => params[:id]).limit(1).first

  #   if not @examen 

  #     flash[:mensaje] = 'Examen no encontrado'
  #     redirect_to :controller => 'principal'
  #   else

  #     @estudiante_examen = @examen.estudiante_examenes.where(:estudiante_ci => usuario.ci).limit(1).first
  #     @estudiante_examen.tipo_estado_estudiante_examen_id = 'PREPARADO' if @examen.prueba
  #     if @estudiante_examen and @examen.se_puede_presentar? and @estudiante_examen.preparado? or @estudiante_examen.resagado?
  #       @estudiante_examen.tipo_estado_estudiante_examen_id = 'INICIADO'
  #       @estudiante_examen.tiempo = @examen.duracion if @estudiante_examen.tiempo.nil? or (@estudiante_examen.tiempo.eql? 0) or (@examen.prueba)
  #       @estudiante_examen.save
  #       # session[:tiempo] = @examen.duracion
  #       @titulo = @examen.descripcion_simple
  #       if @examen.prueba
  #         @estudiante_examen.estudiante_examen_respuestas.delete_all
  #       end
  #       # session[:estudiante_examen] = @estudiante_examen
  #       session[:estudiante_examen_id] = @estudiante_examen.id
  #       @estudiante_examen.estado_parte_id = @examen.parte_examenes.first.parte_id
  #       # @estudiante_examen.save!

  #       @host = "#{request.protocol}#{request.host_with_port}"+HOST
  #     else
  #       flash[:mensaje] = 'Examen no disponible'
  #       redirect_to :controller => 'principal'
  #     end
  #   end
  # end

  # def guardar_respuesta
  #   eer = params[:eer]
  #   estudiante_ci = eer[:estudiante_ci]
  #   examen_id = eer[:examen_id]
  #   @respuesta_id = eer[:respuesta_id]
  #   @eer = EstudianteExamenRespuesta.find_or_initialize_by_estudiante_ci_and_examen_id_and_respuesta_id(estudiante_ci,examen_id,@respuesta_id)
  #   @eer.update_attributes eer

  #   @eer.estudiante_examen.tiempo = params[:tiempo].to_i + 1
  #   @eer.estudiante_examen.transferir_nota_escrita2_a_historial if not @eer.estudiante_examen.examen.prueba
  #   @eer.estudiante_examen.save
  #   respond_to do |format|
  #     format.html {redirect_to :back}
  #     format.js
  #   end
    
  # end

  # def completar
  #   @ee = EstudianteExamen.find session[:estudiante_examen_id].to_s
  #   @ee.tipo_estado_estudiante_examen_id = 'COMPLETADO' #unless @estudiante_examen.examen.prueba
  #   @ee.tiempo = params[:tiempo]

  #   # PENDIENTE POR GUARDAR EN EXAMEN TEORICO 2 LA NOTA @estudiante_examen.total_puntos_correctos_base_20

  #   flash[:mensaje] = ""

  #   if @ee.save
  #     session[:estudiante_examen_id] = nil
  #     flash[:mensaje] = 'Examen Completado con Éxito.'
  #     puts 'Examen Completado con Éxito.'
  #   end

  #   @ee.transferir_nota_escrita2_a_historial unless @ee.examen.prueba
  #   # unless @ee.examen.prueba
  #   #   if @ee.transferir_nota_escrita2_a_historial
  #   #     flash[:mensaje] += 'Calificación asignada.' 
  #   #   else
  #   #     flash[:mensaje] += 'Su calificación no pudo ser asignada. (Notifique al personal administrativo para tomar las correcciones respectivas).'
  #   #   end
  #   # end

  #   redirect_to :action => :resultado, :id => @ee.id.to_s

  # end

  # def resultado
  #   # Variables Globales
  #   @estudiante_examen = EstudianteExamen.find params[:id].to_s

  #   @usuario = session[:usuario]

  #   rol = session[:rol]

  #   @examen = @estudiante_examen.examen
  #   @titulo = "Resultado del #{@examen.descripcion_simple}"

  #   @total_actividades = @examen.total_actividades
  #   @total_preguntas = @examen.total_preguntas
  #   @total_puntos = @examen.puntaje_total
    
  #   @total_puntos_correctos = @estudiante_examen.total_puntos_correctos
  #   @total_respuestas_correctas = @estudiante_examen.total_respuestas_correctas
  #   @total_respuestas_incorrectas = @total_preguntas - @total_respuestas_correctas

  # end

  def transferir_notas_a_historiales
    @estudiante_examenes = EstudianteExamen.where("tipo_estado_estudiante_examen_id = 'COMPLETADO' OR tipo_estado_estudiante_examen_id = 'INICIADO'").delete_if{|ee| ee.examen.prueba}

    total_trasferidos = 0
    total_ee = @estudiante_examenes.count
    @estudiante_examenes.each do |ee|
      total_trasferidos += 1 if ee.transferir_nota_escrita2_a_historial
      puts "Guardado ##{total_trasferidos}/#{total_ee}."
    end
    puts "Total de exámenes: #{total_ee}. Total transferidos: #{total_trasferidos}"
    flash[:mensaje] = "Total de exámenes: #{total_ee}. Total transferidos: #{total_trasferidos}"
    redirect_to :action => 'index'
  end

  private

  def resolver_layout
    case action_name
    when 'presentar', 'indicaciones', 'resultado'
      'presentar_examen'
    else
      'application'
    end
  end



end

