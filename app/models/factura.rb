# encoding: utf-8

class Factura < ApplicationRecord
	attr_accessor :codigo, :numero_control, :fecha, :cliente_rif
	# set_primary_keys :codigo
	self.primary_keys = :codigo

	belongs_to :cliente,
	foreign_key: 'cliente_rif'

	has_many :detalle_facturas,
	foreign_key: 'factura_codigo'
	accepts_nested_attributes_for :detalle_facturas

	validates_presence_of :cliente_rif
	validates_presence_of :codigo
	validates_presence_of :numero_control	
  	validates_uniqueness_of :codigo, :case_sensitive => false
  	validates_uniqueness_of :numero_control, :case_sensitive => false	
	
def monto_total
	total = 0
	detalle_facturas.each do |detalle|
		total += detalle.total
	end
	return total
end

end