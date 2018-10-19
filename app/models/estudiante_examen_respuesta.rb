class EstudianteExamenRespuesta < ApplicationRecord

	# CLAVE PRIMARIA COMPUESTA
	self.primary_keys = :estudiante_ci, :examen_id, :respuesta_id

	# ASOCIACIONES
	# belongs_to :actividad

	belongs_to :estudiante_examen,
	:primary_key =>  [:estudiante_ci, :examen_id],
	:foreign_key => [:estudiante_ci, :examen_id]

	belongs_to :respuesta


	#VALIDACIONES
	validates :estudiante_ci, :presence => true
	validates :examen_id, :presence => true
	validates :respuesta_id, :presence => true

	def ee
		estudiante_examen
	end

	def es_correcta?
		if valor 
			return respuesta.correcta? valor
		else
			return false
		end
	end

	def descripcion
		"#{estudiante_ci} - #{ee.examen.descripcion_simple}. Pregunta: #{respuesta.pregunta.valor} ->  #{valor}"
	end

end