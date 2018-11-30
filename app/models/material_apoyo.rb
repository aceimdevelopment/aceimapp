class MaterialApoyo < ApplicationRecord

# ASOCIACIONES
	has_many :material_apoyo_cursos, :dependent => :destroy, :foreign_key => :material_apoyo_id
	accepts_nested_attributes_for :material_apoyo_cursos

	belongs_to :tipo_material_apoyo

end
