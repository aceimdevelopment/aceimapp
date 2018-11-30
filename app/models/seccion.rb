#creada por db2models
class Seccion < ApplicationRecord

  #autogenerado por db2models
  # set_primary_keys :periodo_id,:idioma_id,:tipo_categoria_id,:tipo_nivel_id,:seccion_numero
  self.primary_keys = :periodo_id,:idioma_id,:tipo_categoria_id,:tipo_nivel_id,:seccion_numero

  #autogenerado por db2models
  belongs_to :instructor,
  :class_name => 'Instructor',
  :foreign_key => ['instructor_ci']

  #autogenerado por db2models
  belongs_to :instructor_evaluador,
  :class_name => 'Instructor',
  :foreign_key => ['instructor_evaluador_ci']

  #autogenerado por db2models
  belongs_to :curso_periodo,
  :class_name => 'CursoPeriodo',
  :foreign_key => ['periodo_id','idioma_id','tipo_categoria_id','tipo_nivel_id']

  belongs_to :tipo_nivel,
  :class_name => 'TipoNivel',
  :foreign_key => ['tipo_nivel_id']

  has_many :historiales_academicos,
  :class_name => 'HistorialAcademico',
  :foreign_key => ['periodo_id','idioma_id','tipo_categoria_id','tipo_nivel_id', 'seccion_numero']
  accepts_nested_attributes_for :historiales_academicos

  has_one :horario_seccion2,
  :class_name => 'HorarioSeccion',
  :foreign_key => ['periodo_id','idioma_id','tipo_categoria_id','tipo_nivel_id', 'seccion_numero']
  accepts_nested_attributes_for :horario_seccion2


  def horario_seccion
    HorarioSeccion.where(:periodo_id=>periodo_id,:idioma_id=>idioma_id,:tipo_categoria_id=>tipo_categoria_id,:tipo_nivel_id=>tipo_nivel_id,:seccion_numero=>seccion_numero)
  end

  belongs_to :curso,
    :class_name => 'Curso',
    :foreign_key => ['tipo_nivel_id','idioma_id','tipo_categoria_id']

  belongs_to :tipo_curso,
    :class_name => 'TipoCurso',
    :foreign_key => ['idioma_id','tipo_categoria_id']


  belongs_to :bloque_horario,
  :class_name => 'BloqueHorario',
  :foreign_key => ['bloque_horario_id']
  
  belongs_to :idioma,
  :class_name => 'Idioma',
  :foreign_key => ['idioma_id']


  def self.con_cupo_tipo_curso_abierto_nuevo_perido_actual
    categorias = TipoCurso.where(:inscripcion_abierta =>true).collect{|c| c.tipo_categoria_id}.uniq
    idiomas = TipoCurso.where(:inscripcion_abierta =>true).collect{|c| c.idioma_id}.uniq
    periodo_id =  ParametroGeneral.periodo_inscripcion.id
    secciones = Seccion.where(:periodo_id => periodo_id, :idioma_id => idiomas, :tipo_categoria_id => categorias, :esta_abierta => true).delete_if{|s| s.curso.grado != 1}.delete_if{|s| !s.hay_cupo?} 
    return secciones
  end

  def self.secciones_para_inscripciones_cursos_abiertas
    categorias = Inscripcion.where(:tipo_estado_inscripcion_curso_id => 'AB').collect{|c| c.tipo_categoria_id}.uniq
    idiomas = Inscripcion.where(:tipo_estado_inscripcion_curso_id => 'AB').collect{|c| c.idioma_id}.uniq
    periodo_id =  ParametroGeneral.periodo_inscripcion.id
    secciones = Seccion.where(:periodo_id => periodo_id, :idioma_id => idiomas, :tipo_categoria_id => categorias, :esta_abierta => true).delete_if{|s| s.curso.grado != 1}.delete_if{|s| !s.hay_cupo?} 
    return secciones
  end

  def cupo
    # cantidad = historiales_academicos.count
    cantidad = HistorialAcademico.where(:periodo_id => periodo_id, :idioma_id => idioma_id, :tipo_categoria_id => tipo_categoria_id, :tipo_nivel_id => tipo_nivel_id, :seccion_numero => seccion_numero).count
    resto = ParametroGeneral.capacidad_curso - cantidad     
    return 0 if resto<=0
    resto
  end
  
  def hay_cupo?
    cupo > 0
    #cantidad = historial_academico.size
    #cantidad < ParametroGeneral.capacidad_curso
  end



  def self.idioma(idioma)
    Idioma.where(:id => idioma).limit(1).first.descripcion
  end

  def self.tipo_categoria(tipo_categoria)
    TipoCategoria.where(:id => tipo_categoria).limit(0).first.descripcion
  end
  def self.horario(session)
    retorno = ""
    horario_seccion = HorarioSeccion.where(:periodo_id => session[:periodo_id],
    :idioma_id => session[:idioma_id],
    :tipo_categoria_id => session[:tipo_categoria_id],
    :tipo_nivel_id => session[:tipo_nivel_id],
    :seccion_numero => session[:seccion_numero])

    dias_id = horario_seccion.collect{|hs| hs.tipo_dia_id}

    dias = TipoDia.where(:id => dias_id).order("orden").collect{|d| d.descripcion}.join(" - ")

    hora_id = horario_seccion.collect{|hs| hs.tipo_hora_id}

    hora = TipoHora.where(:id => hora_id).limit(0).first
    hora = " (#{hora.hora_entrada.strftime("%I:%M%p")} - #{hora.hora_salida.strftime("%I:%M%p")})"
    retorno = dias + hora
  end

  def es_horario_inscripcion? horario_inscripcion

      dias_id = horario_seccion.collect{|hs| hs.tipo_dia_id}
    if horario_inscripcion.eql? 'AMBOS'
      return true
    elsif horario_inscripcion.eql? 'SABATINOS'
      return dias_id.include? 'SA' 
    elsif horario_inscripcion.eql? 'SEMANAL'
      return (not dias_id.include? 'SA')       
    else      
      return false
    end

    return true if (horario.eql? 'SABATINO')
    
  end

  def horario
    retorno = ""
    horario_seccion = HorarioSeccion.where(:periodo_id => periodo_id,
    :idioma_id => idioma_id,
    :tipo_categoria_id => tipo_categoria_id,
    :tipo_nivel_id => tipo_nivel_id,
    :seccion_numero => seccion_numero)

    dias_id = horario_seccion.collect{|hs| hs.tipo_dia_id}

    dias = TipoDia.where(:id => dias_id).order("orden").collect{|d| d.descripcion}.join(" - ")

    hora_id = horario_seccion.collect{|hs| hs.tipo_hora_id}

    hora = TipoHora.where(:id => hora_id).limit(1).first
    return "-" unless hora
    hora = " (#{hora.hora_entrada.strftime("%I:%M%p")} - #{hora.hora_salida.strftime("%I:%M%p")})"
    retorno = dias + hora
  end

  def horario_sec
    retorno = ""
    horario_seccion = HorarioSeccion.where(:periodo_id => periodo_id,
    :idioma_id => idioma_id,
    :tipo_categoria_id => tipo_categoria_id,
    :tipo_nivel_id => tipo_nivel_id,
    :seccion_numero => seccion_numero)

		dias_id = horario_seccion.collect{|hs| hs.tipo_dia_id}

		dias = TipoDia.where(:id => dias_id).order("orden").collect{|d| d.descripcion}.join(" - ")

    dias1 = TipoDia.where(:id => dias_id).order("orden").collect{|d| d.id}.join(".")

    hora_id = horario_seccion.collect{|hs| hs.tipo_hora_id}

	  hora = TipoHora.where(:id => hora_id).limit(1).first

		retorno = dias1 + "." + hora.id

    return retorno
  end
	
	def ejemplo
		puts "X"
	end

  def horarios

    parejas = TipoBloque.where(["pareja != ?", "-1"]).group("pareja").order("orden ASC")

    retorno = []

    retorno[0] = {:dias => "", :total=> ""}
    retorno[1] = {:dias => "", :total=> ""} 
    retorno[2] = {:dias => "", :total=> ""} 
    retorno[3] = {:dias => "", :total=> ""} 
    retorno[4] = {:dias => "", :total=> ""} 



    i = 0

    parejas.each{|pareja|


		  bloque_horario = TipoBloque.where(["pareja != ? AND pareja = ?", "-1", pareja.pareja]).order("orden ASC")

		  dias_id = bloque_horario.collect{|bh| bh.tipo_dia_id}

		  dias = TipoDia.where(:id => dias_id).order("orden").collect{|d| d.descripcion}.join(" - ")

      dias1 = TipoDia.where(:id => dias_id).order("orden").collect{|d| d.id}.join(".")

		  hora_id = bloque_horario.collect{|bh| bh.tipo_hora_id}

		  hora = TipoHora.where(:id => hora_id).limit(1).first

      retorno[i]["dias"] = dias1 + "." + hora.id

		  hora = " (#{hora.hora_entrada.strftime("%I:%M%p")} - #{hora.hora_salida.strftime("%I:%M%p")})"

		  retorno[i]["total"] = dias + hora


      i = i + 1

		}

    return retorno

    
  end


