# encoding: utf-8
class DetalleFactura < ApplicationRecord
	# CLAVE PRIMARIA COMPUESTA
	self.primary_keys = :factura_codigo, :periodo_id , :idioma_id , :tipo_categoria_id , :tipo_nivel_id

	# ASOCIACIONES
	belongs_to :factura,
		:foreign_key => 'factura_codigo'

	belongs_to :curso_periodo,
		:class_name => 'CursoPeriodo',
		:foreign_key => ['periodo_id' , 'idioma_id' , 'tipo_categoria_id' , 'tipo_nivel_id']

	# VALIDACIONES
	validates_presence_of :factura_codigo, :periodo_id , :idioma_id , :tipo_categoria_id , :tipo_nivel_id

	validates :factura_codigo, :uniqueness => {:scope => ['periodo_id' , 'idioma_id' , 'tipo_categoria_id' , 'tipo_nivel_id']}
end