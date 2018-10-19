class Opcion < ApplicationRecord
	# BITACORA:
	# Puedira repensarse las que esta clase tenga un campo es_correcta (bolean) el cual sustituya a la posible respuesta correcta.

	# ATRIBUTOS ACCESIBLES
	# attr_accessor :id, :valor, :pregunta_id

	belongs_to :pregunta

	# VALIDACIONES	
	# validates :id, :presence => true
	validates :valor, :presence => true
	validates :pregunta_id, :presence => true

end
