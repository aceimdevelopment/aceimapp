class Respuesta < ApplicationRecord

	# ATRIBUTOS ACCESIBLES
	# attr_accessor :id, :valor, :valor_alternativa1, :valor_alternativa2, :puntaje, :pregunta_id, :orden, :otra_respuesta_id

	# ASOCIACIONES
	belongs_to :pregunta

	# has_many :otras_respuestas,
	# 	:class_name => 'Respuesta',
	# 	:foreign_key => :otra_respuesta_id

	# accepts_nested_attributes_for :otras_respuestas

	has_many :estudiante_examen_respuesta
	accepts_nested_attributes_for :estudiante_examen_respuesta


	#VALIDACIOENS
	validates :valor, :presence => true
	validates :puntaje, :presence => true
	validates :pregunta_id, :presence => true

	def correcta
		aux = valor
		aux += " / #{valor_alternativa1}" unless valor_alternativa1.blank?
		aux += " / #{valor_alternativa2}" unless valor_alternativa2.blank?  
		return valor
	end

	def correcta? (valor_x)
		casos = false
		#Casos elementales
		casos = true if valor.eql? valor_x
		casos = true if valor_alternativa1.eql? valor_x
		casos = true if valor_alternativa2.eql? valor_x
		# Casos comparacion de caracteres (IqualIgnoreCase)
		casos = true if valor and valor.casecmp(valor_x).zero?
		casos = true if valor_alternativa1 and valor_alternativa1.casecmp(valor_x).zero?
		casos = true if valor_alternativa2 and valor_alternativa2.casecmp(valor_x).zero?
		return casos
	end

end
