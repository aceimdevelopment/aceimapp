class TipoEstadoExamen < ApplicationRecord

	# ATRIBUTOS ACCESIBLES
	# attr_accessor :id, :nombre

	# ASOCIACIONES
	has_many :examenes
	accepts_nested_attributes_for :examenes

	# VALIDACIONES
	validates :id, :presence => true
	validates :nombre, :presence => true

end