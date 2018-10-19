class NotaEnEvaluacion < ApplicationRecord

  self.primary_keys = :usuario_ci, :idioma_id, :tipo_categoria_id, :tipo_nivel_id, :periodo_id, :seccion_numero, :tipo_evaluacion_id

  belongs_to :historial_academico,
    :class_name => 'HistorialAcademico',
    :foreign_key => ['usuario_ci', 'idioma_id', 'tipo_categoria_id', 
                     'tipo_nivel_id', 'periodo_id', 'seccion_numero']
          
  belongs_to :tipo_evaluacion

  def nota_valor
  	return "SC" if nota.to_i.eql? -2
  	return "PI" if nota.to_i.eql? -1
  	return nota.to_s
  end
end
