# encoding: utf-8

class CalificacionController < ApplicationController
  before_action :filtro_logueado
  before_action :filtro_administrador_instructor
  def index
  end
  
  def seleccionar_curso
    
    @titulo_pagina = "Seleccionar Curso"
    if session[:administrador] == nil
      @seccion = Seccion.where(:instructor_ci => session[:usuario].ci, 
                             :esta_abierta => true,
                             :periodo_id => session[:parametros][:periodo_calificacion]).uniq.sort_by{|x| Seccion.idioma(x.idioma_id)}
    elsif (session[:administrador].tipo_rol_id < 3)
      @seccion = Seccion.where(:esta_abierta => true,
                               :periodo_id => session[:parametros][:periodo_calificacion]).uniq.sort_by{|x| Seccion.idioma(x.idioma_id)}
    else
      redirect_to :controller => "principal_admin"
      return
    end
    
    if @seccion.size == 0 
      flash[:mensaje] = "Actualmente no posee nigún curso"
    end
  end
  
  def buscar_estudiantes
    saltar = true
    if params[:saltar] == nil
      saltar = true
    else
      saltar = false
    end
    if saltar
      session[:periodo_id] = params[:p]
      session[:idioma_id] = params[:i]
      session[:tipo_categoria_id] = params[:tc]
      session[:tipo_nivel_id] = params[:tn]
      session[:seccion_numero] = params[:sn]
    end
    @historiales, @usuarios = historiales_usuarios
    historial = @historiales.first
    @titulo_pagina = "Calificar sección"
    @curso = "#{Seccion.idioma(historial.idioma_id)}"
    @horario = Seccion.horario(session)
    @seccion = session[:seccion_numero]
    @nivel = historial.tipo_nivel.descripcion
    @tipo_nivel_id = session[:tipo_nivel_id]
    @periodo = historial.periodo
    @periodo_transicion = Periodo::PERIODO_TRANSICION_NOTAS_PARCIALES
    @periodo_30 = Periodo::PERIODO_30

    if (!historial.nota_en_evaluacion_sin_calificar? && !historial.sin_calificar? ) && (session[:administrador] == nil)
      redirect_to :action => "mostrar_calificaciones"
      return
    else
      if @periodo.es_menor_que? @periodo_transicion
        @historiales.each{|h|
          if !h.tiene_notas_adicionales? && h.idioma_id.upcase == "IN"
            h.crear_notas_adicionales
          end
        }
      elsif @periodo.es_mayor_igual_que? @periodo_30 
        @historiales.each{|h|
          h.generar_buscar_calificaciones if !h.tiene_notas_adicionales?
        }
      else
        @historiales.each{|h|

            if h.tiene_notas_adicionales?
              h.crear_nota_redaccion unless h.tiene_nota_redaccion?
            else
              h.crear_notas_adicionales
            end
        }
      end
    end

=begin
    if @periodo.es_menor_que? @periodo_transicion

      @historiales.each{|h|
         if !h.tiene_notas_adicionales? && h.idioma_id.upcase == "IN"
            h.crear_notas_adicionales
          end
      }
      
      if historial.idioma_id == "IN"
        if (!historial.nota_en_evaluacion_sin_calificar? && !historial.sin_calificar? && saltar) && (session[:administrador] == nil)
          redirect_to :action => "mostrar_calificaciones"
          return
        end
      elsif (!historial.sin_calificar? && saltar) && (session[:administrador] == nil)
        redirect_to :action => "mostrar_calificaciones"
        return
      end
    elsif @periodo.es_mayor_igual_que? @periodo_30 
      @historiales.each{|h|
        h.generar_buscar_calificaciones if !h.tiene_notas_adicionales?
      }
      if (!historial.nota_en_evaluacion_sin_calificar? && !historial.sin_calificar? && saltar) && (session[:administrador] == nil)
        redirect_to :action => "mostrar_calificaciones"
        return
      end

    else
      @historiales.each{|h|

          if h.tiene_notas_adicionales?
            h.crear_nota_redaccion unless h.tiene_nota_redaccion?
          else
            h.crear_notas_adicionales
          end
      }
      if (!historial.nota_en_evaluacion_sin_calificar? && !historial.sin_calificar? && saltar) && (session[:administrador] == nil)
        redirect_to :action => "mostrar_calificaciones"
        return
      end
    end      
