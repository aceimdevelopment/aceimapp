module ExamenesHelper
	def total_and_sobre_20 (estudiante_examen)
		total_puntos_correctos = estudiante_examen.total_puntos_correctos

		total_puntos = estudiante_examen.examen.puntaje_total

		"#{total_puntos_correctos} / #{total_puntos} (#{estudiante_examen.total_puntos_correctos_base_20}/20)"
		
	end
end
