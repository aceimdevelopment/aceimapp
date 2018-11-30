#creada por db2models
class EstudianteCurso < ApplicationRecord
   
  REGULAR = "regular"
  REINTEGRO = "reintegro"
  REINICIO = "reinicio" 
  MODIFICACION = "modificacion"

  # CLAVE PRIMARIA COMPUESTA
  self.primary_keys = :usuario_ci,:idioma_id,:tipo_categoria_id

  # ASOCIACIONES
  belongs_to :usuario,
    foreign_key: 'usuario_ci'

  belongs_to :tipo_convenio
  belongs_to :tipo_curso,
    foreign_key: ['idioma_id','tipo_categoria_id']  

  has_many :historiales_academicos,
    foreign_key: [:usuario_ci,:idioma_id,:tipo_categoria_id]
  accepts_nested_attributes_for :historiales_academicos

  belongs_to :estudiante,
    foreign_key: 'usuario_ci'
  
  # FUNCIONES  
  def descripcion 
    "Estudiante - #{tipo_curso.descripcion}"
  end

  def estudiante_nivelacion
    EstudianteNivelacion.where(:usuario_ci => usuario_ci, :idioma_id => idioma_id, :tipo_categoria_id => tipo_categoria_id)
  end

  def ultimo_historial
    HistorialAcademico.where(
        :usuario_ci => usuario_ci,
        :idioma_id => idioma_id,
        :tipo_categoria_id => tipo_categoria_id
      ).sort_by{|x| "#{x.periodo.ano}-#{x.periodo_id}"}.last
  end
  
  def ultimo_historial_aprobado
    HistorialAcademico.where(
        :usuario_ci => usuario_ci,
        :idioma_id => idioma_id,
        :tipo_categoria_id => tipo_categoria_id,
        :tipo_estado_calificacion_id => "AP"
      ).sort_by{|x| x.periodo.ordenado}.last
  end
  
  def tipo_estudiante
    periodo_inscripcion = ParametroGeneral.periodo_inscripcion
    letra, ano = periodo_inscripcion.id.split("-")                    
    ano = ano.to_i
    ultimo = ultimo_historial        
    return REINICIO unless ultimo
    letra_ultimo, ano_ultimo = ultimo.periodo_id.split("-")
    ano_ultimo = ano_ultimo.to_i
    return REGULAR if letra == letra_ultimo && ano == ano_ultimo
    return REINICIO if ano_ultimo < (ano-2) 
    if ano_ultimo == (ano-2) 
      return REINICIO if letra_ultimo[0] <= letra[0]
      return REINTEGRO
    end
    case letra
      when "A"                
        return REGULAR if (letra_ultimo == "D" || letra_ultimo == "C") && (ano_ultimo == (ano-1))
        return REINTEGRO
      when "B"                
        return REGULAR if (letra_ultimo == "D" && ano_ultimo == (ano-1)) || (letra_ultimo == "A" && ano_ultimo == ano)
        return REINTEGRO
      when "C"                
        return REGULAR if (letra_ultimo == "B" && ano_ultimo == ano) || (letra_ultimo == "A" && ano_ultimo == ano)
        return REINTEGRO
      when "D"                
        return REGULAR if (letra_ultimo == "C" && ano_ultimo == ano) #|| (letra_ultimo == "B" && ano_ultimo == ano && tipo_convenio_id != "REG")
        return MODIFICACION if (letra_ultimo == "B" && ano_ultimo == ano)
        return REINTEGRO  
      else 
        return MODIFICACION   
     end
  end
  
  def proximo_historial
    historial = HistorialAcademico.new
    historial.usuario_ci = usuario_ci
    historial.tipo_categoria_id = tipo_categoria_id
    historial.idioma_id = idioma_id
    periodo_actual = ParametroGeneral.periodo_inscripcion
    historial.periodo_id = periodo_actual.id
    historial.tipo_convenio_id = tipo_convenio_id 
    historial.tipo_estado_calificacion_id = "SC"
    historial.tipo_estado_inscripcion_id = "PRE"
    historial.nota_final = -2
    historial.numero_deposito = ""
    ultimo = ultimo_historial
    historial.seccion_numero = nil
    inicial = Curso.where(:idioma_id => idioma_id,
      :tipo_categoria_id => tipo_categoria_id,
      :grado => 1).limit(1).first
    

    estado = tipo_estudiante
    if estado == REGULAR || estado == MODIFICACION
      if ultimo.aprobo_curso?
        grado = ultimo.curso.grado+1
        prox = Curso.where(:idioma_id => idioma_id,
          :tipo_categoria_id => tipo_categoria_id,
          :grado => grado).limit(1).first
        if prox 
          historial.tipo_nivel_id = prox.tipo_nivel_id
          historial.seccion_numero = ultimo.seccion_numero
          if !ultimo || !ultimo.seccion || !historial || !historial.seccion || ultimo.seccion.horario !=  historial.seccion.horario
            historial.seccion_numero = nil
          end
        else 
          if ultimo.tipo_categoria_id == "NI" && ultimo.tipo_nivel_id == "CI"
            historial.tipo_nivel_id = "BI"
            historial.tipo_categoria_id = "TE"
            
            ec1 = EstudianteCurso.where(:usuario_ci => historial.usuario_ci,
              :tipo_categoria_id => "TE",
              :idioma_id => "ID") 
            
            unless ec1
              ec1 = EstudianteCurso.new
              ec1.tipo_categoria_id = historial.tipo_categoria_id
              ec1.usuario_ci = historial.usuario_ci
              ec1.idioma_id = historial.idioma_id
              ec1.tipo_convenio_id = historial.tipo_convenio_id
              ec1.save
            end 
            
            historial.seccion_numero = nil
          else
            raise Exception.new "Ya se graduo en #{tipo_curso.descripcion}"
          end
        end
      else #reprobado
        historial.tipo_convenio_id = "REG"
        self.tipo_convenio_id = "REG"
        self.save
        historial.tipo_nivel_id = ultimo.tipo_nivel_id
      end
    elsif estado == REINTEGRO
      ultimo_aprobado = ultimo_historial_aprobado
      if ultimo_aprobado
        historial.tipo_nivel_id = ultimo_aprobado.tipo_nivel_id
      else
        historial.tipo_nivel_id = inicial.tipo_nivel_id
      end
    elsif estado == REINICIO
      historial.tipo_nivel_id = inicial.tipo_nivel_id
    end  
    historial.cuenta_bancaria_id = historial.cuenta_nueva
    return historial
  end 
  
end
