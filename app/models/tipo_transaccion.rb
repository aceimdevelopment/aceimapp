# encoding: utf-8

class TipoTransaccion < ApplicationRecord

	# ATRIBUTOS ACCESIBLES	
	attr_accessor :id, :descripcion

	# ASOCIACIONES
	has_many :historiales,
	:class_name => 'HistorialAcademico',
	:foreign_key => :tipo_transaccion_id

	accepts_nested_attributes_for :historiales

	# VALIDACIONES
	validates :id, :presence => true
	validates :descripcion, :presence => true


end