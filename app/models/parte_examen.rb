class ParteExamen < ApplicationRecord
	include ActionView::Helpers::TextHelper

	# CLAVE PRIMARIA COMPUESTA
  	# set_primary_keys [:parte_id, :examen_id]
	self.primary_keys = :parte_id, :examen_id


	# ATRIBUTOS ACCESIBLES
	# attr_accessor :parte_id, :examen_id

	# ASOCIACIONES
  	belongs_to :examen

	belongs_to :parte

	has_many :parte_examen_actividades, :dependent => :destroy, 
	# :class_name => 'ParteExamenActividad',
	# :primary_key => [:parte_id, :examen_id, :actividad_id],
	:foreign_key => [:parte_id, :examen_id]

	accepts_nested_attributes_for :parte_examen_actividades

	has_many :actividades, :through => :parte_examen_actividades, :source => :actividad

	accepts_nested_attributes_for :actividades

	# VALIDACIONES
	validates :parte_id, :presence => true
	validates :examen_id, :presence => true

	def descripcion_parte_con_actividades
		return "#{parte.nombre}: #{pluralize(actividades.count, 'Actividad')}"
	end

end