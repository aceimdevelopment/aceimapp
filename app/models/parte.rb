class Parte < ApplicationRecord

	# ATRIBUTOS ACCESIBLES
	# attr_accessor :id, :nombre, :orden

	# ASOCIACIONES
	has_many :parte_examenes
	# :primary_key => [:parte_id, :examen_id]
	# :class_name => 'BloqueExamen'
	accepts_nested_attributes_for :parte_examenes

	has_many :examenes, :through => :bloques_examenes, :source => :examen
	accepts_nested_attributes_for :examenes	

	# VALIDACIONES
	validates :id, :presence => true
	validates :nombre, :presence => true

end