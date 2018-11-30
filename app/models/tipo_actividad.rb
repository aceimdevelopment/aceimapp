class TipoActividad < ApplicationRecord

	# ATRIBUTOS ACCESIBLES	
	# attr_accessor :id, :descripcion

	# ASOCIACIONES
	has_many :actividades,
	:class_name => 'Actividad',
	:foreign_key => :tipo_actividad_id

	accepts_nested_attributes_for :actividades

	# VALIDACIONES
	validates :id, :presence => true
	validates :descripcion, :presence => true


end