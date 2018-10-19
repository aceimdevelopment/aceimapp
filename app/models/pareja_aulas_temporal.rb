# encoding: utf-8

class ParejaAulasTemporal < ApplicationRecord

  self.primary_keys = :tipo_hora_id,:tipo_dia_id,:aula_id

  belongs_to :tipo_bloque,
    :class_name => 'TipoBloque',
    :foreign_key => ['tipo_hora_id','tipo_dia_id']

  belongs_to :aula,
    :class_name => 'Aula',
    :foreign_key => ['aula_id']

  belongs_to :tipo_dia,
    :class_name => 'TipoDia',
    :foreign_key => ['tipo_dia_id']


end
