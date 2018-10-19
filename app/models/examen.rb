class Examen < ApplicationRecord

# ASOCIACIONES
	belongs_to :curso_periodo,
		:foreign_key => [:periodo_id, :curso_idioma_id,:curso_tipo_categoria_id, :curso_tipo_nivel_id]

	belongs_to :tipo_estado_examen

	has_many :parte_examenes, :dependent => :destroy
	accepts_nested_attributes_for :parte_examenes

	has_many :partes, :through => :parte_examenes, :source => :parte
	accepts_nested_attributes_for :partes

	has_many :estudiante_examenes, :dependent => :destroy, :foreign_key => :examen_id
	accepts_nested_attributes_for :estudiante_examenes

	
# VALIDACIONES
	validates :curso_idioma_id, :presence => true
	validates :curso_tipo_categoria_id, :presence => true
	validates :curso_tipo_nivel_id, :presence => true
	validates :periodo_id, :presence => true
	validates :duracion, :presence => true
	validates :orden, :presence => true

# FUNCINALIDADES
	def respuestas
		totales = []
		parte_examenes.each do |pe|
			actividades = pe.actividades
			actividades.each do |actividad|
				preguntas = actividad.preguntas
				preguntas.each do |pregunta|
					pregunta.respuestas.each do |respuesta|
						totales << respuesta
					end
				end
			end
		end
		return totales
		
	end

	def se_puede_presentar?
		if Time.now > inicio_aplicacion and Time.now < cierre_aplicacion
			return true
		else
			false
		end
	end

	def es_prueba?
		prueba.eql? true
	end

	def descripcion_full
		"#{curso_periodo.descripcion}-#{orden}-#{descripcion}"
	end

	def descripcion_simple
		if prueba and prueba.eql? true
			"Examen de prueba de #{curso_periodo.idioma.descripcion}"
		else
			"#{orden.capitalize} Examen de #{titulo}"
		end
	end

	def descripcion_completa
		aux = ""
		parte_examenes.each do |parte_examen|
			aux += "#{parte_examen.parte.id}: #{parte_examen.actividades.count} Act. " if parte_examen.actividades.count > 0
		end
		"#{descripcion}. Partes: #{aux} / Total: #{puntaje_total} Puntos."
	end

	def titulo
		curso_periodo.descripcion
	end

	def puntaje_total
		total = 0
		parte_examenes.each do |pe|
			pe.actividades.each do |act|
				act.preguntas.each do |pre|
					total += pre.respuestas.sum(:puntaje)
				end
			end
		end
		return total
	end

	def total_preguntas
		total = 0
		parte_examenes.each do |pe|
			pe.actividades.each do |act|
				# total += act.preguntas.count
				act.preguntas.each do |pre|
					total += pre.respuestas.count
				end
			end
		end
		return total
	end

	def total_actividades
		total = 0
		parte_examenes.each do |pe|
			total += pe.actividades.count
		end
		return total
	end


end
