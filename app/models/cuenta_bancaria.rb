# encoding: utf-8
class CuentaBancaria < ApplicationRecord
	# ASOCIACIONES
	has_many :historiales,
	:class_name => 'HistorialAcademico',
	:foreign_key => :cuenta_bancaria_id

	accepts_nested_attributes_for :historiales

	# FUNCIONES
	def descripcion
		"#{id} #{titular}"
	end

end
