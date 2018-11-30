class TipoMaterialApoyo < ApplicationRecord

	# ATRIBUTOS ACCESIBLES	
	# attr_accessor :id, :descripcion

	# ASOCIACIONES
	has_many :materiales_apoyo,
	:class_name => 'MaterialApoyo',
	:foreign_key => :tipo_material_apoyo_id

	accepts_nested_attributes_for :materiales_apoyo

	# VALIDACIONES
	validates :id, :presence => true
	validates :descripcion, :presence => true


end