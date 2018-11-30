# encoding: utf-8
class Instructor < ApplicationRecord

  self.primary_keys = :usuario_ci

  belongs_to :usuario,
  foreign_key: :usuario_ci
  accepts_nested_attributes_for :usuario

  has_many :horario_disponible_instructor,
    :class_name => 'HorarioDisponibleInstructor',
    :foreign_key => ['instructor_ci']
  
  def domina
    Domina.where(:instructor_usuario_ci => usuario_ci)
  end
  
  def domina_descripcion
    Domina.where(:instructor_usuario_ci => usuario_ci).collect{|d| d.idioma.descripcion}.join("-")
  end
  
  def cursos_a_corregir
    Seccion.where(:instructor_ci => usuario_ci, :periodo_id => ParametroGeneral.periodo_calificacion,:esta_abierta => true)
  end
  
  def cursos_corregidos
    Seccion.where(:instructor_ci => usuario_ci,
    :periodo_id => ParametroGeneral.periodo_calificacion,
    :esta_calificada => true,
    :esta_abierta => true)  
  end
  
  def descripcion  
    return " NO ASIGNADO" if usuario_ci == "-----"   
    return "#{nombre_completo} (#{usuario.telefono_movil})"
  end 
  
  
  def nombre_completo
  	return " NO ASIGNADO" if usuario_ci == "-----"   
  	return usuario.nombre_completo
  end   
  
  def clave_propuesta
    parte_apellido = "#{usuario.apellidos}".downcase.normalizar[0..3] 
    parte_cedula = "#{usuario.ci}".normalizar
    parte_cedula = parte_cedula[(parte_cedula.size-4)..(parte_cedula.size-1)]
    "#{parte_apellido}#{parte_cedula}"
  end   
  
  def estado
    dif = self.cursos_a_corregir.count - self.cursos_corregidos.count
    if dif == 0
      return "Completo"
    elsif dif == self.cursos_a_corregir.count
      return "Ninguno"
    else
      return "Intermedio"
    end
  end  
  
  def fecha_que_califico(periodo)
    Seccion.where(:instructor_ci => usuario_ci, 
                  :periodo_id => periodo).order("fecha_que_califico DESC").limit(1).first.fecha_que_califico
  end    
  
  def notificacion(periodo)
    nota = NotificacionCalificacion.where(:usuario_ci => usuario_ci, :periodo_id => periodo).limit(1).first
    if nota == nil
      return nil
    elsif nota.correo_enviado
      return "Enviado"
    else
      return "No Enviado"
    end
  end
  
  def fecha_notificacion(periodo)
    nota = NotificacionCalificacion.where(:usuario_ci => usuario_ci, :periodo_id => periodo).limit(1).first.fecha_hora
  end
  
  def guardar_notificacion(periodo)
    notificacion = NotificacionCalificacion.where(:usuario_ci => usuario_ci, :periodo_id => periodo).limit(0).first
    notificacion.correo_enviado = true
    notificacion.fecha_hora = Time.now
    notificacion.save
  end
  
  def seccion_periodo
    periodo_actual = ParametroGeneral.periodo_actual
    Seccion.where(:periodo_id=>periodo_actual.id, :instructor_ci=>usuario_ci)
  end
  
  def mach_horario_seccion_instructor?(horario_id)     
      if seccion = seccion_periodo
        seccion.each do |s|
          
          if s.mach_horario?(horario_id)
		        return true
	        end
		      #HorarioSeccion.where(:aula_id=>id, :tipo_hora_id=>hora_id,:tipo_dia_id=>dia_id).delete_if{|x| !x.seccion.esta_abierta}
	      end
      end
      false
  end
  
  def secciones_que_dicta(periodo_id)
    Seccion.where(:instructor_ci => usuario_ci, :periodo_id => periodo_id,:esta_abierta => true)
  end
  
  def horario_secciones_que_dicta(periodo)
    secciones = Seccion.where(:instructor_ci => usuario_ci, :periodo_id => periodo,:esta_abierta => true).sort_by{|x| "#{x.tipo_curso.id}-#{'%03i'%x.curso.grado}-#{'%03i'%x.seccion_numero}"}
    horarios = secciones.collect{|z| z.horario}.uniq
  end
  
end
