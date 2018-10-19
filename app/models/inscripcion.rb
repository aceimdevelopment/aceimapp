#encoding: utf-8
class Inscripcion < ApplicationRecord
	attr_accessor :tipo_inscripcion_id, :idioma_id, :tipo_categoria_id, :permitir_cambio_horario, :apertura, :cierre, :tipo_estado_inscripcion_curso_id, :apertura_entrega_planilla, :cierre_entrega_planilla

 	# set_primary_keys [:tipo_inscripcion_id, :idioma_id, :tipo_categoria_id]
	self.primary_keys = :tipo_inscripcion_id, :idioma_id, :tipo_categoria_id

	belongs_to :tipo_inscripcion

	belongs_to :tipo_estado_inscripcion_curso

	belongs_to :tipo_curso,
    :foreign_key => ['idioma_id','tipo_categoria_id']

	validates :apertura, :presence => { :message => "Debe incluir el momento de apertura" }
	validates :cierre, :presence => {:message => "Debe incluir el momento de cierre"}

	# validates :apertura_entrega_planilla, :presence => { :message => "Debe incluir el momento de entrega de planilla" }
	# validates :cierre_entrega_planilla, :presence => {:message => "Debe incluir el momento de cierre de entrega de planilla"}

	validate :apertura_menorque_cierre

	def fecha_apertura
		I18n.localize(apertura, :format => "%A %d de %B de %Y a las %I:%M %p")
	end

	def fecha_cierre
		I18n.localize(cierre, :format => "%A %d de %B de %Y a las %I:%M %p")
	end

	def fecha_inscripcion
		fecha_formato apertura, cierre
	end

	def fecha_entrega_planilla
		fecha_formato apertura_entrega_planilla, cierre_entrega_planilla
	end

	def fecha_formato (fecha_inicial, fecha_final)
		if fecha_inicial.blank? or fecha_final.blank? or post_cierre
			return "por definir"
		else
			if fecha_inicial.to_date.eql? fecha_final.to_date		
				fecha = I18n.localize(fecha_inicial, :format => "El %A, %d de %B de %Y ")
				if (fecha_inicial.hour < 12) and (fecha_final.hour > 12)
					fecha += I18n.localize(fecha_inicial, :format => "desde las %I:%M %p hasta las 12:00m y desde las 2:00pm hasta las ")
					fecha += I18n.localize(fecha_final, :format => "%I:%M %p")
				else
					fecha += I18n.localize(fecha_inicial, :format => "desde las %I:%M %p hasta las ")
					fecha += I18n.localize(fecha_final, :format => "%I:%M %p")					
				end	
			else
				fecha = "Desde el #{fecha_apertura} hasta el #{fecha_cierre}"
			end			
			return fecha
		end
	end

	def post_cierre
		Date.today.yday > cierre.to_date.yday+10
	end

	def ninos_abierta?
		tipo_estado_inscripcion_curso_id.eql? 'AB' and tipo_categoria_id.eql? 'NI'
	end

	def nuevos?
		tipo_inscripcion_id.eql? 'NU'
	end

	def regulares?
		tipo_inscripcion_id.eql? 'RE'
	end

	def regulares_o_nuevos?
		tipo_inscripcion_id.eql? 'NU' or tipo_inscripcion_id.eql? 'RE'
	end

	def cambio_horario?
		tipo_inscripcion_id.eql? 'CA'
	end

	def nuevo_abierta?
		tipo_estado_inscripcion_curso_id.eql? 'AB' and tipo_inscripcion.eql? 'NU'
	end

	def abierta?
		tipo_estado_inscripcion_curso_id.eql? 'AB'		
	end

	def programada?
		tipo_estado_inscripcion_curso_id.eql? 'PR'		
	end

	def cerrada?
		tipo_estado_inscripcion_curso_id.eql? 'CE'
	end

	def abrir_ahora?
		tipo_estado_inscripcion_curso_id.eql? 'PR' and apertura <= DateTime.now
	end

	def cerrar_ahora?
		tipo_estado_inscripcion_curso_id.eql? 'AB' and DateTime.now > cierre
	end

    def descripcion
    	"#{tipo_curso.descripcion} - #{tipo_inscripcion.descripcion}"
    end

private

	def apertura_menorque_cierre
	    errors.add(:apertura, "- El Cierre debe ser después que la Apertura") if
	        apertura > cierre
	end 
end