#  def idioma
#    Idioma.where(:id => idioma_id).limit(1).first
#  end


  def tipo_categoria
    TipoCategoria.find(tipo_categoria_id)
  end

#  def tipo_nivel
#    TipoNivel.where(:id => tipo_nivel_id).limit(1).first
#  end

  def preinscritos

    HistorialAcademico.count(:conditions => ["tipo_nivel_id = ? AND idioma_id = ? AND \
    tipo_categoria_id = ? AND periodo_id = ? AND seccion_numero = ?",
      tipo_nivel_id,idioma_id,
    tipo_categoria_id, periodo_id,seccion_numero])

  end

  def inscritos

    HistorialAcademico.count(:conditions => ["tipo_nivel_id = ? AND idioma_id = ? AND \
    tipo_categoria_id = ? AND periodo_id = ? AND seccion_numero = ? AND tipo_estado_inscripcion_id=?",
      tipo_nivel_id,idioma_id,
    tipo_categoria_id, periodo_id,seccion_numero, "INS"])

  end
  
  def listado_estudiantes_inscritos
    HistorialAcademico.all(:conditions => ["tipo_nivel_id = ? AND idioma_id = ? AND \
    tipo_categoria_id = ? AND periodo_id = ? AND seccion_numero = ? AND tipo_estado_inscripcion_id=?",
      tipo_nivel_id,idioma_id,
    tipo_categoria_id, periodo_id,seccion_numero, "INS"])

  end
  
  
  def estudiantes_inscritos

    HistorialAcademico.all(:conditions => ["tipo_nivel_id = ? AND idioma_id = ? AND \
    tipo_categoria_id = ? AND periodo_id = ? AND seccion_numero = ? AND tipo_estado_inscripcion_id<>?",
      tipo_nivel_id,idioma_id,
    tipo_categoria_id, periodo_id,seccion_numero, "PRE"])

  end
  

  def curso
    Curso.where(:idioma_id => idioma_id, :tipo_categoria_id => tipo_categoria_id, :tipo_nivel_id => tipo_nivel_id).limit(1).first
  end



  def aula
    if horario_seccion.first.aula_id == "CER"
      "No Asignada"
    else
      "#{horario_seccion.collect{|hs| hs.dia_aula}.join(" | ")}, #{horario_seccion.first.aula.tipo_ubicacion.descripcion} "
    end
  end

  def aula_corta
    if not horario_seccion.first
      "Sin Aula"
    elsif horario_seccion.first.aula_id == "CER"
      "No Asignada"
    else
      "#{horario_seccion.sort_by{|x| x.dia.orden}.collect{|hs| hs.dia_aula}.join(" | ")}"
    end
  end

  def aula_cortica
    if horario_seccion.first.aula_id == "CER"
      "No Asignada"
    else
      "#{horario_seccion.first.aula.descripcion}"
    end
  end
  def guardar_datos_calificacion(usuario_ci)
    self.usuario_que_califico_ci = usuario_ci
    self.fecha_que_califico = Time.now
    self.esta_calificada = true
    self.save
  end

  def verificar_calificaciones_completas
    ins = self.instructor
    if (ins.cursos_a_corregir.count - ins.cursos_corregidos.count) == 0
      notificacion = NotificacionCalificacion.new
      notificacion.periodo_id = ParametroGeneral.periodo_calificacion
      notificacion.usuario_ci = self.instructor_ci
      notificacion.save
    end
  end
  
  def descripcion_inscritos
    cc=ParametroGeneral.capacidad_curso                                 
    cu = cupo                                                         
    if cupo > 0
      return "#{descripcion_corta} - (#{preinscritos}/#{inscritos}), CUPO: #{cu}"
    end                                                                          
    return "#{descripcion_corta} - (#{preinscritos}/#{inscritos}), CUPO: 0 -- ESTA LLENA"
  end

  def descripcion_sin_horario
    "#{curso.descripcion} - #{"%002i"%seccion_numero}"
  end
  
  def descripcion
    "#{curso.descripcion} - #{horario} - #{"%002i"%seccion_numero}"
  end

  def descripcion_corta
    "#{"%002i"%seccion_numero}: #{horario}"
  end

  def descripcion_con_periodo
    "[#{periodo_id}] - #{descripcion}"
  end
  
  def mach_horario?(horario2)
    if horario == horario2
      return true
    end  
    false
  end
  
end