=end
  end
  
  def guardar_notas
    nota = 0
    exitoso = true
    historial = nil #debe quedar asignado un ultimo historial
    params[:historial_academico].each{ |pa| 
      historial = HistorialAcademico.where(:usuario_ci => pa[0],
                                          :periodo_id => session[:periodo_id],
                                          :idioma_id => session[:idioma_id],
					  :tipo_estado_inscripcion_id => "INS",
                                          :tipo_categoria_id => session[:tipo_categoria_id],
                                          :tipo_nivel_id => session[:tipo_nivel_id],
                                          :seccion_numero => session[:seccion_numero]
                                          ).limit(1).first
      if pa[1] != ""
        case pa[1].upcase
          #when "SC"
          #  nota = HistorialAcademico::SC
          when "PI"
            nota = HistorialAcademico::PI
          else
            if !(HistorialAcademico::NOTASSTRING.include? pa[1]) 
              nota = -4           
            else
              nota = pa[1].to_i
            end
        end
      
        
        if nota != -4
          historial.nota_final = nota  
          historial.save
        else
          exitoso = false
        end
      else
        exitoso = false
      end
    }
    
    if !exitoso
      flash[:mensaje] = "Los datos han sido guardados, pero existen algunas notas inválidas o incompletas"
      @historiales,@usuarios = historiales_usuarios
      historial = @historiales.first
      @titulo_pagina = "Calificar sección"
      @curso = "#{Seccion.idioma(historial.idioma_id)}"
      @horario = Seccion.horario(session)
      @nivel = historial.tipo_nivel.descripcion
      @seccion = session[:seccion_numero]
      @periodo = historial.periodo
      @periodo_transicion = Periodo::PERIODO_TRANSICION_NOTAS_PARCIALES

      info_bitacora("La seccion #{session[:seccion_numero]} del curso #{Seccion.idioma(historial.idioma_id)} del horario #{Seccion.horario(session)} no fue calificada por completo, periodo #{session[:parametros][:periodo_calificacion]}")
      render :action => "buscar_estudiantes"
      return
    else
      historial.seccion.guardar_datos_calificacion(session[:usuario].ci)
      if session[:administrador] == nil
        historial.seccion.verificar_calificaciones_completas
      end
      #bitacora
      params[:historial_academico].each{ |pa| 
      historial = HistorialAcademico.where(:usuario_ci => pa[0],
                                          :periodo_id => session[:periodo_id],
                                          :idioma_id => session[:idioma_id],
					                                :tipo_estado_inscripcion_id => "INS",
                                          :tipo_categoria_id => session[:tipo_categoria_id],
                                          :tipo_nivel_id => session[:tipo_nivel_id],
                                          :seccion_numero => session[:seccion_numero]
                                          ).limit(1).first
      historial.cambiar_estado_calificacion(session[:tipo_categoria_id])
      info_bitacora("Usuario #{session[:usuario].nombre_completo} calificó al estudiante #{historial.usuario_ci} del curso #{Seccion.idioma(historial.idioma_id)}, horario #{Seccion.horario(session)}, seccion #{session[:seccion_numero]}, con #{historial.nota_final}, periodo #{session[:parametros][:periodo_calificacion]} ")
      }
      info_bitacora("La seccion #{session[:seccion_numero]} del curso #{Seccion.idioma(historial.idioma_id)} del horario #{Seccion.horario(session)} fue calificada por el usuario #{session[:usuario].nombre_completo}, periodo #{session[:parametros][:periodo_calificacion]}")
      #fin bitacora
      redirect_to :action => "mostrar_calificaciones"
    end
  end

