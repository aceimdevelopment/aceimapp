# encoding: utf-8

class PrincipalController < ApplicationController
  before_action :filtro_logueado

  # before_action :filtro_logueado

  def tiempo_agotado    
    @estudiante_examen = EstudianteExamen.find session[:estudiante_examen_id].to_s
    @estudiante_examen.tiempo = 0
    @estudiante_examen.tipo_estado_estudiante_examen_id = 'AGOTADO'
    if @estudiante_examen.save
      session[:estudiante_examen_id] = nil
      flash[:mensaje] = 'Puede ver su resultado haciendo click en el enlace de correspondiente'
    end
    redirect_to :action => 'index'
  end

  def index
    session[:nuevo] = nil 
    @titulo_pagina = "Principal"
    @preinscrito = !!HistorialAcademico.where(
      :usuario_ci => session[:usuario].ci,
      :idioma_id => session[:tipo_curso].idioma_id,
      :tipo_categoria_id => session[:tipo_curso].tipo_categoria_id,
      :periodo_id => session[:parametros][:periodo_inscripcion]).limit(1).first

    @periodo = ParametroGeneral.periodo_actual 
    @periodo_sabatino = ParametroGeneral.periodo_actual_sabatino 

    @ha = HistorialAcademico.where(:idioma_id => session[:tipo_curso].idioma_id, :usuario_ci => session[:usuario].ci, :tipo_categoria_id => 'AD', :periodo_id => [@periodo.id, @periodo_sabatino.id]).first
    @descargar_planilla_inscripcion = ParametroGeneral.find("DESCARGAR_PLANILLA_INSCRIPCION").valor

    @ha = nil if (@ha and @ha.idioma_id.eql? 'FR' and (@ha.tipo_nivel_id.eql? "CB" or @ha.tipo_nivel_id.eql? "CI" or @ha.tipo_nivel_id.eql? "CA"))

    @archivos_disponibles = Archivo.where(idioma_id: @ha.idioma_id, tipo_nivel_id: @ha.tipo_nivel_id, bloque_horario_id: @ha.seccion.bloque_horario_id) if @ha


    @curso_abierto_regular = Inscripcion.where(:tipo_inscripcion_id => 'RE', 
      :tipo_estado_inscripcion_curso_id => 'AB', 
      :idioma_id => session[:tipo_curso].idioma_id,
      :tipo_categoria_id => session[:tipo_curso].tipo_categoria_id).limit(1).first

    @curso_abierto_cambio = Inscripcion.where(:tipo_inscripcion_id => 'CA', 
      :tipo_estado_inscripcion_curso_id => 'AB', 
      :idioma_id => session[:tipo_curso].idioma_id,
      :tipo_categoria_id => session[:tipo_curso].tipo_categoria_id).limit(1).first


    @nivelaciones = EstudianteNivelacion.where(
      :usuario_ci => session[:usuario].ci,
      :idioma_id => session[:tipo_curso].idioma_id,
      :tipo_categoria_id => session[:tipo_curso].tipo_categoria_id,
      :periodo_id => session[:parametros][:periodo_inscripcion])

    @estudiante_examenes = EstudianteExamen.joins(:examen).where('estudiante_examen.estudiante_ci' => session[:usuario].ci, "examen.periodo_id" => @periodo.id)

  end

  def principal
    mensaje = flash[:mensaje]
    # flash[:mensaje] = mensaje
    # rol = session[:rol]
    # accion = ""
    # accion = "_admin" if rol == "Administrador"
    # accion = "_instructor" if rol == "Instructor"
    # redirect_to :controller => "principal#{accion}"
    # return
    rol = session[:rol]
    if rol == "Administrador"
      flash[:mensaje] = mensaje
      redirect_to :controller => "principal_admin"
      return
    end
    if rol == "Instructor"
      flash[:mensaje] = mensaje
      redirect_to :controller => "principal_instructor"
      return
    end           
    flash[:mensaje] = mensaje
    redirect_to :controller => "principal"
    return
  end
  
  
  def cambiar_periodo_modal
    @periodos = Periodo.all.collect{|x| x}.sort_by{|x| "#{x.ano} #{x.id}"}.reverse()
    @controlador = params[:parametros][:controlador]
    @accion = params[:parametros][:accion]
    render :layout => false
  end
  
  def cambiar_periodo
    controlador = params[:controlador]
    accion = params[:accion]
    session[:parametros][:periodo_actual] = params[:periodo][:id] 
    flash[:mensaje]= "El periodo fue cambiado para su sessión a #{session[:parametros][:periodo_actual]}"
    redirect_to :controller => controlador, :action => accion
  end

  
end
