# encoding: utf-8

class Idioma < ApplicationRecord

  has_many :tipo_curso,
    :class_name => 'TipoCurso',
    :foreign_key => ['idioma_id']

  has_many :categorias, :through => :tipo_curso, :source => :tipo_categoria

  has_many :archivos
  accepts_nested_attributes_for :archivos

  # has_and_belongs_to_many :categorias, :class_name => 'idioma_categoria', :foreign_key => ['tipo_categoria_id']

  # has_many :idioma_categoria,
  #   :class_name => 'IdiomaCategoria',
  #   :foreign_key => 'idioma_id'

  # has_many :categorias, :through => :idioma_categoria, :source => :tipo_categoria



  def descripcion_idioma
    "#{descripcion}"
  end

  def preinscritos
    @periodo = ParametroGeneral.periodo_actual
    HistorialAcademico.count(:conditions => ["idioma_id = ? AND periodo_id = ?",id,@periodo.id])
  end
  
  def preinscritos2(nivel)
    @periodo = ParametroGeneral.periodo_actual
    HistorialAcademico.count(:conditions => ["periodo_id = ? AND idioma_id = ? AND tipo_nivel_id=?",@periodo.id, id,nivel])
  end
  
  def inscritos  
    @periodo = ParametroGeneral.periodo_actual
    HistorialAcademico.count(:conditions => ["idioma_id = ? AND periodo_id = ? AND tipo_estado_inscripcion_id=?",id,@periodo.id,"INS"])
  end
  
  def inscritos2(nivel)
    @periodo = ParametroGeneral.periodo_actual
    HistorialAcademico.count(:conditions => ["periodo_id = ? AND idioma_id = ? AND tipo_estado_inscripcion_id=? AND tipo_nivel_id=?",@periodo.id, id,"INS",nivel])
  end
  
  def secciones_abiertas
    Seccion.count(:conditions => ["idioma_id = ? AND periodo_id = ? AND esta_abierta=?",id,@periodo.id, true])
  end
  
  def secciones_abiertas2(nivel)
    Seccion.count(:conditions => ["idioma_id = ? AND periodo_id = ? AND esta_abierta=? AND tipo_nivel_id=?",id,@periodo.id, true, nivel])
  end

  def secciones
    Seccion.count(:conditions => ["idioma_id = ? AND periodo_id = ?",id,@periodo.id] )
  end

  def secciones2(nivel)
    Seccion.count(:conditions => ["idioma_id = ? AND periodo_id = ? AND tipo_nivel_id=?",id,@periodo.id,nivel] )
  end


end
