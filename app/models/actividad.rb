class Actividad < ApplicationRecord

	# ASOCIACIONES
	# Tipo_Actividad
	belongs_to :tipo_actividad,
		:foreign_key => :tipo_actividad_id

	# Cursos
	belongs_to :curso,
		:foreign_key => [:curso_idioma_id,:curso_tipo_categoria_id, :curso_tipo_nivel_id],
		:primary_key => [:idioma_id, :tipo_categoria_id, :tipo_nivel_id]

	has_many :preguntas, :dependent => :destroy
	accepts_nested_attributes_for :preguntas

	# Textos
	has_many :textos, :dependent => :destroy
	accepts_nested_attributes_for :textos

	# Adjuntos
	has_many :adjuntos, :dependent => :destroy
	accepts_nested_attributes_for :adjuntos

	# parte_examen_actividades
	has_many :parte_examen_actividades, :dependent => :destroy
	# :class_name => 'ParteExamenActividad',
	# :foreign_key => :actividad_id
	# :foreign_key => :actividad_id

	accepts_nested_attributes_for :parte_examen_actividades

	# parte_examenes
	has_many :parte_examenes, 
	# :class_name => 'ParteExamen',
	:through => :parte_examen_actividades

	accepts_nested_attributes_for :parte_examenes

	# VALIDACION
	validates :instrucciones, :presence => true
	validates :tipo_actividad_id, :presence => true
	validates :curso_idioma_id, :presence => true
	validates :curso_tipo_categoria_id, :presence => true
	validates :curso_tipo_nivel_id, :presence => true
	validates :curso_tipo_nivel_id, :presence => true


	def descripcion
		"#{tipo_actividad.descripcion} - #{instrucciones}. #{total_preguntas} preguntas de #{valor_cada_pregunta} c/u."
	end

	def descripcion_sin_tipo
		"#{instrucciones}. #{total_preguntas} preguntas de #{valor_cada_pregunta} c/u."		
	end

	def total_preguntas
		total = 0
		preguntas.each{|pre| total += pre.respuestas.count}
		return total
	end

	def total_respuestas_esperadas
		totales = 0
		preguntas.each do |pregunta|
			totales += pregunta.respuestas.count
		end
		return totales
	end

	def valor_cada_pregunta
		valor = 0
		valor = preguntas.first.valor_cada_pregunta if preguntas.first 
		return valor
	end

	def descripcion_con_id
		"#{tipo_actividad.id} #{descripcion}"
	end

	# belongs_to :examen
	# Examnes
	# QUEDA PENDIENTE
	# has_many :segmento_examenes,
	# 	:class_name => 'ExamenTieneSegmento'

	# accepts_nested_attributes_for :segmento_examenes

	# has_many :examenes, :through => :segmento_examenes, :source => :examen

	# # Preguntas
	# has_many :segmento_preguntas,
	# 	:class_name => 'SegmentoTienePregunta'

	# accepts_nested_attributes_for :segmento_preguntas

	# has_many :preguntas, :through => :segmento_preguntas, :source => :pregunta

end
