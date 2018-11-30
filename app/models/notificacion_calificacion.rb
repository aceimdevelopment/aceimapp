# encoding: utf-8

class NotificacionCalificacion < ApplicationRecord

  self.primary_keys = :periodo_id, :usuario_ci

  belongs_to :usuario,
    :class_name => 'Usuario',
    :foreign_key => ['usuario_ci']
  
  belongs_to :periodo,
    :class_name => 'Periodo',
    :foreign_key => ['periodo_id']

end
