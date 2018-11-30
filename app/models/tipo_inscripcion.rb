# encoding: utf-8

class TipoInscripcion < ApplicationRecord

  has_many :inscripciones,
    :class_name => 'Inscripcion',
    :foreign_key => 'tipo_inscripcion_id'

  accepts_nested_attributes_for :inscripciones

  # has_many :cursos, :through => :inscripcion, :source => :tipo_curso

end