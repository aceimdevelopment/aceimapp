class MaterialApoyoCurso < ApplicationRecord

# CLAVE PRIMARIA CONPUESTA
	self.primary_keys = :material_apoyo_id, :curso_idioma_id, :curso_tipo_categoria_id, :curso_tipo_nivel_id

#ASOCIACIONES
	belongs_to :material_apoyo
	belongs_to :curso	
	
end
