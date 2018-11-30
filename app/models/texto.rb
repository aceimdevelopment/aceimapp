class Texto < ApplicationRecord
	
	# ATRIBUTOS ACCESIBLES
	# attr_accessor :contenido, :segmento_id

	# ASOCIACIONES

	belongs_to :segmento
end