# encoding: utf-8

class ReportesPdf

  def self.to_utf16(valor)
    ic_ignore = Iconv.new('ISO-8859-15//IGNORE//TRANSLIT', 'UTF-8')
    ic_ignore.iconv(valor)
  end

  def self.generar_listado_estudiantes(periodo,idioma,nivel,\
  categoria,seccion_numero,guardar=false)

    
    historial = HistorialAcademico.where(:periodo_id=>periodo, :idioma_id=>idioma, :tipo_nivel_id=>nivel, :tipo_categoria_id=>categoria, :seccion_numero=>seccion_numero, :tipo_estado_inscripcion_id=>"INS")
    historial = historial.sort_by{|x| x.usuario.nombre_completo}

		#pdf.add_image_from_file 'public/images/logo_pi_color1.jpg', 55, 660, 490,nil

    pdf = PDF::Writer.new(:paper => "letter")  #:orientation => :landscape, 
    
    ss = PDF::Writer::StrokeStyle.new(2)
		ss.cap = :round
		pdf.stroke_style ss

    pdf.add_image_from_file 'app/assets/images/logo_fhe_ucv.jpg', 45, 710, 50,nil
    pdf.add_image_from_file 'app/assets/images/logo_eim.jpg', 515, 710, 50,nil
    pdf.add_image_from_file 'app/assets/images/logo_ucv.jpg', 275, 710, 50,nil
    
    #pdf.image "public/images/Logo FHE-UCV.jpg", :justification => :left, :width => 50
    #pdf.image "public/images/Logo FHE-UCV.jpg", :justification => :center, :width => 50, :pad => 0
    
    pdf.line 35,700,575,700
    
    #pdf.add_image_from_file 'public/images/logoEIM.jpg', 5, 660, 50,nil
    
    
    if historial.size > 0
      @seccion = historial.last.seccion
			pdf.text "\n\n\n\n\n"
      pdf.text to_utf16("<b>Período:</b> #{historial.last.periodo_id}"), :justification => :center
      pdf.text to_utf16("<b>Curso:</b> #{Seccion.idioma(@seccion.idioma)} #{Seccion.tipo_categoria(@seccion.tipo_categoria)} #{@seccion.tipo_nivel.descripcion} - #{"%002i"%@seccion.seccion_numero}"), :justification => :center        
      pdf.text to_utf16("<b>Aula:</b> #{@seccion.aula}"), :justification => :center
      pdf.text to_utf16("<b>Horario:</b> #{@seccion.horario}"), :justification => :center
      pdf.text to_utf16("<b>Profesor:</b> #{@seccion.instructor.nombre_completo}"), :justification => :center
      pdf.text "\n\n"
      
      pdf.line 35,630,575,630
      
      
      
      tab = PDF::SimpleTable.new
      tab.bold_headings = true
      tab.show_lines    = :inner
      tab.show_headings = true
      tab.shade_rows = :none
      tab.orientation   = :center
      tab.heading_font_size = 8
      tab.font_size = 8
      tab.row_gap = 3
      tab.minimum_space = 0
      tab.column_order = ["nro","nombre","cedula", "correo","telefono"]
      tab.columns["nro"] = PDF::SimpleTable::Column.new("nro") { |col|
        col.width = 25
        col.justification = :right
        col.heading = "#"
        col.heading.justification= :center
      }
      tab.columns["nombre"] = PDF::SimpleTable::Column.new("nombre") { |col|
        col.width = 180
        col.justification = :left
        col.heading = "NOMBRE COMPLETO"
        col.heading.justification= :center
      }
      tab.columns["cedula"] = PDF::SimpleTable::Column.new("cedula") { |col|
        col.width = 50
        col.justification = :center
        col.heading = to_utf16 "CÉDULA"
        col.heading.justification= :center
      }
      tab.columns["correo"] = PDF::SimpleTable::Column.new("correo") { |col|
        col.width = 180
        col.justification = :left
        col.heading = "CORREO"
        col.heading.justification= :center
      }
      tab.columns["telefono"] = PDF::SimpleTable::Column.new("telefono") { |col|
        col.width = 80
        col.justification = :left
        col.heading = "TELEFONO"
        col.heading.justification= :center
      }

      data = []

      historial.each_with_index{|reg,ind|
        data << {
          "nro" => "#{(ind+1)}",          
          "nombre" => to_utf16(reg.usuario.nombre_completo),
          "cedula" => reg.usuario_ci,
          "correo" => reg.usuario.correo,
          "telefono" => reg.usuario.telefono_movil
        }
      }


			t = Time.new
			pdf.start_page_numbering(250, 15, 7, nil, to_utf16("#{t.day} / #{t.month} / #{t.year}       Página: <PAGENUM> de <TOTALPAGENUM>"), 1)

      tab.data.replace data
      
      pdf.line 35,25,575,25
      
      tab.render_on(pdf)

      pdf.save_as "#{historial.last.seccion.id.to_s.gsub(",","_")}.pdf" if guardar
    end
    pdf

  end

  def self.generar_listado_secciones(periodo,guardar=false)
    
    secciones = Seccion.where(:periodo_id => periodo)
    secciones = secciones.sort_by{|x| "#{x.idioma_id}, #{x.tipo_categoria_id}, #{"%002i"%x.tipo_nivel.orden}, #{"%002i"%x.seccion_numero}, #{x.horario}"}

    pdf = PDF::Writer.new(:paper => "letter",:orientation => :landscape)
    
    
    pdf.add_image_from_file 'logo_FHE-UCV.jpg', 65, 550, 50,nil
    pdf.add_image_from_file 'logo_EIM.jpg', 665, 550, 50,nil
    pdf.add_image_from_file 'logo_UCV.jpg', 365, 550, 50,nil
    
    pdf.line 55,545,720,545
    
    pdf.text "\n\n\n"
    pdf.text "SECCIONES #{periodo_id}\n",:justification => :center
    pdf.text "\n\n"
    
    pdf.line 55,515,720,515
    
    tab = PDF::SimpleTable.new
    tab.bold_headings = true
    tab.show_lines    = :all
    tab.show_headings = true
    tab.shade_rows = :none
    tab.orientation   = :center
    tab.heading_font_size = 8
    tab.font_size = 8
    tab.row_gap = 2
    tab.minimum_space = 0

    tab.column_order = ["inscritos", "preinscritos","idioma","nivel","seccion","horario","aula","profesor"]
    tab.columns["inscritos"] = PDF::SimpleTable::Column.new("inscritos") { |col|
      col.width = 30
      col.justification = :center
      col.heading = "I"
      col.heading.justification= :center
    }
    tab.columns["preinscritos"] = PDF::SimpleTable::Column.new("preinscritos") { |col|
      col.width = 30
      col.justification = :center
      col.heading = to_utf16 "P"
      col.heading.justification= :center
    }
    tab.columns["idioma"] = PDF::SimpleTable::Column.new("idioma") { |col|
      col.width = 80
      col.justification = :left
      col.heading = "IDIOMA"
      col.heading.justification= :center
    }
    tab.columns["nivel"] = PDF::SimpleTable::Column.new("nivel") { |col|
      col.width = 80
      col.justification = :left
      col.heading = "NIVEL"
      col.heading.justification= :center
    }
    tab.columns["seccion"] = PDF::SimpleTable::Column.new("seccion") { |col|
      col.width = 40
      col.justification = :left
      col.heading = "SEC"
      col.heading.justification= :center
    }
    tab.columns["horario"] = PDF::SimpleTable::Column.new("horario") { |col|
      col.width = 140
      col.justification = :left
      col.heading = "HORARIO"
      col.heading.justification= :center
    }
    tab.columns["aula"] = PDF::SimpleTable::Column.new("aula") { |col|
      col.width = 100
      col.justification = :left
      col.heading = "AULA"
      col.heading.justification= :center
    }
    tab.columns["profesor"] = PDF::SimpleTable::Column.new("profesor") { |col|
      col.width = 140
      col.justification = :left
      col.heading = "PROFESOR"
      col.heading.justification= :center
    }

    if secciones.size > 0
      data = []
      
      tab.column_order = ["confirmados", "preinscritos","idioma","nivel","seccion","horario","aula","profesor"]


      secciones.each{|sec|
        data << {
          "inscritos" => to_utf16("#{sec.inscritos}"), 
          "preinscritos" => to_utf16("#{sec.preinscritos}"), 
          "idioma" => to_utf16("#{sec.idioma.descripcion} (#{sec.tipo_categoria.descripcion})"), 
          "nivel" => to_utf16("#{sec.tipo_nivel.descripcion}"), 
          "seccion" => to_utf16("#{sec.unidad}"), 
          "horario" => to_utf16("#{sec.horario.descripcion}"), 
          "aula" => to_utf16("#{sec.aula.descripcion}"),       
          "profesor" => to_utf16("#{sec.instructor.descripcion}")
        }
        
      }
			pdf.start_page_numbering(665, 30, 7, nil, to_utf16("Página: <PAGENUM> de <TOTALPAGENUM>"), 1)
      tab.data.replace data
      tab.render_on(pdf)  
      pdf.text "\n"
      
      
      
      
      pdf.text Time.now.strftime("%d/%m/%Y %I:%M %p"),:justification => :center
            
      
      


      pdf.save_as "secciones.pdf" if guardar
      pdf
    end


  end

  def self.imprimir_secciones
    periodo = ParametroGeneral.periodo_actual
    secciones = Seccion.where(:periodo_id=> periodo)
    
    secciones.each do  |seccion|
       generar_listado_estudiantes(seccion.periodo_id,\
       seccion.idioma_id,seccion.tipo_nivel_id,\
       seccion.tipo_categoria_id,seccion.seccion_numero,true)
    end
  end
    
  def self.generar_certificado_estudiante(ci,guardar=false)

    historial = HistorialAcademico.all(
    :conditions => ["estudiante_usuario_ci = ?",ci])                             
    
    historial = historial.sort_by{|x| x.usuario.nombre_completo}

		#pdf.add_image_from_file 'public/images/logo_pi_color1.jpg', 55, 660, 490,nil

    pdf = PDF::Writer.new(:paper => "letter")  #:orientation => :landscape, 
    
    ss = PDF::Writer::StrokeStyle.new(2)
		ss.cap = :round
		pdf.stroke_style ss

    pdf.add_image_from_file 'logo_FHE-UCV.jpg', 45, 710, 50,nil
    pdf.add_image_from_file 'logo_EIM.jpg', 515, 710, 50,nil
    pdf.add_image_from_file 'logo_UCV.jpg', 280, 710, 50,nil
    pdf.text "\n\n\n\n"
    pdf.margins_mm(30)
    pdf.text "UNIVERSIDAD CENTRAL DE VENEZUELA", :font_size => 6,:justification => :center
    pdf.text to_utf16("Facultad de Humanidades y Educación"), :font_size => 6,:justification => :center
    pdf.text "Escuela de Idiomas Modernos", :font_size => 6,:justification => :center
    
    #pdf.image "public/images/Logo FHE-UCV.jpg", :justification => :left, :width => 50
    #pdf.image "public/images/Logo FHE-UCV.jpg", :justification => :center, :width => 50, :pad => 0
    
    pdf.line 35,650,575,700
    
    #pdf.add_image_from_file 'public/images/logoEIM.jpg', 5, 660, 50,nil
    
    if historial.size > 0
    	#pdf.select_font "Helvetica"
    	pdf.text "\n\n\n\n\n\n\n"
    	pdf.text "<b>CONSTANCIA</b>", :font_size => 20,:justification => :center
    	pdf.text "\n"
    	pdf.text to_utf16("Quien suscribe, Prof. Lucius Daniel, Director de la Escuela de Idiomas Modernos de la Facultad de Humanidades y Educación de la Universidad Central de Venezuela, hace constar por medio de la presente que el(la) ciudadano(a):"), :spacing => 1.5, :font_size => 12, :justification => :full
    	pdf.text "\n"
    	pdf.text "<b>#{to_utf16(historial.first.usuario.descripcion)}</b>",:justification => :center
			pdf.text "\n"
			pdf.text to_utf16("aprobó el(los) curso(s) que se indican a continuación:")
			pdf.text "\n"
            
      #pdf.line 35,630,575,630
      
      tab = PDF::SimpleTable.new
      tab.bold_headings = true
      tab.show_lines    = :none
      tab.show_headings = true
      tab.shade_rows = :none
      tab.orientation   = :center
      tab.heading_font_size = 8
      tab.font_size = 12
      tab.row_gap = 1
      tab.minimum_space = 0
      
      tab.column_order = ["nro","curso","nivel","periodo","nota"]
      
      tab.columns["nro"] = PDF::SimpleTable::Column.new("nro") { |col|
        col.width = 25
        col.justification = :right
        col.heading = " "
        col.heading.justification= :center
      }
      tab.columns["curso"] = PDF::SimpleTable::Column.new("nombre") { |col|
        col.width = 180
        col.justification = :center
        col.heading = "Curso"
        col.heading.justification= :center
      }
      tab.columns["nivel"] = PDF::SimpleTable::Column.new("cedula") { |col|
        col.width = 100
        col.justification = :center
        col.heading = to_utf16 "Nivel"
        col.heading.justification= :center
      }
      tab.columns["periodo"] = PDF::SimpleTable::Column.new("correo") { |col|
        col.width = 80
        col.justification = :center
        col.heading = to_utf16("Período")
        col.heading.justification= :center
      }
      tab.columns["nota"] = PDF::SimpleTable::Column.new("telefono") { |col|
        col.width = 80
        col.justification = :center
        col.heading = to_utf16("Calificación")
        col.heading.justification= :center
      }

      data = []

      historial.each{|reg|
      	if reg.aprobo_curso?
      	
      	data << {
          "nro" => "<b>*</b>",          
          "curso" => "<b>#{to_utf16(reg.idioma.descripcion)} #{to_utf16(reg.tipo_categoria.complemento)}</b>",
          "nivel" => "<b>#{to_utf16(reg.tipo_nivel.descripcion)}</b>",
          "periodo" => "<b>#{reg.periodo_id}</b>",
          "nota" => "<b>#{"%002i"%reg.nota_final}</b>"
        }
        
      	end
      	
        
      }
			tab.data.replace data
			tab.render_on(pdf)
			
			t = Time.new
			
			pdf.text "\n\n"
			pdf.text to_utf16("Cada nivel tiene una duración de 54 horas académicas (9 semanas aproximadamente). Esta constancia se expide a solicitud del interezado(a)."), :spacing => 1.5, :font_size => 12, :justification => :full
			
			pdf.text to_utf16("En Caracas, a los #{t.day} días del mes de #{mes(t.month)} de #{t.year}"), :spacing => 1.5, :font_size => 12, :justification => :full
			
			pdf.text "\n\n\n\n"
			pdf.text "____________________________" , :justification => :center
			pdf.text "Prof. Lucius Daniel" , :justification => :center
			
			
			pdf.add_text_wrap(160, 38, 300 , "\"CIUDAD UNIVERSITARIA DE CARACAS - PATRIMONIO CULTURAL DE LA HUMANIDAD\"", 6, :center)
			pdf.add_text_wrap(160, 30, 300 , to_utf16("Ciudad Universitaria de de Caracas, Galpón 7, Frente a Farmacia. Telf.: (0212) 6052982"), 6, :center)
			pdf.add_text_wrap(160, 22, 300 , to_utf16("Telefax: (2012) 6052908"), 6, :center)


      pdf.save_as "Constancia - #{historial.usuario.ci} - #{historial.usuario.nombre_completo}.pdf" if guardar
    end
    pdf

  end

	def self.mes(mun)
		return "Enero" if mun == 1
		return "Febrero" if mun == 2
		return "Marzo" if mun == 3
		return "Abril" if mun == 4
		return "Mayo" if mun == 5
		return "Junio" if mun == 6
		return "Julio" if mun == 7
		return "Agosto" if mun == 8
		return "Septiembre" if mun == 9
		return "Octubre" if mun == 10
		return "Noviembre" if mun == 11
		return "Diciembre" if mun == 12
		
	end

end
