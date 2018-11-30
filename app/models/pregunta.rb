class Pregunta < ApplicationRecord

	# ATRIBUTOS ACCESIBLES
	# attr_accessor :id, :valor, :actividad_id

	# ASOCIACIONES
	belongs_to :actividad

	has_many :opciones, :dependent => :destroy,
		:class_name => 'Opcion'
	accepts_nested_attributes_for :opciones

	has_many :respuestas, :dependent => :destroy,
		:class_name => 'Respuesta'
	accepts_nested_attributes_for :respuestas

	#VALIDACIONES
	# validates :id, :presence => true
	validates :valor, :presence => true
	validates :actividad_id, :presence => true

	def valor_cada_pregunta
		puntaje = 0
		respuesta = respuestas.first
		puntaje = respuesta.puntaje if respuesta
		return puntaje
	end

	def total_puntaje_respuesta
		total = 0
		respuestas.each {|res| total += res.puntaje}

		return total
	end

end
