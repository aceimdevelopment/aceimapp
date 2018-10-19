# encoding: utf-8

#creada por db2models
class TipoCategoria < ApplicationRecord

  has_many :tipo_curso,
    :class_name => 'TipoCurso',
    :foreign_key => ['tipo_categoria_id']

  has_many :idiomas, :through => :tipo_curso, :source => :idioma
	
  def complemento
  	return "(#{descripcion})" if id !="AD"
    return ""
  end

	# has_and_belongs_to_many :idiomas, :class_name => 'idioma_categoria', :foreign_key => ['tipo_categoria_id']

	has_many :idioma_categoria,
	:class_name => 'IdiomaCategoria',
	:foreign_key => 'tipo_categoria_id'

	has_many :idiomas, :through => :idioma_categoria, :source => :idioma

end
