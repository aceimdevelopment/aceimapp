class CursoPeriodo < ApplicationRecord

  # CLAVE PRIMARIA COMPUESTA
  self.primary_keys = :periodo_id,:idioma_id,:tipo_categoria_id,:tipo_nivel_id

  # ASOCIACIONES
  belongs_to :curso,
    foreign_key: ['tipo_nivel_id','idioma_id','tipo_categoria_id']

  belongs_to :periodo

  has_many :detalles_facturas,
    foreign_key: ['periodo_id' , 'idioma_id' , 'tipo_categoria_id' , 'tipo_nivel_id']
  accepts_nested_attributes_for :detalles_facturas

  has_many :examenes,
    foreign_key: [:periodo_id, :curso_idioma_id,:curso_tipo_categoria_id, :curso_tipo_nivel_id]
  accepts_nested_attributes_for :examenes

  has_many :secciones,
    foreign_key: ['periodo_id' , 'idioma_id' , 'tipo_categoria_id' , 'tipo_nivel_id']
  accepts_nested_attributes_for :secciones

  # FUNCIONES
  def preinscritos
    @periodo = ParametroGeneral.periodo_actual
    HistorialAcademico.count(:conditions => ["idioma_id = ? AND periodo_id = ? AND tipo_categoria_id = ? AND tipo_nivel_id = ?",idioma_id,@periodo.id, tipo_categoria_id,tipo_nivel_id])
  end

  def inscritos
    @periodo = ParametroGeneral.periodo_actual
    HistorialAcademico.count(:conditions => ["idioma_id = ? AND periodo_id = ? AND tipo_categoria_id = ? AND tipo_nivel_id = ? AND tipo_estado_inscripcion_id=?",idioma_id,@periodo.id,tipo_categoria_id,tipo_nivel_id,"INS"])
  end
  
  def tipo_nivel
    TipoNivel.find(tipo_nivel_id)
  end
  
  def tipo_categoria  
  	TipoCategoria.find(tipo_categoria_id)
  end

  def idioma  
  	Idioma.find(idioma_id)
  end

  def descripcion_categoria
    "#{idioma.descripcion} #{tipo_categoria.descripcion}"
  end

  def descripcion
    "Curso de #{idioma.descripcion} #{tipo_categoria.descripcion} - Nivel #{tipo_nivel.descripcion} (Periodo#{periodo.id})"
  end
end
