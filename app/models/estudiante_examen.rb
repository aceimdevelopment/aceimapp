# encoding: utf-8
class EstudianteExamen < ApplicationRecord

	# CLAVE PRIMARIA COMPUESTA
	self.primary_keys = :estudiante_ci, :examen_id

	# ASOCIACIONES
	belongs_to :examen
	belongs_to :tipo_estado_estudiante_examen
	belongs_to :estudiante,
    :foreign_key => :estudiante_ci

	has_many :estudiante_examen_respuestas, :dependent => :destroy, 
		foreign_key: [:estudiante_ci, :examen_id]
	accepts_nested_attributes_for :estudiante_examen_respuestas

	has_many :respuestas, :through => :estudiante_examen_respuestas, :source => :respuesta
	accepts_nested_attributes_for :respuestas

	# VALIDACIONES
	validates :estudiante_ci, :presence => true
	validates :examen_id, :presence => true

	def eers
		estudiante_examen_respuestas
	end

# Version de Generar EERs V1
	# def generar_eers

	# 	total_generadas = 0
	# 	total_respuestas = 0
	# 	examen.parte_examenes.each do |pe|
	# 		actividades = pe.actividades
	# 		actividades.each do |actividad|
	# 			preguntas = actividad.preguntas
	# 			preguntas.each do |pregunta|
	# 				respuestas = pregunta.respuestas
	# 				total_respuestas += respuestas.count
	# 				respuestas.each do |respuesta|
	# 					total_generadas += 1 if EstudianteExamenRespuesta.create(:estudiante_ci => estudiante_ci, :examen_id => examen_id, :respuesta_id => respuesta.id)
	# 				end
	# 			end
	# 		end
	# 	end
	# 	return "Total Generadas: #{total_generadas} de Total de Respuestas: #{total_respuestas}"
	# end

	# def generar_respuestas
	# 	begin
	# 		estudiante_examen_respuestas.create(:respuesta_id => examen.respuestas.collect{|r| r.id})
	# 		return examen.respuestas.count
	# 	rescue Exception => e
	# 		return e
	# 	end
	# end



	def generar_eers2
		total_generadas = 0

		examen.respuestas.each do |respuesta|
			total_generadas += 1 if EstudianteExamenRespuesta.find_or_create_by_estudiante_ci_and_examen_id_and_respuesta_id(:estudiante_ci => estudiante_ci, :examen_id => examen_id, :respuesta_id => respuesta.id)
		end

		return "Total Generadas o encontradas: #{total_generadas}"

	end


	def preparado?
		tipo_estado_estudiante_examen_id.eql? 'PREPARADO'
	end

	def agotado?
		tipo_estado_estudiante_examen_id.eql? 'AGOTADO'
	end

	def iniciado?
		tipo_estado_estudiante_examen_id.eql? 'INICIADO'
	end

	def completado?
		tipo_estado_estudiante_examen_id.eql? 'COMPLETADO'
	end

	def estado
		tipo_estado_estudiante_examen
	end

	def transferir_nota_escrita_a_historial
		if examen.orden.eql? "primero"
			transferir_nota_escrito1_a_historial 
		else
			transferir_nota_escrita2_a_historial 
		end
	end

	def transferir_nota_escrito1_a_historial
		transferir_nota_a_historial(HistorialAcademico::EXAMENESCRITO1, total_puntos_correctos_base_20)		
	end

	def transferir_nota_escrita2_a_historial
		transferir_nota_a_historial(HistorialAcademico::EXAMENESCRITO2, total_puntos_correctos_base_20)
	end
	def transferir_nota_a_historial(tipo_evalu_id, calificacion)
		unless historial_academico
			return false
		else
			historial_academico.guargar_nota_adicional(tipo_evalu_id, calificacion)
		end
	end
	def historial_academico
		HistorialAcademico.where(:usuario_ci => estudiante_ci, :idioma_id => examen.curso_idioma_id, :tipo_categoria_id => examen.curso_tipo_categoria_id, :tipo_nivel_id => examen.curso_tipo_nivel_id, :periodo_id => examen.periodo_id).limit(1).first
	end

	def total_puntos_correctos
		total = 0
		estudiante_examen_respuestas.each do |eer|
			total += eer.respuesta.puntaje if eer.es_correcta?
		end 
		return total
	end

	def total_puntos_correctos_base_20
		sprintf("%.1f",Float((total_puntos_correctos*20)/examen.puntaje_total))

		# Float(nota[1].gsub(",","."))
		# "#{sprintf('%.2f',((total_puntos_correctos*20)/examen.puntaje_total))}"
	end

	def total_respuestas_correctas
		total = 0
		estudiante_examen_respuestas.each do |eer|
			total += 1 if eer.es_correcta?
		end
		return total
	end

	def resagado?
		return ((resagado_inicio? and resagado_fin?) and (Time.now > resagado_inicio and Time.now < resagado_fin) and tipo_estado_estudiante_examen_id.eql? 'RESAGADO')
	end


	def self.transferir_notas_a_historiales
		begin
			@estudiante_examenes = EstudianteExamen.where("tipo_estado_estudiante_examen_id != 'PREPARADO' AND tipo_estado_estudiante_examen_id != 'SUSPENDIDO'").delete_if{|ee| ee.examen.prueba and ee.examen.periodo_id!=ParametroGeneral.periodo_actual.id}
			# @estudiante_examenes = EstudianteExamen.where("tipo_estado_estudiante_examen_id = 'AGOTADO' OR tipo_estado_estudiante_examen_id = 'RESAGADO'").delete_if{|ee| ee.examen.prueba or ee.examen.periodo_id!=ParametroGeneral.periodo_actual.id}

			total_trasferidos = 0
			total_ee = @estudiante_examenes.count
			@estudiante_examenes.each do |ee|
				total_trasferidos += 1 if ee.transferir_nota_escrita_a_historial
				puts "Guardado ##{total_trasferidos}/#{total_ee}."
			end
			puts "Total de exámenes: #{total_ee}. Total transferidos: #{total_trasferidos}"
		rescue Exception => e
			puts = "Error: #{e.message}"
		end
  	end

end