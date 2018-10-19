# encoding: utf-8

#creada por db2models
class HorarioSeccion < ApplicationRecord

  #autogenerado por db2models
  set_primary_keys :periodo_id,:idioma_id,:tipo_categoria_id,:tipo_nivel_id,:seccion_numero,:tipo_hora_id,:tipo_dia_id

  #autogenerado por db2models
  belongs_to :seccion,
    :class_name => 'Seccion',
    :foreign_key => ['periodo_id','idioma_id','tipo_categoria_id','tipo_nivel_id','seccion_numero']

  #autogenerado por db2models
  belongs_to :tipo_bloque,
    :class_name => 'TipoBloque',
    :foreign_key => ['tipo_hora_id','tipo_dia_id']

  #autogenerado por db2models
  belongs_to :aula,
    :class_name => 'Aula',
    :foreign_key => ['aula_id']
    
  def dia
    tipo_bloque.tipo_dia
  end
  
  def dia_aula
      fac,au = aula_id.split("-")
      "#{dia.descripcion} Aula #{au.to_s} - #{aula.tipo_ubicacion.descripcion_corta}" 
  end

  def ubicacion
    "#{aula.tipo_ubicacion.descripcion_corta}"
  end
  
  def descripcion
    tipo_bloque.descripcion
  end
end
