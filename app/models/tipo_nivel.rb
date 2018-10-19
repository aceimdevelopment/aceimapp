#creada por db2models
class TipoNivel < ApplicationRecord

  has_many :curso,
    :class_name => 'Curso',
    :foreign_key => ['tipo_nivel_id']

  has_many :archivos
  accepts_nested_attributes_for :archivos

  PERIODO = ParametroGeneral.periodo_actual.id
  def preinscritos
    HistorialAcademico.count(:conditions => ["periodo_id = ? AND tipo_nivel_id = ?",PERIODO, id])
  end
  
  def preinscritos2(idioma)
    HistorialAcademico.count(:conditions => ["periodo_id = ? AND tipo_nivel_id = ? AND idioma_id=?",PERIODO, id,idioma])
  end

  def inscritos
    HistorialAcademico.count(:conditions => ["periodo_id = ? AND tipo_nivel_id = ? AND tipo_estado_inscripcion_id=?",PERIODO, id,"INS"])
  end
  
  def inscritos2(idioma)
    HistorialAcademico.count(:conditions => ["periodo_id = ? AND tipo_nivel_id = ? AND tipo_estado_inscripcion_id=? AND idioma_id=?",PERIODO, id,"INS",idioma])
  end
  
  def secciones_abiertas
    Seccion.count(:conditions => ["tipo_nivel_id = ? AND periodo_id = ? AND esta_abierta=?",id,PERIODO, true] )
  end
  
  def secciones_abiertas2(idioma)
    Seccion.count(:conditions => ["tipo_nivel_id = ? AND periodo_id = ? AND esta_abierta=? AND idioma_id=?",id,PERIODO, true, idioma])
  end

  def secciones
    Seccion.count(:conditions => ["tipo_nivel_id = ? AND periodo_id = ?",id,PERIODO] )
  end
  
  def secciones2(idioma)
    Seccion.count(:conditions => ["tipo_nivel_id = ? AND periodo_id = ? AND idioma_id=?",id,PERIODO,idioma] )
  end

end
