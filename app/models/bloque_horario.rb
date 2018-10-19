# encoding: utf-8

class BloqueHorario < ApplicationRecord

  # ASOCIACIONES
  belongs_to :tipo_hora

  belongs_to :tipo_dia,
    class_name: 'TipoDia',
    foreign_key: 'tipo_dia_id1'#,
    # name: 'tipo_dia1' # OJO: Revisar esta linea

  belongs_to :tipo_dia,
    class_name: 'TipoDia',
    foreign_key: 'tipo_dia_id2'#,
    # name: 'tipo_dia2'

  has_many :archivos
  accepts_nested_attributes_for :archivos

  # FUNCIONES
	def descripcion_horario

		bloque_horario = BloqueHorario.find("H5")

		dia1 = bloque_horario.tipo_dia_id1
		dia2 = bloque_horario.tipo_dia_id2

		dia1_desc = TipoDia.find(dia1)

	  dia2_desc = TipoDia.find(dia2)

		puts dia1_desc.descripcion
		puts dia2_desc.descripcion

  end

end
