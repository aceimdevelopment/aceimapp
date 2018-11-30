class Segmento < ApplicationRecord
	# ATRIBUTOS ACCESIBLES
	# attr_accessor :id, :titulo, :tipo_segmento_id, :curso_idioma_id, :curso_tipo_categoria_id, :curso_tipo_nivel_id, :cantidad_preguntas, :valor_preguntas

	# ASOCIACIONES

	# Tipo_Segmento
	belongs_to :tipo_segmento,
		:foreign_key => :tipo_segmento_id

	# Cursos
	belongs_to :curso,
		:foreign_key => [:idioma_id,:tipo_categoria_id, :tipo_nivel_id]

	has_many :preguntas, :dependent => :destroy
	accepts_nested_attributes_for :preguntas


	belongs_to :examen
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

	# Textos
	has_many :textos, :dependent => :destroy
	accepts_nested_attributes_for :textos

	# Adjuntos
	has_many :adjuntos, :dependent => :destroy
	accepts_nested_attributes_for :adjuntos


	def descripcion
		"#{tipo_segmento.nombre} - #{titulo}. #{cantidad_preguntas} preguntas de #{valor_preguntas} c/u. (Total= #{cantidad_preguntas*valor_preguntas if (cantidad_preguntas and valor_preguntas) } Pts.)"
	end

	def descripcion_con_if
		"#{tipo_segmento.id} #{tipo_segmento.nombre} - #{titulo}. #{cantidad_preguntas} preguntas de #{valor_preguntas} c/u. (Total= #{cantidad_preguntas*valor_preguntas if (cantidad_preguntas and valor_preguntas) } Pts.)"
	end
end
