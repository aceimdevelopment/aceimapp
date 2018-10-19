# encoding: utf-8

class Aula < ApplicationRecord
  include ActiveModel::Validations 

  # ASOCIACIONES
  belongs_to :tipo_ubicacion

  has_many :bloque_aula_disponible,
    :class_name => 'BloqueAulaDisponible',
    :foreign_key => ['aula_id']
  
  # VALIDACIONES
  validates :id, :presence => true
  validates :tipo_ubicacion_id, :presence => true
  validates :descripcion, :presence => true
  validates :conjunto_disponible, :presence => true

  # FUNCIONES
  def descripcion_completa
    "(#{id}) #{tipo_ubicacion.descripcion} - #{descripcion}"
  end
  
  def descripcion_pareja
    "#{descripcion}"
  end

   def descripcion_ubicaciones_aula
    "#{tipo_ubicacion.descripcion}"
   end

  def horario_seccion_aula (dia_id, hora_id, periodo_id)
		  HorarioSeccion.where(:aula_id=>id, :tipo_hora_id=>hora_id,:tipo_dia_id=>dia_id,:periodo_id => periodo_id).delete_if{|x| !x.seccion.esta_abierta}
  end

end
