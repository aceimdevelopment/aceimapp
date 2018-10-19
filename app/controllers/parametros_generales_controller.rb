# encoding: utf-8

class ParametrosGeneralesController < ApplicationController
  before_action :filtro_logueado
  before_action :filtro_super_administrador
  
  def index

    @tipo_cursos = TipoCurso.all.delete_if{|c| c.idioma_id.eql? 'OR' or c.tipo_categoria_id.eql? 'BBVA'}

    @tipo_inscripciones = TipoInscripcion.all.delete_if{|i| i.id.eql? 'NI'}.sort_by{|i| i.descripcion}

    @titulo_pagina = "Configuraciones Generales"

    @inscripcion_general = ParametroGeneral.find("INSCRIPCION_ABIERTA").valor
    
    @descargar_planilla_inscripcion = ParametroGeneral.find("DESCARGAR_PLANILLA_INSCRIPCION").valor

    @inscripcion_nuevos = ParametroGeneral.find("INSCRIPCION_NUEVOS_ABIERTA").valor

    @cambio_de_horario = ParametroGeneral.find("INSCRIPCION_PERMITIR_CAMBIO_HORARIO").valor

    @listados_abiertos = ParametroGeneral.find("LISTADOS_ABIERTOS").valor

    @califiacion_abierta = ParametroGeneral.find("CALIFICACION_ABIERTA").valor

    @capacidad_cursos = ParametroGeneral.find("CAPACIDAD_CURSO").valor

    @periodo_actual = ParametroGeneral.find("PERIODO_ACTUAL").valor

    @periodo_actual_sabatino = ParametroGeneral.find("PERIODO_ACTUAL_SABATINO").valor

    @periodo_anterior = ParametroGeneral.find("PERIODO_ANTERIOR").valor

    @periodo_calificacion = ParametroGeneral.find("PERIODO_CALIFICACION").valor

    @periodo_inscripcion = ParametroGeneral.find("PERIODO_INSCRIPCION").valor

    @inscripcion_modo_ninos = ParametroGeneral.find("INSCRIPCION_MODO_NINOS").valor

    @inscripcion_activa = ParametroGeneral.find("INSCRIPCION_ACTIVA").valor

  end

  def guardar_inscripcion_idioma
    @inscripcion = Inscripcion.find(params[:id].split(" "))
    @inscripcion.tipo_estado_inscripcion_curso_id = 'PR' unless @inscripcion.tipo_estado_inscripcion_curso_id.eql? 'AB' 

    if @inscripcion.update_attributes(params[:inscripcion])
      flash[:mensaje] = 'Programación guardada'
    else
      flash[:mensaje] = "#{@inscripcion.errors.count} error(es) impide(n) que sea programada la inscripción: #{@inscripcion.errors.full_messages.join(". ")}."
    end
    redirect_to :action => 'index'
  end
  

  def programar_inscripcion_nuevos

    Thread.new do
      ParametroGeneral.programar_apertura_nuevos(1)
      # ApplicationRecord.connection.close
    end

    flash[:mensaje] = "Programación realizada" 
    redirect_to :back
  end

  def cambiar_inscripcion_activa_modal
    @inscripcion_activa = ParametroGeneral.find("INSCRIPCION_ACTIVA").valor

    render :layout => false
  end

  def cambiar_inscripcion_activa
    inscripcion_activa = ParametroGeneral.find("INSCRIPCION_ACTIVA")
    
    inscripcion_activa.valor = params[:inscripcion_activa]
    if inscripcion_activa.save
      flash[:mensaje] = "Cambio exitoso de Incripción Activa."
    else
      flash[:mensaje] = "Error al intentar actualizar valor de Inscripción Activa. Por favor, inténtenlo de nuevo."
    end
    redirect_to(:action=>"index")

  end

  def guardar_parametros

    descargar_planilla_inscripcion = ParametroGeneral.find("DESCARGAR_PLANILLA_INSCRIPCION")
    descargar_planilla_inscripcion.valor = params[:descargar_planilla_inscripcion]
    descargar_planilla_inscripcion.save
    
    inscripcion_general = ParametroGeneral.find("INSCRIPCION_ABIERTA")
    inscripcion_general.valor = params[:inscripcion_general]
    inscripcion_general.save

    inscripcion_nuevos = ParametroGeneral.find("INSCRIPCION_NUEVOS_ABIERTA")
    inscripcion_nuevos.valor = params[:inscripcion_nuevos]
    inscripcion_nuevos.save

    cambio_de_horario = ParametroGeneral.find("INSCRIPCION_PERMITIR_CAMBIO_HORARIO")
    cambio_de_horario.valor = params[:cambio_de_horario]
    cambio_de_horario.save

    listados_abiertos = ParametroGeneral.find("LISTADOS_ABIERTOS")
    listados_abiertos.valor = params[:listados_abiertos]
    listados_abiertos.save

    califiacion_abierta = ParametroGeneral.find("CALIFICACION_ABIERTA")
    califiacion_abierta.valor = params[:calificacion_abierta]
    califiacion_abierta.save

    inscripcion_modo_ninos = ParametroGeneral.find("INSCRIPCION_MODO_NINOS")
    inscripcion_modo_ninos.valor = params[:inscripcion_modo_ninos]
    inscripcion_modo_ninos.save

  
    flash[:mensaje] = "Configuraciones almacenadas con éxito"
    redirect_to(:action=>"index")

  end

  def cambiar_periodo_modal
    @metodo_invocador = params[:parametros][:invocador]
    @periodos = Periodo.all.collect{|x| x}.sort_by{|x| "#{x.ano} #{x.id}"}.reverse()
    render :layout => false
  end
  
  def cambiar_periodo
    
    if params[:metodo_invocador].eql? "cambiar_periodo_general"
    
      periodo_actual = ParametroGeneral.find("PERIODO_ACTUAL")
      periodo_actual.valor = params[:periodo][:id] 
      periodo_actual.save

      letra , ano = params[:periodo][:id].split "-"

      if letra.eql? "A"
          ano = ano.to_i - 1
          p = Periodo.where("ano = ?", ano).collect{|x| x}.sort_by{|x| "#{x.ano} #{x.id}"}.reverse().first
          nueva_letra = p.letra

      else
        nueva_letra = (letra.ord - 1).chr
      end

      periodo_anterior = ParametroGeneral.find("PERIODO_ANTERIOR")
      periodo_anterior.valor = nueva_letra + "-" + ano.to_s
      periodo_anterior.save
      session[:parametros][:periodo_actual] = params[:periodo][:id]
      flash[:mensaje] = "Periodo General por defecto cambiado con éxito"
    
    elsif params[:metodo_invocador] == "cambiar_periodo_calificacion"     
      periodo_calificacion = ParametroGeneral.find("PERIODO_CALIFICACION") 
      periodo_calificacion.valor = params[:periodo][:id] 
      periodo_calificacion.save
      flash[:mensaje] = "Periodo de Calificación cambiado con éxito"

    elsif params[:metodo_invocador].eql? "cambiar_periodo_sabatino"
      periodo_actual = ParametroGeneral.find("PERIODO_ACTUAL_SABATINO")
      periodo_actual.valor = params[:periodo][:id] 
      periodo_actual.save
      flash[:mensaje] = "Periodo Sabatino cambiado con éxito"
    else
      periodo_inscripcion = ParametroGeneral.find("PERIODO_INSCRIPCION")
      periodo_inscripcion.valor = params[:periodo][:id] 
      periodo_inscripcion.save
    end
  
    redirect_to(:action=>"index")    

  end

  def crear_nuevo_periodo_modal
    
    ultimo_periodo = Periodo.order("periodo.ano ASC, periodo.id ASC").last
  
    letra = ultimo_periodo.letra

    letra = (letra.ord + 1).chr

    @nuevo_periodo = letra + "-" + ultimo_periodo.ano.to_s
    
    render :layout => false
  
  end

  def crear_nuevo_periodo_nuevo_ano_modal
    
    ultimo_periodo = Periodo.order("periodo.ano ASC, periodo.id ASC").last
  
    ano = ultimo_periodo.ano.to_i+1

    @nuevo_periodo = "A-"+ano.to_s
    
    render :layout => false
  
  end

  def crear_nuevo_periodo

    nuevo_periodo = params[:periodo_id]
    letra , ano = nuevo_periodo.split "-"

    @periodo = Periodo.new
  	@periodo.id = nuevo_periodo
    @periodo.ano = ano
    @periodo.fecha_inicio = '0000-00-00'
             
    if @periodo.save
      info_bitacora("Nueva Periodo Creado: #{nuevo_periodo}")
      flash[:mensaje] = "Periodo Creado Satisfactoriamente"
      redirect_to(:action=>"index")
    else
      flash[:mensaje] = "No se pudo crear el nuevo periodo"
      redirect_to(:action=>"index")
    end
  
  end

  def cambiar_capacidad_curso_modal
    @capacidad = ParametroGeneral.capacidad_curso
    render :layout => false
  end

  def cambiar_capacidad_curso
    valor = params[:capacidad]
    capacidad = ParametroGeneral.find("CAPACIDAD_CURSO")
    capacidad.valor = valor
    flash[:mensaje] = capacidad.save ? "Capacidad de curso actualizada" : "No se pudo acualizar la capacidad del curso" 
    redirect_to :action => 'index' 
  end

end
