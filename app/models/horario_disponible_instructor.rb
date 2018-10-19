# encoding: utf-8

class HorarioDisponibleInstructor < ApplicationRecord

  self.primary_keys = :instructor_ci, :idioma_id, :bloque_horario_id

  belongs_to :instructor,
    foreign_key: 'instructor_ci'

  belongs_to :idioma,
    foreign_key: 'idioma_id'

  belongs_to :bloque_horario,
    foreign_key: 'bloque_horario_id'
  
  def instructor_nombre
    return instructor_ci unless instructor
    return instructor.descripcion
  end

end


