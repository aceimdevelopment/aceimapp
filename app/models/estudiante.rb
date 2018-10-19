class Estudiante < ApplicationRecord

  self.primary_keys = :usuario_ci

  belongs_to :usuario,
  foreign_key: :usuario_ci
  accepts_nested_attributes_for :usuario

  #autogenerado por db2models
  belongs_to :tipo_nivel_academico,
    :class_name => 'TipoNivelAcademico',
    :foreign_key => ['tipo_nivel_academico_id']

  has_many :estudiante_cursos,
    :class_name => 'EstudianteCurso',
    :foreign_key => ['usuario_ci']

  accepts_nested_attributes_for :estudiante_cursos

  has_many :estudiante_examenes,
    :foreign_key => :usuario_ci
  
  accepts_nested_attributes_for :estudiante_examenes

    
   def preinscrito?          
     @periodo = ParametroGeneral.periodo_actual
     HistorialAcademico.first(
     :conditions => ["usuario_ci = ? AND periodo_id = ?",
       usuario_ci,@periodo.id])
   end    


end
