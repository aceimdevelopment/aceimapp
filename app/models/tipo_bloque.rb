# encoding: utf-8

#creada por db2models
class TipoBloque < ApplicationRecord

  #autogenerado por db2models
  # set_primary_keys :tipo_hora_id,:tipo_dia_id
  self.primary_keys = :tipo_hora_id,:tipo_dia_id


  #autogenerado por db2models
  belongs_to :tipo_hora,
    :class_name => 'TipoHora',
    :foreign_key => ['tipo_hora_id']

  #autogenerado por db2models
  belongs_to :tipo_dia,
    :class_name => 'TipoDia',
    :foreign_key => ['tipo_dia_id']
    
  def descripcion
  	"#{tipo_dia.descripcion} de #{tipo_hora.hora_entrada} a #{tipo_hora.hora_salida}"
  end

end
