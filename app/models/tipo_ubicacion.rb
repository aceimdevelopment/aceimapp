# encoding: utf-8

#creada por db2models
class TipoUbicacion < ApplicationRecord
  attr_accessor :id, :descripcion, :descripcion_corta
  validates_presence_of :id, :descripcion, :descripcion_corta
  validates :id, :length => {:is => 3 }
	def desc
		
		if(descripcion == "Facultad de Humanidades y Educación")
			"#{descripcion} - #{descripcion_corta}"
		else
			"#{descripcion}"
		end

	end

  def descripcion_completa
    "#{id}- #{descripcion_corta}: #{descripcion}"
  end
	
	def cantidad_alumnos_por_ubicacion(periodo)
	  seccion = Seccion.where(:periodo_id=>periodo)
    secciones = []
    sum = 0
    seccion.each{|s|
      aula = s.horario_seccion2.aula
      if aula && aula.tipo_ubicacion_id == id
        #secciones << s
        sum+=s.inscritos
      end
    }
    
  #  secciones.each{|s|
  #    sum+=s.inscritos
  #  }
    sum
  end
  
  def listado_alumnos_por_ubicacion(periodo)
    seccion = Seccion.where(:periodo_id => periodo)
    alumnos = []
    seccion.each{|s|
      aula = s.horario_seccion2.aula
      if aula && aula.tipo_ubicacion_id == id 
        aux = s.listado_estudiantes_inscritos
       # if aux.size > 0
          alumnos += aux
      #  end
      end
    }
    alumnos = alumnos.sort_by{|x| x.usuario.nombre_completo}
    alumnos
  end

end
