# encoding: utf-8

class Cliente < ApplicationRecord
	# epecifica clave primaria rif
	self.primary_keys = :rif


	# incluye validaciones personales: Correo electrónico 
	# include ActiveModel::Validations 

	# ASOCIACIONES
	has_many :facturas,
		:class_name => 'Factura',
		:foreign_key => 'cliente_rif'
	accepts_nested_attributes_for :facturas

	# VALIDACIONES
  	validates_presence_of :rif
  	validates_presence_of :razon_social
  	validates_presence_of :domicilio
  	validates_uniqueness_of :rif, :case_sensitive => false
  	validates_uniqueness_of :razon_social, :case_sensitive => false
	# esta pendiente la validacion del rif

	# FUNCIONES
	def descripcion
		"#{rif.upcase} | #{razon_social}"
	end

	def telefono_fijo_obligatorio
		return telefono_fijo.to_s.rjust(12,'_')
	end
end 