# Guardar notas del metodo de calificacion de 30-30-30-10
  def guardar_notas_30
    exitoso_global = true
    exitoso_local = true
    nota_float = -2
    historial = nil
    @tipo_nivel_id = session[:tipo_nivel_id]
    
    arreglo = [{:nota1 => HistorialAcademico::EXAMENESCRITO1},
                 {:nota2 => HistorialAcademico::EXAMENESCRITO2},
                 {:nota3 => HistorialAcademico::EXAMENORAL},
                 {:nota4 => HistorialAcademico::OTRAS},
                 {:notafinal => "nota_final"}]

    arreglo.each{|a|
      params[a.keys[0]].each_with_index{|nota,i|
        exitoso_local = true
        historial = HistorialAcademico.where(:usuario_ci => nota[0],
                                          :periodo_id => session[:periodo_id],
                                          :idioma_id => session[:idioma_id],
                                          :tipo_estado_inscripcion_id => "INS",
                                          :tipo_categoria_id => session[:tipo_categoria_id],
                                          :tipo_nivel_id => session[:tipo_nivel_id],
                                          :seccion_numero => session[:seccion_numero]
                                          ).limit(1).first     
        
        if nota[1].upcase=="PI"
          nota_float = -1
        else
          begin
            nota_float = Float(nota[1].gsub(",","."))
          rescue
            exitoso_local = exitoso_global = false
          end
        end
        
        if exitoso_local 
          if a[a.keys[0]] != "nota_final"
            nota_individual = historial.nota_en_evaluacion(a[a.keys[0]])
            nota_individual.nota = nota_float
            nota_individual.save
          else
            historial.nota_final = nota_float
            historial.save
          end
        end
      }
    }
   
   if !exitoso_global
    flash[:mensaje] = "Los datos han sido guardados, pero existen algunas notas inválidas o incompletas"
    @historiales,@usuarios = historiales_usuarios
    historial = @historiales.first
    @titulo_pagina = "Calificar sección"
    @curso = "#{Seccion.idioma(historial.idioma_id)}"
    @horario = Seccion.horario(session)
    @nivel = historial.tipo_nivel.descripcion
    @seccion = session[:seccion_numero]
    @periodo = historial.periodo
    @periodo_transicion = Periodo::PERIODO_TRANSICION_NOTAS_PARCIALES
    @periodo_30 = Periodo::PERIODO_30    
    info_bitacora("La seccion #{session[:seccion_numero]} del curso #{Seccion.idioma(historial.idioma_id)} del horario #{Seccion.horario(session)} no fue calificada por completo, periodo #{session[:parametros][:periodo_calificacion]}")
    render :action => "buscar_estudiantes"
    return
   else
    historial.seccion.guardar_datos_calificacion(session[:usuario].ci)
    if session[:administrador] == nil
      historial.seccion.verificar_calificaciones_completas
    end
    #bitacora
      params[:notafinal].each{ |pa| 
      historial = HistorialAcademico.where(:usuario_ci => pa[0],
                                          :periodo_id => session[:periodo_id],
                                          :idioma_id => session[:idioma_id],
            :tipo_estado_inscripcion_id => "INS",
                                          :tipo_categoria_id => session[:tipo_categoria_id],
                                          :tipo_nivel_id => session[:tipo_nivel_id],
                                          :seccion_numero => session[:seccion_numero]
                                          ).limit(1).first   
      historial.cambiar_estado_calificacion(session[:tipo_categoria_id])                                    
      info_bitacora("Usuario #{session[:usuario].nombre_completo} calificó al estudiante #{historial.usuario_ci} del curso #{Seccion.idioma(historial.idioma_id)}, horario #{Seccion.horario(session)}, seccion #{session[:seccion_numero]}, con las siguientes notas: E1 = #{historial.nota_en_evaluacion(HistorialAcademico::EXAMENESCRITO1).nota}, E2 = #{historial.nota_en_evaluacion(HistorialAcademico::EXAMENESCRITO2).nota}, EOral = #{historial.nota_en_evaluacion(HistorialAcademico::EXAMENORAL).nota}, Otras = E1 = #{historial.nota_en_evaluacion(HistorialAcademico::OTRAS).nota}, nota final = #{historial.nota_final}, periodo #{session[:parametros][:periodo_calificacion]}")
      }
      info_bitacora("La seccion #{session[:seccion_numero]} del curso #{Seccion.idioma(historial.idioma_id)} del horario #{Seccion.horario(session)} fue calificada por el usuario #{session[:usuario].nombre_completo}, periodo #{session[:parametros][:periodo_calificacion]}")
      #fin bitacora
    redirect_to :action => "mostrar_calificaciones"
   end
  end
  

  
  def guardar_notas_ingles
    exitoso_global = true
    exitoso_local = true
    nota_float = -2
    historial = nil
    @tipo_nivel_id = session[:tipo_nivel_id]



    if ((session[:idioma_id] != "IT") and (@tipo_nivel_id.eql? 'CB' or  @tipo_nivel_id.eql? 'CI' or @tipo_nivel_id.eql? 'CA')) 

      arreglo = [{:nota1 => HistorialAcademico::EXAMENESCRITO1},
                 {:nota2 => HistorialAcademico::EXAMENESCRITO2},
                 {:nota3 => HistorialAcademico::EXAMENORAL},
                 {:nota4 => HistorialAcademico::OTRAS},
                 {:notafinal => "nota_final"}]
    else
      arreglo = [{:nota1 => HistorialAcademico::EXAMENESCRITO1},
                 {:nota2 => HistorialAcademico::EXAMENESCRITO2},
                 {:nota3 => HistorialAcademico::EXAMENORAL},
                 {:nota5 => HistorialAcademico::REDACCION},
                 {:nota4 => HistorialAcademico::OTRAS},
                 {:notafinal => "nota_final"}]
    end

    # if @tipo_nivel_id.eql? 'BI' or  @tipo_nivel_id.eql? 'MI' or @tipo_nivel_id.eql? 'AI'
    #   arreglo = [{:nota1 => HistorialAcademico::EXAMENESCRITO1},
    #              {:nota2 => HistorialAcademico::EXAMENESCRITO2},
    #              {:nota3 => HistorialAcademico::EXAMENORAL},
    #              {:nota5 => HistorialAcademico::REDACCION},
    #              {:nota4 => HistorialAcademico::OTRAS},
    #              {:notafinal => "nota_final"}]
    # else
    #   arreglo = [{:nota1 => HistorialAcademico::EXAMENESCRITO1},
    #              {:nota2 => HistorialAcademico::EXAMENESCRITO2},
    #              {:nota3 => HistorialAcademico::EXAMENORAL},
    #              {:nota4 => HistorialAcademico::OTRAS},
    #              {:notafinal => "nota_final"}]
    # end

    arreglo.each{|a|
      params[a.keys[0]].each_with_index{|nota,i|
        exitoso_local = true
        historial = HistorialAcademico.where(:usuario_ci => nota[0],
                                          :periodo_id => session[:periodo_id],
                                          :idioma_id => session[:idioma_id],
					                                :tipo_estado_inscripcion_id => "INS",
                                          :tipo_categoria_id => session[:tipo_categoria_id],
                                          :tipo_nivel_id => session[:tipo_nivel_id],
                                          :seccion_numero => session[:seccion_numero]
                                          ).limit(1).first     
        
        if nota[1].upcase=="PI"
          nota_float = -1
        else
          begin
            nota_float = Float(nota[1].gsub(",","."))
          rescue
            exitoso_local = exitoso_global = false
          end
        end
        
        if exitoso_local 
          if a[a.keys[0]] != "nota_final"
            nota_individual = historial.nota_en_evaluacion(a[a.keys[0]])
            nota_individual.nota = nota_float
            nota_individual.save
          else
            historial.nota_final = nota_float
            historial.save
          end
        end
      }
    }
   
   if !exitoso_global
    flash[:mensaje] = "Los datos han sido guardados, pero existen algunas notas inválidas o incompletas"
    @historiales,@usuarios = historiales_usuarios
    historial = @historiales.first
    @titulo_pagina = "Calificar sección"
    @curso = "#{Seccion.idioma(historial.idioma_id)}"
    @horario = Seccion.horario(session)
    @nivel = historial.tipo_nivel.descripcion
    @seccion = session[:seccion_numero]
    @periodo = historial.periodo
    @periodo_transicion = Periodo::PERIODO_TRANSICION_NOTAS_PARCIALES    
    info_bitacora("La seccion #{session[:seccion_numero]} del curso #{Seccion.idioma(historial.idioma_id)} del horario #{Seccion.horario(session)} no fue calificada por completo, periodo #{session[:parametros][:periodo_calificacion]}")
    render :action => "buscar_estudiantes"
    return
   else
    historial.seccion.guardar_datos_calificacion(session[:usuario].ci)
    if session[:administrador] == nil
      historial.seccion.verificar_calificaciones_completas
    end
    #bitacora
      params[:notafinal].each{ |pa| 
      historial = HistorialAcademico.where(:usuario_ci => pa[0],
                                          :periodo_id => session[:periodo_id],
                                          :idioma_id => session[:idioma_id],
					  :tipo_estado_inscripcion_id => "INS",
                                          :tipo_categoria_id => session[:tipo_categoria_id],
                                          :tipo_nivel_id => session[:tipo_nivel_id],
                                          :seccion_numero => session[:seccion_numero]
                                          ).limit(1).first   
      historial.cambiar_estado_calificacion(session[:tipo_categoria_id])                                    
      info_bitacora("Usuario #{session[:usuario].nombre_completo} calificó al estudiante #{historial.usuario_ci} del curso #{Seccion.idioma(historial.idioma_id)}, horario #{Seccion.horario(session)}, seccion #{session[:seccion_numero]}, con las siguientes notas: E1 = #{historial.nota_en_evaluacion(HistorialAcademico::EXAMENESCRITO1).nota}, E2 = #{historial.nota_en_evaluacion(HistorialAcademico::EXAMENESCRITO2).nota}, EOral = #{historial.nota_en_evaluacion(HistorialAcademico::EXAMENORAL).nota}, Otras = E1 = #{historial.nota_en_evaluacion(HistorialAcademico::OTRAS).nota}, nota final = #{historial.nota_final}, periodo #{session[:parametros][:periodo_calificacion]}")
      }
      info_bitacora("La seccion #{session[:seccion_numero]} del curso #{Seccion.idioma(historial.idioma_id)} del horario #{Seccion.horario(session)} fue calificada por el usuario #{session[:usuario].nombre_completo}, periodo #{session[:parametros][:periodo_calificacion]}")
      #fin bitacora
    redirect_to :action => "mostrar_calificaciones"
   end
  end
  
  
  def mostrar_calificaciones
    @historiales,@usuarios = historiales_usuarios
    historial = @historiales.first
    @titulo_pagina = "Calificaciones"
    @curso = "#{Seccion.idioma(historial.idioma_id)}"
    @horario = Seccion.horario(session)
    @nivel = historial.tipo_nivel.descripcion
    @seccion = session[:seccion_numero]
    @periodo = historial.periodo
    @periodo_transicion = Periodo::PERIODO_TRANSICION_NOTAS_PARCIALES
    @periodo_30 = Periodo::PERIODO_30

    @tipo_nivel_id = session[:tipo_nivel_id]
  end
  
  def generar_pdf
    
    @periodo_30 = Periodo::PERIODO_30
    @historiales,@usuarios = historiales_usuarios
    historial = @historiales.first
    @periodo = historial.periodo
    info_bitacora("Usuario #{session[:usuario].nombre_completo} generó pdf del curso #{Seccion.idioma(historial.idioma_id)}, horario #{Seccion.horario(session)}, seccion #{session[:seccion_numero]},periodo #{session[:parametros][:periodo_calificacion]}")
    historiales,usuarios = historiales_usuarios

  if @periodo.es_mayor_igual_que? @periodo_30
    pdf = DocumentosPDF.notas_30(historiales,session)
  else
    pdf = DocumentosPDF.notas(historiales,session)
  end

    send_data pdf.render,:filename => "notas.pdf",
                         :type => "application/pdf", :disposition => "attachment"
  end

  def guardar_nota_individual
    guardo = true
    historial = HistorialAcademico.where(:usuario_ci => params[:ci],
                                         :idioma_id => params[:idioma],
                                         :tipo_categoria_id => params[:tipo_categoria],
                                         :tipo_nivel_id => params[:tipo_nivel],
                                         :periodo_id => params[:periodo],
                                         :seccion_numero => params[:seccion]
                                         ).limit(1).first
    nota = params[:nota_individual].upcase
    if nota == "PI"
      historial.nota_final = -1
      historial.tipo_estado_calificacion_id = nota
    elsif nota == "SC"
      historial.nota_final = -2
      historial.tipo_estado_calificacion_id = nota      
    elsif HistorialAcademico::NOTASSTRING.include? nota
      historial.nota_final = nota.to_i
      historial.tipo_estado_calificacion_id = (nota.to_i > 10) ? "AP" : "RE"
    else
      guardo = false
    end

    if guardo
      flash[:mensaje] = "Nota Guardada Satisfactoriamente"
      historial.save
      info_bitacora("Se modificó la nota del historial académico (periodo #{params[:periodo]}) con #{nota}")
    else
      info_bitacora("Error modificando la nota del historial académico (periodo #{params[:periodo]}), intentó con #{nota}")
      flash[:mensaje] = "Nota Inválida"
    end
    redirect_to :controller => "admin_estudiante", :action => "opciones_menu"
  end

end
