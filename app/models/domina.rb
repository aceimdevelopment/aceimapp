# encoding: utf-8

class Domina < ApplicationRecord
  # CLAVE PRIMARIA COMPUESTA
  self.primary_keys = :idioma_id,:instructor_usuario_ci

  # ASOCIACIONES
  belongs_to :idioma
  belongs_to :instructor_usuario,
    :class_name => 'Instructor',
    :foreign_key => ['instructor_usuario_ci']

end
