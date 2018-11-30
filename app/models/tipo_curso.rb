#creada por db2models
class TipoCurso < ApplicationRecord

  #autogenerado por db2models
  # set_primary_keys :idioma_id,:tipo_categoria_id
  self.primary_keys = :idioma_id,:tipo_categoria_id

  #autogenerado por db2models
  belongs_to :idioma

  #autogenerado por db2models
  belongs_to :tipo_categoria
  
  has_many :inscripciones,
    :class_name => 'Inscripcion',
    :foreign_key => ['idioma_id','tipo_categoria_id']

  accepts_nested_attributes_for :inscripciones

  has_many :secciones,
    :class_name => 'Seccion',
    :foreign_key => ['idioma_id','tipo_categoria_id']

  accepts_nested_attributes_for :secciones


  # has_many :tipo_inscripciones, :through => :inscripcion, :source => :tipo_inscripcion

  has_many :cursos,
    :class_name => 'Curso',
    :foreign_key => ['idioma_id','tipo_categoria_id']

  accepts_nested_attributes_for :cursos
  
  has_many :estudiantes_nivelacion,
    :class_name => 'EstudianteNivelacion',
    :foreign_key => ['idioma_id','tipo_categoria_id']  

  accepts_nested_attributes_for :estudiantes_nivelacion

  def descripcion
    "#{idioma.descripcion} (#{tipo_categoria.descripcion})"
  end

  def arancel_bs
    if tipo_categoria_i.eql? "NI"
      arancel = "#{ParametroGeneral.costo_ninos_i}Bs.S" 
    elsif tipo_inscripcion_id.eql? 'NU'
      arancel = "#{ParametroGeneral.costo_nuevos_i}Bs.S" 
    else
      arancel = "#{ParametroGeneral.costo_examen_i}Bs.S"
    end 
    return arancel
  end

end
