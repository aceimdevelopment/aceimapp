# encoding: utf-8

class DocumentosPDF
  # include ActionView::Helpers::NumberHelper

  def self.to_utf16(valor)
    ic_ignore = Iconv.new('ISO-8859-15//IGNORE//TRANSLIT', 'UTF-8')
    ic_ignore.iconv(valor)
  end

  def self.hola_mundo
    pdf = PDF::Writer.new
    pdf.text to_utf16 "ðåßáåáßäåéëþþüúíœïgßðf© Hólá Mundo"
    return pdf
  end

  def self.notas(historiales,session)
    usuario = session[:usuario]
    pdf = PDF::Writer.new
    pdf.margins_cm(1.8)
    #color de relleno para el pdf (color de las letras)
#    pdf.fill_color(Color::RGB.new(255,255,255))
    #imagen del encabezado
 #   pdf.add_image_from_file 'app/assets/images/banner.jpg', 50, 685, 510, 60
    
    
    pdf.add_image_from_file 'app/assets/images/logo_fhe_ucv.jpg', 465, 710, 50,nil
    pdf.add_image_from_file 'app/assets/images/logo_eim.jpg', 515, 710+10, 50,nil
    pdf.add_image_from_file 'app/assets/images/logo_ucv.jpg', 45, 710, 50,nil
 
    
    #texto del encabezado
    pdf.add_text 100,745,to_utf16("Universidad Central de Venezuela"),11
    pdf.add_text 100,735,to_utf16("Facultad de Humanidades y Educación"),11
    pdf.add_text 100,725,to_utf16("Escuela de Idiomas Modernos"),11
    pdf.add_text 100,715,to_utf16("Cursos de Extensión EIM-UCV"),11

    #texto del encabezado
#    pdf.add_text 70,722,to_utf16("Universidad Central de Venezuela"),7
#    pdf.add_text 70,714,to_utf16("Facultad de Humanidades y Educación"),7
#    pdf.add_text 70,706,to_utf16("Escuela de Idiomas Modernos"),7
#    pdf.add_text 70,698,to_utf16("Administrador de Cursos de Extensión de Idiomas Modernos"),7

    #titulo
    pdf.fill_color(Color::RGB.new(0,0,0))
    historial = historiales.first
    @periodo = historial.periodo
    @tipo_nivel_id = historial.tipo_nivel_id
    @periodo_transicion = Periodo::PERIODO_TRANSICION_NOTAS_PARCIALES

    #periodo_calificacion
    
    pdf.add_text_wrap 50,650,510,to_utf16("#{Seccion.idioma(historial.idioma_id)} (#{Seccion.tipo_categoria(historial.tipo_categoria_id)} - Sección #{historial.seccion_numero})"), 12,:center
    pdf.add_text_wrap 50,635,510,to_utf16(Seccion.horario(session)),10,:center
    pdf.add_text_wrap 50,621,510,to_utf16("Periodo #{ParametroGeneral.periodo_calificacion.id}"),9.5,:center

    #instructor
    pdf.add_text_wrap 50,600,510,to_utf16(usuario.nombre_completo),10
    pdf.add_text_wrap 50,585,505,to_utf16(usuario.ci),10

    pdf.add_text_wrap 50,555,510,to_utf16("<b>Tabla de Calificaciones<b>"),10

    historiales = historiales.sort_by{|h| h.usuario.nombre_completo}
    #  historiales.each { |h|
    #    pdf.text to_utf16 "#{h.usuario.nombre_completo} - #{h.nota_final}"
    #  }
    pdf.text "\n"*18
    tabla = PDF::SimpleTable.new
    tabla.heading_font_size = 8
    tabla.font_size = 8
    tabla.show_lines    = :all
    tabla.line_color = Color::RGB::Gray
    tabla.show_headings = true
    tabla.shade_headings = true
    tabla.shade_heading_color = Color::RGB.new(230,238,238)
    tabla.shade_color = Color::RGB.new(230,238,238)
    tabla.shade_color2 = Color::RGB::White
    tabla.shade_rows = :striped
    tabla.orientation   = :center
    tabla.position      = :center

    if @periodo.es_menor_que? @periodo_transicion

      if !historiales.first.tiene_notas_adicionales?
        tabla.column_order = ["#", "nombre", "cedula", "nota", "descripcion"]
      else
        tabla.column_order = ["#", "nombre", "cedula", "nota1","nota2","nota3","nota4","nota5", "descripcion"]
      end
    elsif ((historial.idioma_id != "IT") and (@tipo_nivel_id.eql? 'CB' or  @tipo_nivel_id.eql? 'CI' or @tipo_nivel_id.eql? 'CA')) 
      tabla.column_order = ["#", "nombre", "cedula", "nota1","nota2","nota3","nota4","nota5", "descripcion"]
    else
      tabla.column_order = ["#", "nombre", "cedula", "nota1","nota2","nota3","nota6","nota4","nota5","descripcion"]
    end

    tabla.columns["#"] = PDF::SimpleTable::Column.new("#") { |col|
      col.width = 20
      col.heading = to_utf16("<b>#</b>")
      col.heading.justification = :center
      col.justification = :center
    }

    tabla.columns["cedula"] = PDF::SimpleTable::Column.new("cedula") { |col|
      col.width = 60
      col.heading = to_utf16("<b>Cédula</b>")
      col.heading.justification = :center
      col.justification = :center
    }

    tabla.columns["nombre"] = PDF::SimpleTable::Column.new("nombre") { |col|
      if !historiales.first.tiene_notas_adicionales?
        col.width = 190
      else
        col.width = 140  
      end
      col.heading = "<b>Nombre</b>"
      col.heading.justification = :left
      col.justification = :left
    }
    
    if !historiales.first.tiene_notas_adicionales?
      tabla.columns["nota"] = PDF::SimpleTable::Column.new("nota") { |col|
        col.width = 80
        col.heading = to_utf16("<b>Final</b>")
        col.heading.justification = :center
        col.justification = :center
      }
    else
      tabla.columns["nota1"] = PDF::SimpleTable::Column.new("nota1") { |col|
        col.width = 50
        col.heading = to_utf16("<b>Exámen Teórico 1</b>")
        col.heading.justification = :center
        col.justification = :center
      }
      tabla.columns["nota2"] = PDF::SimpleTable::Column.new("nota2") { |col|
        col.width = 50
        col.heading = to_utf16("<b>Exámen Teórico 2</b>")
        col.heading.justification = :center
        col.justification = :center
      }
      tabla.columns["nota3"] = PDF::SimpleTable::Column.new("nota3") { |col|
        col.width = 50
        col.heading = to_utf16("<b>Exámen Oral</b>")
        col.heading.justification = :center
        col.justification = :center
      }
      tabla.columns["nota4"] = PDF::SimpleTable::Column.new("nota4") { |col|
        col.width = 40
        col.heading = to_utf16("<b>Otras</b>")
        col.heading.justification = :center
        col.justification = :center
      }
      tabla.columns["nota5"] = PDF::SimpleTable::Column.new("nota5") { |col|
        col.width = 50
        col.heading = to_utf16("<b>Nota</b>")
        col.heading.justification = :center
        col.justification = :center
      }
      # if (not @periodo.es_menor_que? @periodo_transicion) or ( @tipo_nivel_id.eql? 'BI' or @tipo_nivel_id.eql? 'MI' or @tipo_nivel_id.eql? 'AI')
      if (@periodo.es_mayor_que? @periodo_transicion) or (historial.idioma_id.eql? 'IT' or (@tipo_nivel_id != 'CB' and @tipo_nivel_id != 'CI' and @tipo_nivel_id != 'CA'))
      # if ((historial.idioma_id != "IT") and (@tipo_nivel_id.eql? 'CB' or  @tipo_nivel_id.eql? 'CI' or @tipo_nivel_id.eql? 'CA')) 

        tabla.columns["nota6"] = PDF::SimpleTable::Column.new("nota6") { |col|
          col.width = 50
          col.heading = to_utf16("<b>Redac.</b>")
          col.heading.justification = :center
          col.justification = :center
        }
      end
    end

    tabla.columns["descripcion"] = PDF::SimpleTable::Column.new("descripcion") { |col|
      if !historiales.first.tiene_notas_adicionales?
        col.width = 100
      else
        col.width = 70
      end
      col.heading = to_utf16("<b>Descripción</b>")
      col.heading.justification = :left
      col.justification = :left
    }

    data = []

    historiales.each_with_index{|h,i|
      nota_descripcion = to_utf16(HistorialAcademico::NOTASPALABRAS[h.nota_final + 2])
      if !historiales.first.tiene_notas_adicionales?
        data << {"#" => "#{i+1}",
          "cedula" => to_utf16(h.usuario.ci),
          "nombre" => to_utf16(h.usuario.nombre_completo),
          "nota" => to_utf16(HistorialAcademico.colocar_nota(h.nota_final)),
          "descripcion" => nota_descripcion 
        }
      else
        nota1 = h.nota_en_evaluacion(HistorialAcademico::EXAMENESCRITO1).nota_valor 
        nota2 = h.nota_en_evaluacion(HistorialAcademico::EXAMENESCRITO2).nota_valor
        nota3 = h.nota_en_evaluacion(HistorialAcademico::EXAMENORAL).nota_valor
        nota4 = h.nota_en_evaluacion(HistorialAcademico::OTRAS).nota_valor
        
        # if (not @periodo.es_menor_que? @periodo_transicion) or ( @tipo_nivel_id.eql? 'BI' or @tipo_nivel_id.eql? 'MI' or @tipo_nivel_id.eql? 'AI')
        if (@periodo.es_mayor_que? @periodo_transicion) or (historial.idioma_id.eql? 'IT' or (@tipo_nivel_id != 'CB' and @tipo_nivel_id != 'CI' and @tipo_nivel_id != 'CA'))
        
          nota6 = h.nota_en_evaluacion(HistorialAcademico::REDACCION).nota_valor
  
          data << {"#" => "#{i+1}",
            "cedula" => to_utf16(h.usuario.ci),
            "nombre" => to_utf16(h.usuario.nombre_completo),
            "nota1" => to_utf16(nota1),
            "nota2" => to_utf16(nota2),
            "nota3" => to_utf16(nota3),
            "nota4" => to_utf16(nota4),
            "nota5" => to_utf16(HistorialAcademico.colocar_nota(h.nota_final)),
            "nota6" => to_utf16(nota6),            
            "descripcion" => nota_descripcion
          }

        else
          data << {"#" => "#{i+1}",
            "cedula" => to_utf16(h.usuario.ci),
            "nombre" => to_utf16(h.usuario.nombre_completo),
            "nota1" => to_utf16(nota1),
            "nota2" => to_utf16(nota2),
            "nota3" => to_utf16(nota3),
            "nota4" => to_utf16(nota4),
            "nota5" => to_utf16(HistorialAcademico.colocar_nota(h.nota_final)),
            "descripcion" => nota_descripcion
          }

        end
        
      end
    }
    tabla.data.replace data
    tabla.render_on(pdf)
    pdf.add_text 430,50,to_utf16("#{Time.now.strftime('%d/%m/%Y %I:%M%p')} - Página: 1 de 1")
    return pdf
  end

# NUEVO SISTEMA  DE CALIFICACION 30

  def self.notas_30(historiales,session)
    usuario = session[:usuario]
    pdf = PDF::Writer.new
    pdf.margins_cm(1.8)
    
    pdf.add_image_from_file 'app/assets/images/logo_fhe_ucv.jpg', 465, 710, 50,nil
    pdf.add_image_from_file 'app/assets/images/logo_eim.jpg', 515, 710+10, 50,nil
    pdf.add_image_from_file 'app/assets/images/logo_ucv.jpg', 45, 710, 50,nil
 
    
    #texto del encabezado
    pdf.add_text 100,745,to_utf16("Universidad Central de Venezuela"),11
    pdf.add_text 100,735,to_utf16("Facultad de Humanidades y Educación"),11
    pdf.add_text 100,725,to_utf16("Escuela de Idiomas Modernos"),11
    pdf.add_text 100,715,to_utf16("Cursos de Extensión EIM-UCV"),11

    #titulo
    pdf.fill_color(Color::RGB.new(0,0,0))
    historial = historiales.first
    @periodo = historial.periodo
    @tipo_nivel_id = historial.tipo_nivel_id
    @periodo_30 = Periodo::PERIODO_30

    #periodo_calificacion
    
    pdf.add_text_wrap 50,650,510,to_utf16("#{Seccion.idioma(historial.idioma_id)} (#{Seccion.tipo_categoria(historial.tipo_categoria_id)} - Sección #{historial.seccion_numero})"), 12,:center
    pdf.add_text_wrap 50,635,510,to_utf16(Seccion.horario(session)),10,:center
    pdf.add_text_wrap 50,621,510,to_utf16("Periodo #{ParametroGeneral.periodo_calificacion.id}"),9.5,:center

    #instructor
    pdf.add_text_wrap 50,600,510,to_utf16(usuario.nombre_completo),10
    pdf.add_text_wrap 50,585,505,to_utf16(usuario.ci),10

    pdf.add_text_wrap 50,555,510,to_utf16("<b>Tabla de Calificaciones<b>"),10

    historiales = historiales.sort_by{|h| h.usuario.nombre_completo}
    #  historiales.each { |h|
    #    pdf.text to_utf16 "#{h.usuario.nombre_completo} - #{h.nota_final}"
    #  }
    pdf.text "\n"*18
    tabla = PDF::SimpleTable.new
    tabla.heading_font_size = 8
    tabla.font_size = 8
    tabla.show_lines    = :all
    tabla.line_color = Color::RGB::Gray
    tabla.show_headings = true
    tabla.shade_headings = true
    tabla.shade_heading_color = Color::RGB.new(230,238,238)
    tabla.shade_color = Color::RGB.new(230,238,238)
    tabla.shade_color2 = Color::RGB::White
    tabla.shade_rows = :striped
    tabla.orientation   = :center
    tabla.position      = :center

    tabla.column_order = ["#", "nombre", "cedula", "nota1","nota2","nota3","nota4","notafinal", "descripcion"]


    tabla.columns["#"] = PDF::SimpleTable::Column.new("#") { |col|
      col.width = 20
      col.heading = to_utf16("<b>#</b>")
      col.heading.justification = :center
      col.justification = :center
    }

    tabla.columns["cedula"] = PDF::SimpleTable::Column.new("cedula") { |col|
      col.width = 60
      col.heading = to_utf16("<b>Cédula</b>")
      col.heading.justification = :center
      col.justification = :center
    }

    tabla.columns["nombre"] = PDF::SimpleTable::Column.new("nombre") { |col|
      col.width = 150
      col.heading = "<b>Nombre</b>"
      col.heading.justification = :left
      col.justification = :left
    }
    
    tabla.columns["nota1"] = PDF::SimpleTable::Column.new("nota1") { |col|
      col.width = 50
      col.heading = to_utf16("<b>Exámen Teórico 1 (30%)</b>")
      col.heading.justification = :center
      col.justification = :center
    }
    tabla.columns["nota2"] = PDF::SimpleTable::Column.new("nota2") { |col|
      col.width = 50
      col.heading = to_utf16("<b>Exámen Teórico 2 (30%)</b>")
      col.heading.justification = :center
      col.justification = :center
    }
    tabla.columns["nota3"] = PDF::SimpleTable::Column.new("nota3") { |col|
      col.width = 50
      col.heading = to_utf16("<b>Exámen Oral (30%)</b>")
      col.heading.justification = :center
      col.justification = :center
    }
    tabla.columns["nota4"] = PDF::SimpleTable::Column.new("nota4") { |col|
      col.width = 50
      col.heading = to_utf16("<b>Otros (10%)</b>")
      col.heading.justification = :center
      col.justification = :center
    }
    tabla.columns["notafinal"] = PDF::SimpleTable::Column.new("notafinal") { |col|
      col.width = 50
      col.heading = to_utf16("<b>Final</b>")
      col.heading.justification = :center
      col.justification = :center
    }

    tabla.columns["descripcion"] = PDF::SimpleTable::Column.new("descripcion") { |col|
      if !historiales.first.tiene_notas_adicionales?
        col.width = 100
      else
        col.width = 70
      end
      col.heading = to_utf16("<b>Descripción</b>")
      col.heading.justification = :left
      col.justification = :left
    }

    data = []

    historiales.each_with_index{|h,i|
      nota_descripcion = to_utf16(HistorialAcademico::NOTASPALABRAS[h.nota_final + 2])

      nota1 = h.nota_en_evaluacion(HistorialAcademico::EXAMENESCRITO1).nota_valor 
      nota2 = h.nota_en_evaluacion(HistorialAcademico::EXAMENESCRITO2).nota_valor
      nota3 = h.nota_en_evaluacion(HistorialAcademico::EXAMENORAL).nota_valor
      nota4 = h.nota_en_evaluacion(HistorialAcademico::OTRAS).nota_valor

      data << {"#" => "#{i+1}",
        "cedula" => to_utf16(h.usuario.ci),
        "nombre" => to_utf16(h.usuario.nombre_completo),
        "nota1" => to_utf16(nota1),
        "nota2" => to_utf16(nota2),
        "nota3" => to_utf16(nota3),
        "nota4" => to_utf16(nota4),
        "notafinal" => to_utf16(HistorialAcademico.colocar_nota(h.nota_final)),
        "descripcion" => nota_descripcion
      }
    }
    tabla.data.replace data
    tabla.render_on(pdf)
    pdf.add_text 430,50,to_utf16("#{Time.now.strftime('%d/%m/%Y %I:%M%p')} - Página: 1 de 1")
    return pdf
  end


# FIN NUEVO SISTEMA DE CALIFICACION 30






  def self.datos_preinscripcion(historial_academico,pdf,profesor=nil)    

    #titulo
    pdf.text to_utf16("Planilla de Inscripción (Sede Ciudad Universitaria)\n"), :font_size => 11, :justification => :center
    pdf.text to_utf16("Periodo #{historial_academico.periodo_id}"), :justification => :center

    # ------- DATOS DE LA PREINSCRIPCIO -------
		pdf.text "\n", :font_size => 8
		pdf.text to_utf16("<b>Datos de la Preinscripción:</b>"), :font_size => 11
    tabla = PDF::SimpleTable.new 
    tabla.font_size = 10
    tabla.show_lines    = :none
    tabla.show_headings = false 
    tabla.shade_rows = :none
    tabla.column_order = ["nombre", "valor"]

    tabla.columns["nombre"] = PDF::SimpleTable::Column.new("nombre") { |col|
      col.width = 90
      col.justification = :left
    }
    tabla.columns["valor"] = PDF::SimpleTable::Column.new("valor") { |col|
      col.width = 420
      col.justification = :left
    }
    datos = []
    
    datos << { "nombre" => to_utf16("<b>Estudiante:</b>"), "valor" => to_utf16("#{historial_academico.usuario.descripcion}\n#{historial_academico.usuario.datos_contacto}") }
    datos << { "nombre" => to_utf16("<b>Curso:</b>"), "valor" => to_utf16("#{historial_academico.descripcion_completa}") }
    datos << { "nombre" => to_utf16("<b>Horario:</b>"), "valor" => to_utf16("#{historial_academico.seccion.horario}") }
    datos << { "nombre" => to_utf16("<b>Aula:</b>"), "valor" => to_utf16("#{historial_academico.seccion.aula}") }
    if historial_academico.tipo_convenio_id != "REG"
      datos << { "nombre" => to_utf16("<b>Convenio:</b>"), "valor" => to_utf16("#{historial_academico.tipo_convenio.descripcion}") }
    end

    monto = historial_academico.cuenta_monto
    # monto_soberano = (monto.is_a? Float) ? "(#{monto.to_i/1000} Bs. S)" : "" 
    datos << { "nombre" => to_utf16("<b>Monto:</b>"), "valor" => to_utf16("#{monto} Bs.S / <b>Transacción #</b>: _________________________ Tipo: T ___  D ___ P ___") } if profesor
    datos << { "nombre" => to_utf16("<b>Acreditada en:</b>"), "valor" => to_utf16("FHyE ___ FUNDEIM ___ ") } if profesor
    tabla.data.replace datos
    tabla.render_on(pdf)

  end

  def self.datos_cuentas(historial_academico,pdf)
        # -------- TABLA CUENTA -------
    pdf.text "\n", :font_size => 8
    pdf.text to_utf16("<b>Datos de Pago:</b> (Depósito en efectivo o transferencia <i>únicamente</i> del mismo banco)."), :font_size => 11
#    pdf.text to_utf16("Cuenta Corriente <b>#{historial_academico.cuenta_numero}</b> del Banco: Banco de Venezuela"), :font_size => 11
    tabla = PDF::SimpleTable.new 
    tabla.font_size = 10
    tabla.show_lines    = :none
    tabla.show_headings = false 
    tabla.shade_rows = :none
    tabla.column_order = ["nombre", "valor"]

    tabla.columns["nombre"] = PDF::SimpleTable::Column.new("nombre") { |col|
      col.width = 90
      col.justification = :left
    }
    tabla.columns["valor"] = PDF::SimpleTable::Column.new("valor") { |col|
      col.width = 420
      col.justification = :left
    }
    datos = []

    datos << { "nombre" => "", "valor" => to_utf16("<b>Cuenta Corriente #{historial_academico.cuenta_numero}</b> del Banco de Venezuela") }
    datos << { "nombre" => to_utf16("<b>A nombre de:</b>"), "valor" => to_utf16("#{historial_academico.cuenta_nombre}") }
    # datos << { "nombre" => to_utf16("<b>Monto:</b>"), "valor" => to_utf16("#{historial_academico.cuenta_monto} BsF.") }
    monto = historial_academico.cuenta_monto
    # monto_soberano = (monto.is_a? Float) ? "(#{monto.to_i/1000} Bs. S)" : "" 

    datos << { "nombre" => to_utf16("<b>Monto:</b>"), "valor" => to_utf16("#{monto} Bs.S / <b>Transacción #</b>: _________________________ Tipo: T ___  D ___ P ___") }
    datos << { "nombre" => to_utf16("<b>Acreditada en:</b>"), "valor" => to_utf16("FHyE ___ FUNDEIM ___ ") }

    tabla.data.replace datos  
    tabla.render_on(pdf)
    pdf.text to_utf16("<b>*** Acepté las condiciones y normativas del programa. ***</b>"), :font_size => 10
    pdf.text "\n", :font_size => 10

  end

  def self.firmas(historial_academico,pdf)
    # -- FIRMAS -----
    pdf.text "\n\n", :font_size => 8
    tabla = PDF::SimpleTable.new 
    tabla.font_size = 11
    tabla.orientation   = :center
    tabla.position      = :center
    tabla.show_lines    = :none
    tabla.show_headings = false 
    tabla.shade_rows = :none
    tabla.column_order = ["nombre", "valor"]

    tabla.columns["nombre"] = PDF::SimpleTable::Column.new("nombre") { |col|
      col.width = 250
      col.justification = :center
    }
    tabla.columns["valor"] = PDF::SimpleTable::Column.new("valor") { |col|
      col.width = 250
      col.justification = :center
    }
    @persona = (historial_academico.tipo_categoria_id == "NI" || historial_academico.tipo_categoria_id == "TE") ? "Representante" : "Estudiante" 
    datos = []
    datos << { "nombre" => to_utf16("<b>__________________________</b>"), "valor" => to_utf16("<b>__________________________</b>") }
    datos << { "nombre" => to_utf16("Firma #{@persona}"), "valor" => to_utf16("Firma Autorizada y Sello") }
    tabla.data.replace datos  
    tabla.render_on(pdf)
    pdf.text "\n", :font_size => 8
    
  end

  def self.factura(factura)
    # require ActionView::Helpers::NumberHelper
    pdf = PDF::Writer.new(:paper => "letter")

    pdf.text "\n\n\n\n\n\n\n", :font_size => 12


    # pdf.text to_utf16("<b>Datos de la Preinscripción:</b>"), :font_size => 12
    tabla = PDF::SimpleTable.new 
    tabla.font_size = 10
    tabla.show_lines    = :none
    tabla.show_headings = false
    tabla.shade_rows = :none
    tabla.row_gap = 6
    tabla.column_order = ["nombre", "valor"]

    tabla.columns["nombre"] = PDF::SimpleTable::Column.new("nombre") { |col|
      col.width = 490
      col.justification = :left
    }
    tabla.columns["valor"] = PDF::SimpleTable::Column.new("valor") { |col|
      col.width = 90
      col.justification = :right
    }
    datos = []
    
    datos << { "nombre" => to_utf16("                                                 <i>#{factura.cliente.razon_social}</i>"), "valor" => to_utf16("<i>#{factura.fecha.strftime("%d/%m/%Y") if factura.fecha}</i>") }
    datos << { "nombre" => to_utf16("                                       <i>#{factura.cliente.domicilio}</i>"), "valor" => "" }
    datos << { "nombre" => to_utf16("<i>#{factura.cliente.telefono_fijo_obligatorio.to_s.rjust(40)}</i><i>#{factura.cliente.telefono_movil.rjust(42)}</i>"), "valor" => "<i>#{factura.cliente.rif.to_s.ljust(12)}</i>" }

    tabla.data.replace datos
    tabla.render_on(pdf)

    pdf.text "\n\n\n", :font_size => 12


    tabla = PDF::SimpleTable.new 
    tabla.font_size = 10
    tabla.show_lines    = :none
    tabla.show_headings = false
    tabla.shade_rows = :none
    tabla.column_order = ["no", "descripcion", "unidad", "cantidad", "costo", "total"]
    tabla.row_gap = 5
    tabla.position = 305
    tabla.protect_rows = 15
    tabla.columns["no"] = PDF::SimpleTable::Column.new("no") { |col|
      col.width = 20
      col.justification = :center
    }
    tabla.columns["descripcion"] = PDF::SimpleTable::Column.new("descripcion") { |col|
      col.width = 280
      col.justification = :left
    }

    tabla.columns["unidad"] = PDF::SimpleTable::Column.new("unidad") { |col|
      col.width = 50
      col.justification = :center
    }    
    tabla.columns["cantidad"] = PDF::SimpleTable::Column.new("cantidad") { |col|
      col.width = 50
      col.justification = :center
    }
    tabla.columns["costo"] = PDF::SimpleTable::Column.new("costo") { |col|
      col.width = 80
      col.justification = :right
    }

    tabla.columns["total"] = PDF::SimpleTable::Column.new("total") { |col|
      col.width = 90
      col.justification = :right
    }
    # numero = ActionView::Helpers::NumberHelper
    datos = []
    
    factura.detalle_facturas.each_with_index do |detalle, i|
      i += 1
      descrip = detalle.descripcion.blank? ? detalle.curso_periodo.descripcion : detalle.descripcion 
      datos << { "no" => "<i>#{i}</i>", "descripcion" => to_utf16("<i>#{descrip}</i>"), "unidad"=> "<i>Cursos</i>", "cantidad" => "<i>#{detalle.cantidad.to_s}</i>", "costo" => "<i>#{format("%.2f", detalle.costo_unitario)}</i>", "total" => "<i>#{format("%.2f",detalle.total)}</i>" }

    end

 

    tabla.data.replace datos
    tabla.render_on(pdf)
    monto = format("%.2f", factura.monto_total)
    x = 550-monto.length
    pdf.add_text x,194,"<i>#{monto}</i>",10
    pdf.add_text 562,180,"<i>0.00</i>",10
    pdf.add_text x,164,"<i>#{monto}</i>",10    

    return pdf
  end



  def self.datos_facturacion(historial_academico,pdf)

        # -------- TABLA CUENTA -------
    pdf.text "\n", :font_size => 8
    pdf.text to_utf16("<b>Si requiere una factura fiscal llene los siguientes campos:</b>"), :font_size => 11
    tabla = PDF::SimpleTable.new 
    tabla.font_size = 10
    tabla.show_lines    = :none
    tabla.show_headings = false 
    tabla.shade_rows = :none
    tabla.column_order = ["nombre", "valor"]

    tabla.columns["nombre"] = PDF::SimpleTable::Column.new("nombre") { |col|
      col.width = 90
      col.justification = :left
    }
    tabla.columns["valor"] = PDF::SimpleTable::Column.new("valor") { |col|
      col.width = 420
      col.justification = :left
    }
    datos = []
    
    datos << { "nombre" => to_utf16("<b>A Nombre de:</b>"), "valor" => to_utf16("_________________________________________________________________________") }
    datos << { "nombre" => to_utf16("<b>CI ó RIF:</b>"), "valor" => to_utf16("_________________________________ <b>TLF:</b> ___________________________________") }
    datos << { "nombre" => to_utf16("<b>Dirección:</b>"), "valor" => to_utf16("_________________________________________________________________________") }
    tabla.data.replace datos  
    tabla.render_on(pdf)
    pdf.text "\n", :font_size => 10

  end  



  def self.planilla_inscripcion(historial_academico=nil)
    pdf = PDF::Writer.new(:paper => "letter")  #:orientation => :landscape, 
    t = Time.now

    pdf.add_image_from_file 'app/assets/images/logo_fhe_ucv.jpg', 465, 710, 50,nil
    pdf.add_image_from_file 'app/assets/images/logo_eim.jpg', 515, 710+10, 50,nil
    pdf.add_image_from_file 'app/assets/images/logo_ucv.jpg', 45, 710, 50,nil
    pdf.add_image_from_file Rutinas.crear_codigo_barra(historial_academico.usuario_ci), 460, 600, nil, 100
    pdf.add_text 480,600,to_utf16("---- #{historial_academico.usuario_ci} ----"),11
    
    #texto del encabezado
    pdf.add_text 100,745,to_utf16("Universidad Central de Venezuela"),10
    pdf.add_text 100,735,to_utf16("Facultad de Humanidades y Educación"),10
    pdf.add_text 100,725,to_utf16("Escuela de Idiomas Modernos"),10
    pdf.add_text 100,715,to_utf16("Cursos de Extensión EIM-UCV"),10

    pdf.text "\n\n\n\n"

    datos_preinscripcion(historial_academico,pdf)

    datos_cuentas(historial_academico,pdf)

    firmas(historial_academico,pdf)      
 
		pdf.text to_utf16("----- COPIA DEL ESTUDIANTE -----"), :font_size => 10, :justification => :center

    alto_tijeras = 390
    alto_tijeras = alto_tijeras - 13 if historial_academico.tipo_convenio_id != "REG"

    pdf.add_image_from_file 'app/assets/images/tijeras.jpg', 10, alto_tijeras, 25, nil
    # pdf.add_image_from_file Rutinas.crear_codigo_barra(historial_academico.usuario_ci), 460, 280, nil, 100
    pdf.text to_utf16("-----------------------------------------------------------------------------------------------------------------------------------------------------------"), :font_size => 10
  
    # pdf.text to_utf16("#{t.strftime('%d/%m/%Y %I:%M%p')} - Página: 1 de 2"), :font_size => 10, :justification => :right

    # pdf.new_page
    # pdf.y = 756
    pdf.text "\n"
    pdf.add_image_from_file Rutinas.crear_codigo_barra(historial_academico.usuario_ci), 460, 280, nil, 100
    pdf.add_text 480,280,to_utf16("---- #{historial_academico.usuario_ci} ----"),11

    datos_preinscripcion(historial_academico,pdf,true)
    # pdf.text to_utf16("  <b>Monto:</b>       #{historial_academico.cuenta_monto} BsF. / <b>Depósito No.</b>: _________________________________________"), :font_size => 10

    datos_facturacion(historial_academico,pdf)
    firmas(historial_academico,pdf)


		pdf.text to_utf16("----- COPIA ADMINISTRACIÓN -----"), :font_size => 10, :justification => :center

   
    return pdf
  end
  
  def self.generar_listado_estudiantes(periodo,idioma,nivel,\
  categoria,seccion_numero,guardar=false, admin=false)

    
    historial = HistorialAcademico.where(:periodo_id=>periodo, :idioma_id=>idioma, :tipo_nivel_id=>nivel, :tipo_categoria_id=>categoria, :seccion_numero=>seccion_numero, :tipo_estado_inscripcion_id=>"INS")
    historial = historial.sort_by{|x| x.usuario.nombre_completo}
    pdf = PDF::Writer.new(:paper => "letter")  #:orientation => :landscape, 
    
    ss = PDF::Writer::StrokeStyle.new(2)
		ss.cap = :round
		pdf.stroke_style ss

    pdf.add_image_from_file 'app/assets/images/logo_fhe_ucv.jpg', 45, 710, 50,nil
    pdf.add_image_from_file 'app/assets/images/logo_eim.jpg', 515, 710, 50,nil
    pdf.add_image_from_file 'app/assets/images/logo_ucv.jpg', 275, 710, 50,nil
    pdf.line 35,700,575,700
    
    if historial.size > 0
      @seccion = historial.last.seccion
			pdf.text "\n\n\n\n\n"
      pdf.text to_utf16("<b>Período:</b> #{historial.last.periodo_id}"), :justification => :center
      pdf.text to_utf16("<b>Curso:</b> #{Seccion.idioma(@seccion.idioma)} #{Seccion.tipo_categoria(@seccion.tipo_categoria)} #{@seccion.tipo_nivel.descripcion} - #{"%002i"%@seccion.seccion_numero}"), :justification => :center        
      pdf.text to_utf16("<b>Aula:</b> #{@seccion.aula}"), :justification => :center
      pdf.text to_utf16("<b>Horario:</b> #{@seccion.horario}"), :justification => :center
      if @seccion.instructor
        pdf.text to_utf16("<b>Profesor:</b> #{@seccion.instructor.nombre_completo}"), :justification => :center
      else                                                                                                   
        pdf.text to_utf16("<b>Profesor:</b> NO ASIGNADO"), :justification => :center
      end
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
      # if admin
      #   tab.column_order = ["nro","nombre","cedula", "correo", "pago","telefono"]
      # else  
      #   tab.column_order = ["nro","nombre","cedula", "correo","telefono"]
      # end
      tab.column_order = ["nro","nombre","cedula", "correo","telefono"]
      tab.columns["nro"] = PDF::SimpleTable::Column.new("nro") { |col|
        col.width = 25
        col.justification = :right
        col.heading = "#"
        col.heading.justification= :center
      }
      tab.columns["nombre"] = PDF::SimpleTable::Column.new("nombre") { |col|
        col.width = 150
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
        col.width = 120
        col.justification = :left
        col.heading = "CORREO"
        col.heading.justification= :center
      }
      # if admin
      #   tab.columns["pago"] = PDF::SimpleTable::Column.new("pago") { |col|
      #     col.width = 100
      #     col.justification = :left
      #     col.heading = "PAGO"
      #     col.heading.justification= :center
      #   }
      # end
      tab.columns["telefono"] = PDF::SimpleTable::Column.new("telefono") { |col|
        col.width = 80
        col.justification = :left
        col.heading = "TELEFONO"
        col.heading.justification= :center
      }

      data = []

      historial.each_with_index{|reg,ind|
        # if admin
        #   aux = {
        #     "nro" => "#{(ind+1)}",          
        #     "nombre" => to_utf16(reg.usuario.nombre_completo),
        #     "cedula" => reg.usuario_ci,
        #     "correo" => reg.usuario.correo,
        #     "pago" => reg.descripcion_pago,
        #     "telefono" => reg.usuario.telefono_movil
        #   }

        # else
          aux = {
            "nro" => "#{(ind+1)}",          
            "nombre" => to_utf16(reg.usuario.nombre_completo),
            "cedula" => reg.usuario_ci,
            "correo" => reg.usuario.correo,
            "telefono" => reg.usuario.telefono_movil
          }
        # end
        data << aux
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

  def self.generar_listado_secciones(periodo,guardar=false,filtro=nil,filtro2=nil, filtro3=nil, filtro4 = nil)
    secciones = nil
    secciones = Seccion.where(:periodo_id => periodo)
    if filtro
      idioma_id , tipo_categoria_id = filtro.split ","
      
      secciones = Seccion.where(:periodo_id => periodo, :idioma_id => idioma_id,
        :tipo_categoria_id => tipo_categoria_id)
    end
    if filtro2
      secciones2 = []
      secciones.each{|s|
        aula = s.horario_seccion.first.aula
        secciones2 << s if aula && aula.tipo_ubicacion_id == filtro2
      }                
      secciones = secciones2
    end
    
    if filtro3
      secciones = Seccion.where(:periodo_id=>periodo).delete_if{|s| !s.mach_horario?(filtro3)}
    end          
                                     
    if filtro4
      ids = filtro4.split("_").compact 
      secciones = []
      ids.each{|iden|
        periodo_id, idioma_id, tipo_categoria_id, tipo_nivel_id, seccion_numero = iden.split(",")
        secciones << Seccion.where(
          :periodo_id => periodo_id,
          :idioma_id => idioma_id,
          :tipo_categoria_id => tipo_categoria_id,
          :tipo_nivel_id => tipo_nivel_id,
          :seccion_numero => seccion_numero
        ).limit(1).first
      }
    end
    
    
    secciones = secciones.sort_by{|x| "#{x.tipo_curso.id}-#{'%03i'%x.curso.grado}-#{x.horario}-#{x.seccion_numero}"}
    pdf = PDF::Writer.new(:paper => "letter",:orientation => :landscape)

    pdf.add_image_from_file 'app/assets/images/logo_fhe_ucv.jpg', 65, 550, 50,nil
    pdf.add_image_from_file 'app/assets/images/logo_eim.jpg', 665, 550, 50,nil
    pdf.add_image_from_file 'app/assets/images/logo_ucv.jpg', 365, 550, 50,nil
    
    pdf.line 55,545,720,545
    
    pdf.text "\n\n\n"
    pdf.text "SECCIONES #{periodo}\n",:justification => :center
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

    tab.column_order = ["PRE", "INS","idioma","nivel","seccion","horario","aula","instructor"]
    tab.columns["preinscritos"] = PDF::SimpleTable::Column.new("preinscritos") { |col|
      col.width = 30
      col.justification = :center
      col.heading = to_utf16 "PRE"
      col.heading.justification= :center
    }
    tab.columns["inscritos"] = PDF::SimpleTable::Column.new("inscritos") { |col|
      col.width = 30
      col.justification = :center
      col.heading = "INS"
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
      col.width = 30
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
    tab.columns["instructor"] = PDF::SimpleTable::Column.new("instructor") { |col|
      col.width = 140
      col.justification = :left
      col.heading = "INSTRUCTOR"
      col.heading.justification= :center
    }

    if secciones.size > 0
      data = []
      
      tab.column_order = ["preinscritos", "inscritos","idioma","nivel","seccion","horario","aula","instructor"]

      secciones.each{|sec|
        instructor = (sec.instructor) ? to_utf16("#{sec.instructor.descripcion}") : "-- NO ASIGNADO --"
        data << {
          "preinscritos" => to_utf16("#{sec.preinscritos}"),
          "inscritos" => to_utf16("#{sec.inscritos}"),  
          "idioma" => to_utf16("#{sec.idioma.descripcion} (#{sec.tipo_categoria.descripcion})"), 
          "nivel" => to_utf16("#{sec.tipo_nivel.descripcion}"), 
          "seccion" => to_utf16("#{sec.seccion_numero}"), 
          "horario" => to_utf16("#{sec.horario}"), 
          "aula" => to_utf16("#{sec.aula_corta}"),       
          "instructor" => instructor
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
 
  def self.generar_constancia_notas(ci,idioma,categoria,guardar=false)

    #historial = HistorialAcademico.all(
    #:conditions => ["usuario_ci = ?",ci])
    historial = HistorialAcademico.where(:usuario_ci=>ci,:idioma_id=>idioma,:tipo_categoria_id=>categoria)
    historial = historial.sort_by{|x| x.curso.grado}

		#pdf.add_image_from_file 'public/images/logo_pi_color1.jpg', 55, 660, 490,nil

    pdf = PDF::Writer.new(:paper => "letter")  #:orientation => :landscape, 
    
    ss = PDF::Writer::StrokeStyle.new(2)
		ss.cap = :round
		pdf.stroke_style ss

    pdf.add_image_from_file 'app/assets/images/logo_fhe_ucv.jpg',45, 710, 50,nil
    pdf.add_image_from_file 'app/assets/images/logo_eim.jpg', 515, 710, 50,nil
    pdf.add_image_from_file 'app/assets/images/logo_ucv.jpg', 280, 710, 50,nil
    pdf.text "\n\n\n\n"
    pdf.margins_mm(30)
    pdf.text "UNIVERSIDAD CENTRAL DE VENEZUELA", :font_size => 6,:justification => :center
    pdf.text to_utf16("FACULTAD DE HUMANIDADES Y EDUCACIÓN"), :font_size => 6,:justification => :center
    pdf.text "ESCUELA DE IDIOMAS MODERNOS", :font_size => 6,:justification => :center
    
    #pdf.image "public/images/Logo FHE-UCV.jpg", :justification => :left, :width => 50
    #pdf.image "public/images/Logo FHE-UCV.jpg", :justification => :center, :width => 50, :pad => 0
    
    pdf.line 35,650,575,700
    
    #pdf.add_image_from_file 'public/images/logoEIM.jpg', 5, 660, 50,nil
    
    if historial.size > 0
    	#pdf.select_font "Helvetica"
    	pdf.text "\n\n\n\n"
    	pdf.text "<b>CONSTANCIA</b>", :font_size => 20,:justification => :center
    	pdf.text "\n"
    	pdf.text to_utf16("Quien suscribe, Prof. Lucius Daniel, Director de la Escuela de Idiomas Modernos de la Facultad de Humanidades y Educación de la Universidad Central de Venezuela, hace constar por medio de la presente que #{sexo(historial.first.usuario.tipo_sexo_id,"la","el")} ciudadan#{sexo(historial.first.usuario.tipo_sexo_id,"a","o")}:"), :font_size => 11, :justification => :full
    	pdf.text "\n"
    	pdf.text "<b>#{to_utf16(historial.first.usuario.nombres)} #{to_utf16(historial.first.usuario.apellidos)} (#{to_utf16(historial.first.usuario.ci)})</b>",:justification => :center, :font_size => 12
    	
    	if historial.size
    	  
  	  end
			pdf.text "\n"
			pdf.text to_utf16("aprobó del curso <b>#{historial.first.tipo_curso.descripcion}</b> #{pluralize(historial.count, "el", "los")}  #{pluralize(historial.count, "nivel","niveles")} que se indican a continuación:"), :font_size => 11, :justification => :full
			pdf.text "\n"
            
      #pdf.line 35,630,575,630
      
      tab = PDF::SimpleTable.new
      tab.bold_headings = true
      tab.show_lines    = :none
      tab.show_headings = true
      tab.shade_rows = :none
      tab.orientation   = :center
      tab.heading_font_size = 8
      tab.font_size = 10
      tab.row_gap = 1
      tab.minimum_space = 0
      
      tab.column_order = ["nivel","periodo","nota"]
      tab.columns["nivel"] = PDF::SimpleTable::Column.new("nivel") { |col|
        col.width = 160
        col.justification = :center
        col.heading = to_utf16 "Nivel"
        col.heading.justification= :center
      }
      tab.columns["periodo"] = PDF::SimpleTable::Column.new("periodo") { |col|
        col.width = 80
        col.justification = :center
        col.heading = to_utf16("Período")
        col.heading.justification= :center
      }
      tab.columns["nota"] = PDF::SimpleTable::Column.new("nota") { |col|
        col.width = 80
        col.justification = :center
        col.heading = to_utf16("Calificación")
        col.heading.justification= :center
      }

      data = []

      historial.each{|reg|
      	if reg.aprobo_curso?
      	
      	data << {        
          "nivel" => "<b>#{to_utf16(reg.tipo_nivel.descripcion)}</b>",
          "periodo" => "<b>#{reg.periodo_id}</b>",
          "nota" => "<b>#{"%002i"%reg.nota_final}</b>"
        }
        
      	end
      	
        
      }
			tab.data.replace data
			tab.render_on(pdf)
			
			t = Time.new
			
			pdf.text "\n\n\n"
			pdf.text to_utf16("Cada nivel tiene una duración de 54 horas académicas (9 semanas aproximadamente). Esta constancia se expide a solicitud del interesad#{sexo(historial.first.usuario.tipo_sexo_id,"a","o")}."), :font_size => 11, :justification => :full
			
			pdf.text to_utf16("En Caracas, a los #{t.day} días del mes de #{mes(t.month)} de #{t.year}"), :font_size => 11, :justification => :full
			
			pdf.text "\n"
			pdf.image 'app/assets/images/firma.jpg', :justification => :center, :resize => 0.4
			pdf.text "____________________________" , :justification => :center, :font_size => 6
			pdf.text "Prof. Lucius Daniel" , :justification => :center, :font_size => 11
			
			
			pdf.add_text_wrap(160, 38, 300 , "\"CIUDAD UNIVERSITARIA DE CARACAS - PATRIMONIO CULTURAL DE LA HUMANIDAD\"", 6, :center)
			pdf.add_text_wrap(160, 30, 300 , to_utf16("Ciudad Universitaria de de Caracas, Galpón 7, Frente a Farmacia. Telf.: (0212) 6052982"), 6, :center)
			pdf.add_text_wrap(160, 22, 300 , to_utf16("Telefax: (2012) 6052908"), 6, :center)


      pdf.save_as "Constancia - #{historial.usuario.ci} - #{historial.usuario.nombre_completo}.pdf" if guardar
    end
    pdf

  end


  def self.generar_constancia_estudio(ci,idioma,categoria,remitente, periodo,guardar=false)

    #periodo_actual = ParametroGeneral.periodo_actual
    historial = HistorialAcademico.where(:periodo_id=> periodo, :usuario_ci=>ci,:idioma_id=>idioma,:tipo_categoria_id=>categoria).limit(1).first


    pdf = PDF::Writer.new(:paper => "letter")  #:orientation => :landscape, 
    
    ss = PDF::Writer::StrokeStyle.new(2)
		ss.cap = :round
		pdf.stroke_style ss

    pdf.add_image_from_file 'app/assets/images/logo_fhe_ucv.jpg',45, 710, 50,nil
    pdf.add_image_from_file 'app/assets/images/logo_eim.jpg', 515, 710, 50,nil
    pdf.add_image_from_file 'app/assets/images/logo_ucv.jpg', 280, 710, 50,nil
    pdf.text "\n\n\n\n"
    pdf.margins_mm(30)
    pdf.text "UNIVERSIDAD CENTRAL DE VENEZUELA", :font_size => 6,:justification => :center
    pdf.text to_utf16("FACULTAD DE HUMANIDADES Y EDUCACIÓN"), :font_size => 6,:justification => :center
    pdf.text "ESCUELA DE IDIOMAS MODERNOS", :font_size => 6,:justification => :center

    if historial
    	pdf.text "\n\n\n"
    	pdf.text to_utf16("<b>#{remitente}</b>"), :font_size => 16, :justification => :left
    	pdf.text "\n"
    	pdf.text to_utf16("\tQuien suscribe, Prof. Lucius Daniel, Director de la Escuela de Idiomas Modernos de la Facultad de Humanidades y Educación de la Universidad Central de Venezuela, hace constar por medio de la presente que #{sexo(historial.usuario.tipo_sexo_id,"la","el")} ciudadan#{sexo(historial.usuario.tipo_sexo_id,"a","o")}:"), :spacing => 1.5, :font_size => 12, :justification => :full
    	pdf.text "\n"
    	pdf.text "<b>#{to_utf16(historial.usuario.descripcion)}</b>",:spacing => 1.5,:justification => :center
			pdf.text "\n"
		pdf.text to_utf16("\tEstá inscrit#{sexo(historial.usuario.tipo_sexo_id,"a","o")} en el programa de cursos de idiomas coordinado por esta institución. Los datos sobre el curso se indican a continuación:"), :spacing => 1.5, :font_size => 12, :justification => :full
			
			pdf.text "\n\n"
		tabla = PDF::SimpleTable.new
    tabla.heading_font_size = 8
    tabla.font_size = 8
    tabla.show_lines    = :all
    tabla.line_color = Color::RGB::Gray
    tabla.show_headings = true
    tabla.shade_headings = true
    tabla.shade_heading_color = Color::RGB.new(230,238,238)
    tabla.shade_color = Color::RGB.new(230,238,238)
    tabla.shade_color2 = Color::RGB::White
    tabla.shade_rows = :striped
    tabla.orientation   = :center
    tabla.position      = :center
    tabla.column_order = ["Idioma", "Nivel","Categoria", "Horario", "Periodo"]
      
    tabla.columns["Idioma"] = PDF::SimpleTable::Column.new("Idioma") { |col|
      col.width = 70
      col.justification = :center
      col.heading = to_utf16 "<b>Idioma</b>"
      col.heading.justification= :center
    }
    tabla.columns["Nivel"] = PDF::SimpleTable::Column.new("Nivel") { |col|
      col.width = 80
      col.justification = :center
      col.heading = to_utf16("<b>Nivel</b>")
      col.heading.justification= :center
    }
     tabla.columns["Categoria"] = PDF::SimpleTable::Column.new("Categoria") { |col|
      col.width = 70
      col.justification = :center
      col.heading = to_utf16("<b>Categoría</b>")
      col.heading.justification= :center
    }
    tabla.columns["Horario"] = PDF::SimpleTable::Column.new("Horario") { |col|
      col.width = 140
      col.justification = :center
      col.heading = to_utf16("<b>Horario</b>")
      col.heading.justification= :center
    }
    tabla.columns["Periodo"] = PDF::SimpleTable::Column.new("Periodo") { |col|
      col.width = 70
      col.justification = :center
      col.heading = to_utf16("<b>Período</b>")
      col.heading.justification= :center
    }
   
    periodo, ano = periodo.split("-")
    data = []
   	data << {        
      "Idioma" => to_utf16("#{historial.tipo_curso.idioma.descripcion}"),
      "Nivel" => to_utf16("#{historial.tipo_nivel.descripcion}"),
      "Categoria" => to_utf16("#{historial.tipo_categoria.descripcion}"),
      "Horario" => to_utf16("#{historial.seccion.horario}"),
      "Periodo" => to_utf16("#{periodo} - #{ano}")
    }
  	tabla.data.replace data
	  tabla.render_on(pdf)
			
			#pdf.text to_utf16("<b>#{historial.tipo_curso.descripcion}</b>"), :spacing => 1.5, :font_size => 12, :justification => :center
			
      #pdf.text to_utf16("\n\tEn el horario de #{historial.seccion.horario} durante el período #{periodo} del año #{ano}. La nota mínima aprobatoria es #{aprobado(historial.tipo_categoria_id)} puntos."), :spacing => 1.5, :font_size => 12, :justification => :full
			t = Time.new
			pdf.text to_utf16("\n\tEsta constancia se expide en Caracas, a los #{t.day} días del mes de #{mes(t.month)} de #{t.year} con fines laborales únicamente y bajo ningún concepto indica que #{sexo(historial.usuario.tipo_sexo_id,"la","el")} Sr#{sexo(historial.usuario.tipo_sexo_id,"a","")}. #{historial.usuario.nombre_completo} es estudiante regular de la Universidad Central de Venezuela.
      "), :spacing => 1.5, :font_size => 12, :justification => :full
			
			pdf.image 'app/assets/images/firma.jpg', :justification => :center, :resize => 0.4
			pdf.text "____________________________" , :justification => :center
			pdf.text "Prof. Lucius Daniel" , :justification => :center
			pdf.text "Director" , :justification => :center
			
			pdf.add_text_wrap(160, 38, 300 , "\"CIUDAD UNIVERSITARIA DE CARACAS - PATRIMONIO CULTURAL DE LA HUMANIDAD\"", 6, :center)
			pdf.add_text_wrap(160, 30, 300 , to_utf16("Ciudad Universitaria de de Caracas, Galpón 7, Frente a Farmacia. Telf.: (0212) 6052982"), 6, :center)
			pdf.add_text_wrap(160, 22, 300 , to_utf16("Telefax: (2012) 6052908"), 6, :center)


      pdf.save_as "Constancia - #{historial.usuario.ci} - #{historial.usuario.nombre_completo}.pdf" if guardar
    end
    pdf

  end

  def self.aprobado(categoria)
    if categoria =="NI" || categoria =="TE"
      return "diéz (10)"
    else
      return "quince (15)"
    end
  end
  
  def self.sexo(valor,femenino, masculino)
    if valor
      if valor=="F"
        femenino
      else
        masculino
      end
    else
      "#{masculino}(#{femenino})"
    end
  end

	def self.pluralize(count, singular, plural)
    if count>1 
      plural
    else
      singular
    end
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

  def self.listado(historiales,session)
    usuario = session[:usuario]
    pdf = PDF::Writer.new
    pdf.margins_cm(1.8)
    #color de relleno para el pdf (color de las letras)
#    pdf.fill_color(Color::RGB.new(255,255,255))
    #imagen del encabezado
 #   pdf.add_image_from_file 'app/assets/images/banner.jpg', 50, 685, 510, 60
    
    
    pdf.add_image_from_file 'app/assets/images/logo_fhe_ucv.jpg', 465, 710, 50,nil
    pdf.add_image_from_file 'app/assets/images/logo_eim.jpg', 515, 710+10, 50,nil
    pdf.add_image_from_file 'app/assets/images/logo_ucv.jpg', 45, 710, 50,nil
 
    
    #texto del encabezado
    pdf.add_text 100,745,to_utf16("Universidad Central de Venezuela"),11
    pdf.add_text 100,735,to_utf16("Facultad de Humanidades y Educación"),11
    pdf.add_text 100,725,to_utf16("Escuela de Idiomas Modernos"),11
    pdf.add_text 100,715,to_utf16("Cursos de Extensión EIM-UCV"),11

    #texto del encabezado
#    pdf.add_text 70,722,to_utf16("Universidad Central de Venezuela"),7
#    pdf.add_text 70,714,to_utf16("Facultad de Humanidades y Educación"),7
#    pdf.add_text 70,706,to_utf16("Escuela de Idiomas Modernos"),7
#    pdf.add_text 70,698,to_utf16("Administrador de Cursos de Extensión de Idiomas Modernos"),7

    #titulo
    pdf.fill_color(Color::RGB.new(0,0,0))
    historial = historiales.first
    #periodo_calificacion
    
    pdf.add_text_wrap 50,650,510,to_utf16(
      "#{Seccion.idioma(historial.idioma_id)} (#{Seccion.tipo_categoria(historial.tipo_categoria_id)}) - #{historial.tipo_nivel.descripcion} - Sección #{historial.seccion_numero}"), 12,:center
    pdf.add_text_wrap 50,635,510,to_utf16("#{Seccion.horario(session)} - #{historial.seccion.aula_corta}"),10,:center
    pdf.add_text_wrap 50,621,510,to_utf16("Periodo #{ParametroGeneral.periodo_actual.id}"),9.5,:center

    #instructor
    pdf.add_text_wrap 50,600,510,to_utf16(usuario.nombre_completo),10
    pdf.add_text_wrap 50,585,505,to_utf16(usuario.ci),10

    pdf.add_text_wrap 50,555,510,to_utf16("<b>Listado de alumnos<b>"),10

    historiales = historiales.sort_by{|h| h.usuario.nombre_completo}
    #  historiales.each { |h|
    #    pdf.text to_utf16 "#{h.usuario.nombre_completo} - #{h.nota_final}"
    #  }
    pdf.text "\n"*18
    tabla = PDF::SimpleTable.new
    tabla.heading_font_size = 8
    tabla.font_size = 8
    tabla.show_lines    = :all
    tabla.line_color = Color::RGB::Gray
    tabla.show_headings = true
    tabla.shade_headings = true
    tabla.shade_heading_color = Color::RGB.new(230,238,238)
    tabla.shade_color = Color::RGB.new(230,238,238)
    tabla.shade_color2 = Color::RGB::White
    tabla.shade_rows = :striped
    tabla.orientation   = :center
    tabla.position      = :center
    tabla.column_order = ["#", "nombre", "cedula", "correo"]

    tabla.columns["#"] = PDF::SimpleTable::Column.new("#") { |col|
      col.width = 30
      col.heading = to_utf16("<b>#</b>")
      col.heading.justification = :center
      col.justification = :center
    }
    tabla.columns["cedula"] = PDF::SimpleTable::Column.new("cedula") { |col|
      col.width = 60
      col.heading = to_utf16("<b>Cédula</b>")
      col.heading.justification = :center
      col.justification = :center
    }
    tabla.columns["nombre"] = PDF::SimpleTable::Column.new("nombre") { |col|
      col.width = 190
      col.heading = "<b>Nombre</b>"
      col.heading.justification = :left
      col.justification = :left
    }
    tabla.columns["correo"] = PDF::SimpleTable::Column.new("correo") { |col|
      col.width = 190
      col.heading = to_utf16("<b>Correo</b>")
      col.heading.justification = :left
      col.justification = :left
    }

    data = []

    historiales.each_with_index{|h,i|
        data << {"#" => "#{i+1}",
          "cedula" => to_utf16(h.usuario.ci),
          "nombre" => to_utf16(h.usuario.nombre_completo),
          "correo" => to_utf16(h.usuario.correo)
        }
    }
    tabla.data.replace data
    tabla.render_on(pdf)
    pdf.add_text 430,50,to_utf16("#{Time.now.strftime('%d/%m/%Y %I:%M%p')} - Página: 1 de 1")
    return pdf
  end


  def self.generar_certificado_curso(ci,idioma,categoria,guardar=false)

    #historial = HistorialAcademico.all(
    #:conditions => ["usuario_ci = ?",ci])

    estudiante_curso = EstudianteCurso.where(:usuario_ci=>ci,:idioma_id=>idioma,:tipo_categoria_id=>categoria).limit(1).first

		#pdf.add_image_from_file 'public/images/logo_pi_color1.jpg', 55, 660, 490,nil

    pdf = PDF::Writer.new(:paper => "letter", :orientation => :landscape)  #:orientation => :landscape, 
    
    #ss = PDF::Writer::StrokeStyle.new(2)
		#ss.cap = :round
		#pdf.stroke_style ss

    pdf.add_image_from_file 'app/assets/images/barra_lateral.jpg', 0, 0, 70, 620  #,45, 710, 50,nil

    pdf.add_image_from_file 'app/assets/images/logo_fhe_ucv.jpg', 70, 510, 70, nil  #,45, 710, 50,nil
    pdf.add_image_from_file 'app/assets/images/logo_ucv.jpg',365, 500, 70, nil # 515, 710, 50,nil
    pdf.add_image_from_file 'app/assets/images/logo_eim.jpg', 670, 510, 70, nil#280, 710, 50,nil
    pdf.text "\n\n\n\n\n\n\n"
    #pdf.margins_mm(10)
    pdf.select_font "Times-Roman"
    pdf.text "UNIVERSIDAD CENTRAL DE VENEZUELA", :font_size => 10,:justification => :center
    pdf.text to_utf16("FACULTAD DE HUMANIDADES Y EDUCACIÓN"), :font_size => 10,:justification => :center
    pdf.text "ESCUELA DE IDIOMAS MODERNOS", :font_size => 10,:justification => :center
    
    #pdf.image "public/images/Logo FHE-UCV.jpg", :justification => :left, :width => 50
    #pdf.image "public/images/Logo FHE-UCV.jpg", :justification => :center, :width => 50, :pad => 0

    
    #pdf.add_image_from_file 'public/images/logoEIM.jpg', 5, 660, 50,nil
    	pdf.text "CERTIFICADO", :font_size => 40,:justification => :center
      pdf.select_font "Times-Italic"
    	pdf.text to_utf16("que se otorga a"), :justification => :center, :font_size => 22
    	pdf.text "\n"
    	pdf.select_font "Helvetica-Bold"
    	pdf.text "#{to_utf16(estudiante_curso.usuario.nombres)} #{to_utf16(estudiante_curso.usuario.apellidos)}",:justification => :center, :font_size => 30
			pdf.text "\n"
			pdf.select_font "Times-Italic"
			pdf.text to_utf16("por haber aprobado el curso de"), :justification => :center, :font_size => 22
			pdf.select_font "Times-BoldItalic"
      pdf.text to_utf16("#{estudiante_curso.tipo_curso.idioma.descripcion} - #{estudiante_curso.tipo_curso.tipo_categoria.descripcion}"), :justification => :center   
      pdf.text to_utf16("COMO LENGUA EXTRANJERA"), :justification => :center
      pdf.select_font "Times-Roman"
      pdf.text to_utf16("#{estudiante_curso.tipo_curso.numero_grados*54} Horas"), :justification => :center
      
			t = Time.new
			pdf.text to_utf16("Caracas, #{t.day} de #{mes(t.month)} de #{t.year}"), :spacing => 1.5, :font_size => 12, :justification => :center
			
			
			pdf.add_text_wrap(40, 110, 200 , "Prof. Lucius Daniel", 10, :center)
			pdf.add_text_wrap(40, 100, 200 , "Director", 10, :center)
			pdf.add_text_wrap(540, 110, 200 , to_utf16("Prof. Carlos A. Saavedra A."), 10, :center)
			pdf.add_text_wrap(540, 100, 200 , to_utf16("Coordinador Académico"), 10, :center)

      pdf.save_as "Certificado - #{estudiante_curso.usuario.ci} - #{estudiante_curso.usuario.nombre_completo}.pdf" if guardar
    pdf

  end

  def self.generar_listado_instructores(guardar=false)
    periodo_actual = ParametroGeneral.periodo_actual
    instructores = Instructor.all.delete_if{|i| i.seccion_periodo.size==0}.sort_by{|x| x.usuario.nombre_completo}
    pdf = PDF::Writer.new(:paper => "letter")
    
    ss = PDF::Writer::StrokeStyle.new(2)
		ss.cap = :round
		pdf.stroke_style ss

    pdf.add_image_from_file 'app/assets/images/logo_fhe_ucv.jpg', 45, 710, 50,nil
    pdf.add_image_from_file 'app/assets/images/logo_eim.jpg', 515, 710, 50,nil
    pdf.add_image_from_file 'app/assets/images/logo_ucv.jpg', 275, 710, 50,nil
    pdf.line 35,700,575,700
    if instructores.size > 0
			pdf.text "\n\n\n\n\n"
      pdf.text to_utf16("<b>Instructores Período:</b> #{periodo_actual.id}"), :justification => :center
      pdf.text "\n\n"
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
      tab.column_order = ["nro","nombre","cedula","correo","telefono","domina"]
      tab.columns["nro"] = PDF::SimpleTable::Column.new("nro") { |col|
        col.width = 25
        col.justification = :right
        col.heading = "#"
        col.heading.justification= :center
      }
      tab.columns["nombre"] = PDF::SimpleTable::Column.new("nombre") { |col|
        col.width = 140
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
        col.width = 140
        col.justification = :left
        col.heading = to_utf16 "CORREO ELECTRÓNICO"
        col.heading.justification= :center
      }
      tab.columns["telefono"] = PDF::SimpleTable::Column.new("telefono") { |col|
        col.width = 80
        col.justification = :left
        col.heading = "TELEFONO"
        col.heading.justification= :center
      }
      
      tab.columns["domina"] = PDF::SimpleTable::Column.new("domina") { |col|
        col.width = 80
        col.justification = :left
        col.heading = "IDIOMA"
        col.heading.justification= :center
      }

      data = []

      instructores.each_with_index{|reg,ind|
        
        data << {
          "nro" => "#{(ind+1)}",          
          "nombre" => to_utf16(reg.usuario.nombre_completo),
          "cedula" => reg.usuario_ci,
          "correo" => reg.usuario.correo,
          "telefono" => reg.usuario.telefono_movil,
          "domina" => to_utf16(reg.domina_descripcion)
        } if reg.usuario_ci!="-----"
      }


			t = Time.new
			pdf.start_page_numbering(250, 15, 7, nil, to_utf16("#{t.day} / #{t.month} / #{t.year}       Página: <PAGENUM> de <TOTALPAGENUM>"), 1)

      tab.data.replace data
      tab.render_on(pdf)
      pdf.save_as "instructores_periodo_#{perido_actual.id}.pdf" if guardar
    end
    pdf
  end


  def self.generar_listado_instructores_xls

    	periodo_actual = ParametroGeneral.periodo_actual
    	instructores = Instructor.all.delete_if{|i| i.seccion_periodo.size==0}.sort_by{|x| x.usuario.nombre_completo}
    	open("Instructores_periodo_#{periodo_actual.id}.xls","w") {|f|
    		f.puts "No./\t Nombre Completo /\t Cédula \t Correo Electrónico \t Teléfono Movil \t Idioma"
    		p "No.\t Nombre Completo \t Cédula \t Correo Electrónico \t Teléfono Movil \t Idioma"
  			instructores.each_with_index{|reg,ind|
  				f.puts "#{ind+1}\t#{reg.usuario.nombre_completo} \t#{reg.usuario_ci}\t#{reg.usuario.correo}\t#{reg.usuario.telefono_movil}\t#{reg.domina_descripcion}"
        }  	
    	}

  end


def self.generar_listado_convenios(convenio_id, periodo_id,guardar=false)

    historiales = HistorialAcademico.where(["tipo_convenio_id = ? AND periodo_id = ? AND tipo_estado_inscripcion_id = ? ",convenio_id,periodo_id,"INS"])

    historiales = historiales.sort_by{|x| "#{x.tipo_curso.descripcion} - #{x.tipo_nivel.descripcion} - #{x.usuario.nombre_completo}"}

    pdf = PDF::Writer.new(:paper => "letter")  #:orientation => :landscape, 
    
    ss = PDF::Writer::StrokeStyle.new(2)
		ss.cap = :round
		pdf.stroke_style ss

    pdf.add_image_from_file 'app/assets/images/logo_fhe_ucv.jpg', 45, 710, 50,nil
    pdf.add_image_from_file 'app/assets/images/logo_eim.jpg', 515, 710, 50,nil
    pdf.add_image_from_file 'app/assets/images/logo_ucv.jpg', 275, 710, 50,nil
    pdf.line 35,700,575,700
    
    if historiales.size > 0
			pdf.text "\n\n\n\n\n"
      pdf.text to_utf16("<b>Período:</b> #{historiales.last.periodo_id}"), :justification => :center  
      pdf.text to_utf16("<b>Convenio:</b> #{historiales.last.tipo_convenio.descripcion_convenio}"), :justification => :center
      pdf.text "\n\n"
      
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
      tab.column_order = ["nombre","cedula", "horario","telefono","idioma","nivel"]
      tab.columns["nivel"] = PDF::SimpleTable::Column.new("nro") { |col|
        col.width = 70
        col.heading = "Nivel"
        col.heading.justification= :center
      }
      tab.columns["nombre"] = PDF::SimpleTable::Column.new("nombre") { |col|
        col.width = 150
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
      tab.columns["horario"] = PDF::SimpleTable::Column.new("horario") { |col|
        col.width = 140
        col.justification = :left
        col.heading = "HORARIO"
        col.heading.justification= :center
      }
      tab.columns["telefono"] = PDF::SimpleTable::Column.new("telefono") { |col|
        col.width = 70
        col.justification = :left
        col.heading = "TELEFONO"
        col.heading.justification= :center
      }
      tab.columns["idioma"] = PDF::SimpleTable::Column.new("idioma") { |col|
        col.width = 80
        col.justification = :left
        col.heading = "IDIOMA"
        col.heading.justification= :center
      }

      data = []

      historiales.each_with_index{|reg,ind|
        data << {       
          "nombre" => to_utf16(reg.usuario.nombre_completo),
          "cedula" => to_utf16(reg.usuario_ci),
          "horario" => to_utf16(reg.seccion.horario),
          "telefono" => to_utf16(reg.usuario.telefono_movil),
          "idioma" => to_utf16(reg.tipo_curso.descripcion),
          "nivel" => to_utf16(reg.tipo_nivel.descripcion)   
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



def self.generar_listado_congelados(periodo_id,guardar=false)

    historiales = HistorialAcademico.where(["historial_academico.periodo_id = ? AND tipo_estado_inscripcion_id = ?",periodo_id,"CON"])

    historiales = historiales.sort_by{|x| x.usuario.nombre_completo}

    pdf = PDF::Writer.new(:paper => "letter")  #:orientation => :landscape, 
    
    ss = PDF::Writer::StrokeStyle.new(2)
		ss.cap = :round
		pdf.stroke_style ss

    pdf.add_image_from_file 'app/assets/images/logo_fhe_ucv.jpg', 45, 710, 50,nil
    pdf.add_image_from_file 'app/assets/images/logo_eim.jpg', 515, 710, 50,nil
    pdf.add_image_from_file 'app/assets/images/logo_ucv.jpg', 275, 710, 50,nil
    pdf.line 35,700,575,700
    
    if historiales.size > 0
			pdf.text "\n\n\n\n\n"
      pdf.text to_utf16("<b>Período:</b> #{historiales.last.periodo_id}"), :justification => :center  
      pdf.text to_utf16("<b>Reporte:</b> Alumnos Congelados"), :justification => :center
      pdf.text "\n\n"
           
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
      tab.column_order = ["nro","nombre","cedula", "correo","telefono","idioma","nivel"]
      tab.columns["nro"] = PDF::SimpleTable::Column.new("nro") { |col|
        col.width = 15
        col.justification = :right
        col.heading = "#"
        col.heading.justification= :center
      }
      tab.columns["nombre"] = PDF::SimpleTable::Column.new("nombre") { |col|
        col.width = 120
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
        col.width = 110
        col.justification = :left
        col.heading = "CORREO"
        col.heading.justification= :center
      }
      tab.columns["telefono"] = PDF::SimpleTable::Column.new("telefono") { |col|
        col.width = 60
        col.justification = :left
        col.heading = "TELEFONO"
        col.heading.justification= :center
      }
      tab.columns["idioma"] = PDF::SimpleTable::Column.new("idioma") { |col|
        col.width = 75
        col.justification = :left
        col.heading = "IDIOMA"
        col.heading.justification= :center
      }

      tab.columns["nivel"] = PDF::SimpleTable::Column.new("nivel") { |col|
        col.width = 85
        col.justification = :left
        col.heading = "NIVEL"
        col.heading.justification= :center
      }


      data = []

      historiales.each_with_index{|reg,ind|
        data << {
          "nro" => "#{(ind+1)}",          
          "nombre" => to_utf16(reg.usuario.nombre_completo),
          "cedula" => reg.usuario_ci,
          "correo" => reg.usuario.correo,
          "telefono" => reg.usuario.telefono_movil,
          "idioma" => reg.tipo_curso.descripcion,
          "nivel" => reg.tipo_nivel.descripcion
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
  
  
  def self.generar_listado_alumnos_por_edificio_pdf(consulta,titulo)
    pdf = PDF::Writer.new(:paper => "letter")  #:orientation => :landscape,   
    ss = PDF::Writer::StrokeStyle.new(2)
		ss.cap = :round
		pdf.stroke_style ss
    pdf.add_image_from_file 'app/assets/images/logo_fhe_ucv.jpg', 45, 710, 50,nil
    pdf.add_image_from_file 'app/assets/images/logo_eim.jpg', 515, 710, 50,nil
    pdf.add_image_from_file 'app/assets/images/logo_ucv.jpg', 275, 710, 50,nil
    pdf.text "\n\n\n\n\n"
    pdf.text to_utf16(titulo), :justification => :center, :font_size => 14
    pdf.text "\n\n"
    
    tab = PDF::SimpleTable.new
    tab.bold_headings = true
#    tab.show_lines    = :inner
    tab.show_headings = true
#    tab.shade_rows = :none
    tab.orientation   = :center
    tab.heading_font_size = 8
    tab.font_size = 8
    tab.row_gap = 3
    tab.minimum_space = 0
    tab.column_order = ["nro","nombre","cedula", "aula","idioma","nivel","categoria"]
    tab.columns["nro"] = PDF::SimpleTable::Column.new("nro") { |col|
      col.width = 30
      col.justification = :center
      col.heading = "#"
      col.heading.justification= :center
    }
    tab.columns["nombre"] = PDF::SimpleTable::Column.new("nombre") { |col|
      col.width = 120
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
    tab.columns["aula"] = PDF::SimpleTable::Column.new("aula") { |col|
      col.width = 110
      col.justification = :left
      col.heading = "AULA"
      col.heading.justification= :center
    }
    tab.columns["idioma"] = PDF::SimpleTable::Column.new("idioma") { |col|
      col.width = 60
      col.justification = :left
      col.heading = "IDIOMA"
      col.heading.justification= :center
    }
    tab.columns["nivel"] = PDF::SimpleTable::Column.new("nivel") { |col|
      col.width = 85
      col.justification = :left
      col.heading = "NIVEL"
      col.heading.justification= :center
    }
    tab.columns["categoria"] = PDF::SimpleTable::Column.new("categoria") { |col|
      col.width = 75
      col.justification = :left
      col.heading = to_utf16 "CATEGORÍA"
      col.heading.justification= :center
    }

    data = []

    consulta.each_with_index{|con,ind|
      data << {
        "nro" => "#{(ind+1)}",          
        "nombre" => to_utf16(con.nombre),
        "cedula" => to_utf16(con.cedula),
        "aula" => to_utf16(con.aula),
        "idioma" => to_utf16(con.idioma),
        "nivel" => to_utf16(con.nivel),
        "categoria" => to_utf16(con.categoria)
      }
    }
    
    tab.data.replace data
    tab.render_on pdf
    pdf
  end

  def self.nomina_instructores(instructores,periodo)
    pdf = PDF::Writer.new(:paper => "letter")  #:orientation => :landscape,   
    ss = PDF::Writer::StrokeStyle.new(2)
		ss.cap = :round
		pdf.stroke_style ss
		
    tab = PDF::SimpleTable.new
    tab.bold_headings = true
#    tab.show_lines    = :inner
    tab.show_headings = true
#    tab.shade_rows = :none
    tab.orientation   = :center
    tab.heading_font_size = 8
    tab.font_size = 8
    tab.row_gap = 3
    tab.minimum_space = 0
    tab.column_order = ["nombre","cantidad_secciones","horarios"]
    tab.columns["nombre"] = PDF::SimpleTable::Column.new("nombre") { |col|
      col.width = 120
      col.justification = :left
      col.heading = "Nombre"
      col.heading.justification= :center
    }
    tab.columns["cantidad_secciones"] = PDF::SimpleTable::Column.new("cantidad_secciones") { |col|
      col.width = 90
      col.justification = :center
      col.heading = to_utf16 "Cantidad de secciones"
      col.heading.justification= :center
    }
    tab.columns["horarios"] = PDF::SimpleTable::Column.new("horarios") { |col|
      col.width = 220
      col.justification = :left
      col.heading = "Horarios"
      col.heading.justification= :center
    }
    data = []

    instructores.each{|ins|
      data << {
        "nombre" => "#{to_utf16(ins.usuario.nombre_completo)}",          
        "cantidad_secciones" => to_utf16(ins.secciones_que_dicta(periodo).size.to_s),
        "horarios" => to_utf16(ins.horario_secciones_que_dicta(periodo).join(" // "))
      }
    }
    
    tab.data.replace data
    tab.render_on pdf
    pdf
  end

  def self.planilla_nivelacion_pagina(historial_academico,pdf)
    pdf.add_image_from_file 'app/assets/images/logo_fhe_ucv.jpg', 465, 710, 50,nil
    pdf.add_image_from_file 'app/assets/images/logo_eim.jpg', 515, 710+10, 50,nil
    pdf.add_image_from_file 'app/assets/images/logo_ucv.jpg', 45, 710, 50,nil
    pdf.add_image_from_file Rutinas.crear_codigo_barra(historial_academico.usuario_ci), 450-10, 500+35, nil, 120
    #pdf.add_text 480-10,500+35,to_utf16("---- #{historial_academico.usuario_ci} ----"),11
    
    #texto del encabezado
    pdf.add_text 100,745,to_utf16("Universidad Central de Venezuela"),11
    pdf.add_text 100,735,to_utf16("Facultad de Humanidades y Educación"),11
    pdf.add_text 100,725,to_utf16("Escuela de Idiomas Modernos"),11
    pdf.add_text 100,715,to_utf16("Cursos de Extensión EIM-UCV"),11 
    

    #titulo    
    pdf.text "\n\n\n\n\n"
    pdf.text to_utf16("Planilla de Inscripción-Nivelación (Sede Ciudad Universitaria)\n"), :font_size => 14, :justification => :center
    pdf.text to_utf16("Periodo #{historial_academico.periodo_id}"), :justification => :center

    # ------- DATOS DE LA PREINSCRIPCIO -------
    pdf.text "\n", :font_size => 10
    pdf.text to_utf16("<b>Datos de la Preinscripción:</b>"), :font_size => 12
    tabla = PDF::SimpleTable.new 
    tabla.font_size = 12
    tabla.show_lines    = :none
    tabla.show_headings = false 
    tabla.shade_rows = :none
    tabla.column_order = ["nombre", "valor"]

    tabla.columns["nombre"] = PDF::SimpleTable::Column.new("nombre") { |col|
      col.width = 100
      col.justification = :left
    }
    tabla.columns["valor"] = PDF::SimpleTable::Column.new("valor") { |col|
      col.width = 400
      col.justification = :left
    }
    datos = []
    
    datos << { "nombre" => to_utf16("<b>Estudiante:</b>"), "valor" => to_utf16("#{historial_academico.usuario.descripcion}\n#{historial_academico.usuario.datos_contacto}") }
    datos << { "nombre" => to_utf16("<b>Curso:</b>"), "valor" => to_utf16("#{historial_academico.tipo_curso.descripcion}") }
    datos << { "nombre" => to_utf16("<b>Nivel:</b>"), "valor" => to_utf16("____________________________") }
    datos << { "nombre" => to_utf16("<b>Horario:</b>"), "valor" => to_utf16("____________________________") }
    datos << { "nombre" => to_utf16("<b>Sección:</b>"), "valor" => to_utf16("____________________________") }
    datos << { "nombre" => to_utf16("<b>Aula:</b>"), "valor" => to_utf16("____________________________") }
    tabla.data.replace datos
    tabla.render_on(pdf)
    

    # -------- TABLA CUENTA -------
    pdf.text "\n", :font_size => 10
    pdf.text to_utf16("<b>Datos de Pago:</b> (Depósito en efectivo o transferencia <i>únicamente</i> del mismo banco)."), :font_size => 11

    pdf.text "\n", :font_size => 8
    tabla = PDF::SimpleTable.new 
    tabla.font_size = 12
    tabla.show_lines    = :none
    tabla.show_headings = false 
    tabla.shade_rows = :none
    tabla.column_order = ["nombre", "valor"]

    tabla.columns["nombre"] = PDF::SimpleTable::Column.new("nombre") { |col|
      col.width = 110
      col.justification = :left
    }
    tabla.columns["valor"] = PDF::SimpleTable::Column.new("valor") { |col|
      col.width = 400
      col.justification = :left
    }
    datos = []

    datos << { "nombre" => "", "valor" => to_utf16("<b>Cuenta Corriente #{historial_academico.cuenta_numero}</b> del Banco de Venezuela") }
    datos << { "nombre" => to_utf16("<b>A nombre de:</b>"), "valor" => to_utf16("#{historial_academico.cuenta_nombre}") }

    monto = historial_academico.cuenta_monto
    # monto_soberano = (monto.is_a? Float) ? "(#{monto.to_i/1000} Bs. S)" : "" 

    datos << { "nombre" => to_utf16("<b>Monto:</b>"), "valor" => to_utf16("#{monto}")}

    datos << { "nombre" => to_utf16("<b>Transacción #:</b>"), "valor" => to_utf16("_________________________ Tipo: T ___  D ___ P ___") }
    tabla.data.replace datos  
    tabla.render_on(pdf)
    pdf.text "\n", :font_size => 10
    
    # ---- NORMAS -----
    pdf.text to_utf16("<b>LEA CUIDADOSAMENTE LA SIGUIENTE INFORMACIÓN Y NORMATIVA DEL PROGRAMA</b>"), :font_size => 12
    pdf.text "\n", :font_size => 10
    pdf.text to_utf16("<C:bullet/>La inscripción es válida UNICAMENTE para el período indicado en esta planilla. NO SE CONGELAN CUPOS POR NINGÚN MOTIVO."), :font_size => 11, :justification => :full
    pdf.text to_utf16("<C:bullet/>SOLO SE REINTEGRARÁ EL MONTO DE LA MATRÍCULA EN CASO DE QUE NO SE REUNA EL QUORUM NECESARIO PARA LA APERTURA DEL CURSO."), :font_size => 11, :justification => :full
    pdf.text to_utf16("<C:bullet/>La asistencia a clases es obligatoria: Cursos <b>LUN-MIE</b>: Límite de 3 inasistencias. Cursos <b>MAR-JUE</b>: Límite de 3 inasistencias. Cursos <b>SÁBADOS</b>: Límite de 2 inasistencias."), :font_size => 11, :justification => :full
    pdf.text to_utf16("<C:bullet/>La nota mínima aprobatoria es de 15 puntos. El cupo mínimo es de 15 participantes."), :font_size => 11, :justification => :full
    pdf.text to_utf16("<C:bullet/>NO SE PERMITEN CAMBIOS DE SECCIÓN."), :font_size => 11, :justification => :full
    pdf.text to_utf16("<C:bullet/>El horario, sección y aula se reserva hasta la fecha indicada."), :font_size => 11, :justification => :full
    pdf.text to_utf16("<C:bullet/>Únicamente DEPOSITOS en EFECTIVO (NO CHEQUES)."), :font_size => 11, :justification => :full
    
    # -- FIRMAS -----
    pdf.text "\n", :font_size => 8
    pdf.text "\n", :font_size => 8
    pdf.text "\n", :font_size => 8
    pdf.text "\n", :font_size => 8
    tabla = PDF::SimpleTable.new 
    tabla.font_size = 12 
    tabla.orientation   = :center
    tabla.position      = :center
    tabla.show_lines    = :none
    tabla.show_headings = false 
    tabla.shade_rows = :none
    tabla.column_order = ["nombre", "valor"]

    tabla.columns["nombre"] = PDF::SimpleTable::Column.new("nombre") { |col|
      col.width = 250
      col.justification = :center
    }
    tabla.columns["valor"] = PDF::SimpleTable::Column.new("valor") { |col|
      col.width = 250
      col.justification = :center
    }
    datos = []
    datos << { "nombre" => to_utf16("<b>__________________________</b>"), "valor" => to_utf16("<b>__________________________</b>") }
    datos << { "nombre" => to_utf16("Firma Estudiante"), "valor" => to_utf16("Firma Autorizada y Sello") }
    tabla.data.replace datos  
    tabla.render_on(pdf)
    pdf.text "\n", :font_size => 8
    pdf.text "\n", :font_size => 8
  end

  def self.planilla_nivelacion(historial_academico=nil)
    pdf = PDF::Writer.new(:paper => "letter")  #:orientation => :landscape, 
    t = Time.now

    planilla_nivelacion_pagina(historial_academico,pdf)
    pdf.text to_utf16("----- COPIA DEL ESTUDIANTE -----"), :font_size => 12, :justification => :center
    pdf.text "\n", :font_size => 8
    pdf.text to_utf16("#{t.strftime('%d/%m/%Y %I:%M%p')} - Página: 1 de 2"), :font_size => 10, :justification => :right
    
    pdf.new_page
    pdf.y = 756
    planilla_nivelacion_pagina(historial_academico,pdf)
    pdf.text to_utf16("----- COPIA ADMINISTRACIÓN -----"), :font_size => 12, :justification => :center
    pdf.text "\n", :font_size => 8
    pdf.text to_utf16("#{t.strftime('%d/%m/%Y %I:%M%p')} - Página: 2 de 2"), :font_size => 10, :justification => :right
   
    return pdf
  end
  
  
  
  def self.generar_carnets_instructores(consulta,periodo)
    pdf = PDF::Writer.new(:paper => "letter")  #:orientation => :landscape,   
    ss = PDF::Writer::StrokeStyle.new(2)
		ss.cap = :round
		pdf.stroke_style ss
		
		#coordenadas para las columnas y las filas
		c = { "x_columna_0" => 50,"x_columna_1" => 310,"y_fila_0" => 710,"y_fila_1" => 550, "y_fila_2" => 390,"y_fila_3" => 230,
          "x_columna_0_base" => 55,"x_columna_1_base" => 315, "y_fila_0_base" => 690, "y_fila_1_base" => 530, "y_fila_2_base" => 370,
          "y_fila_3_base" => 210
		  }
		  
     consulta.each_with_index{|ins,i|
      fil = ((i%8)/2).to_i
      col = i%2
      pdf.rounded_rectangle(c["x_columna_#{col}"],c["y_fila_#{fil}"], 250, 150, 5).stroke 
      xb = c["x_columna_#{col}_base"]
      yb = c["y_fila_#{fil}_base"]
      letra, ano = periodo.split("-")
      
      rango = "Enero - Marzo" if letra == "A"
      rango = "Abril - Junio" if letra == "B"
      rango = "Julio - Septiembre" if letra == "C"
      rango = "Octubre - Diciembre" if letra == "D"
      rango << " #{ano}"

      #primero la firma para poder superponer texto sobre ella (como si fuera transparente)
      pdf.add_image_from_file 'app/assets/images/firma.jpg', (xb+100), (yb-110), 130,35
      pdf.add_text_wrap xb,yb,300,to_utf16("Escuela de Idiomas Modernos")
   		pdf.add_text_wrap xb,(yb-10),300,to_utf16("Coordinación de los Cursos de Extensión")	
   		pdf.add_text_wrap xb,(yb-20),300,to_utf16("Informa que:")
   		pdf.add_text_wrap xb,(yb-30),300,to_utf16("<b>#{ins.usuario.nombre_completo}</b>")
   		pdf.add_text_wrap xb,(yb-40),300,to_utf16("<b>CI: #{ins.usuario_ci}</b>")
   		pdf.add_text_wrap xb,(yb-60),300,to_utf16("Es instructor de los cursos de idiomas durante el")
   		pdf.add_text_wrap xb,(yb-70),300,to_utf16("periodo #{periodo} <b>(#{rango})</b>")
   		pdf.add_text_wrap xb+85,yb-110,300,to_utf16("<b>___________________________</b>")
   		pdf.add_text_wrap xb+105,yb-120,300,to_utf16("Firma y sello autorizado")
      if ((i%8==7))
        pdf.new_page
      end
     }
    pdf
  end

  def self.generar_listado_nivelacion_confirmados(periodo_id, idioma_id = nil)
    if idioma_id
      historial = EstudianteNivelacion.where(:periodo_id=>periodo_id, :confirmado => 1, :idioma_id => idioma_id)
    else
      historial = EstudianteNivelacion.where(:periodo_id=>periodo_id, :confirmado => 1)
    end 
    historial = historial.sort_by{|x| x.usuario.nombre_completo}
    pdf = PDF::Writer.new(:paper => "letter")  #:orientation => :landscape, 
    
    ss = PDF::Writer::StrokeStyle.new(2)
    ss.cap = :round
    pdf.stroke_style ss

    pdf.add_image_from_file 'app/assets/images/logo_fhe_ucv.jpg', 45, 710, 50,nil
    pdf.add_image_from_file 'app/assets/images/logo_eim.jpg', 515, 710, 50,nil
    pdf.add_image_from_file 'app/assets/images/logo_ucv.jpg', 275, 710, 50,nil
    pdf.line 35,700,575,700
    
    if historial.size > 0
      
      pdf.text "\n\n\n\n\n"
      pdf.text to_utf16("<b>Estudiantes con Nivelación (Confirmados) - Período:</b> #{periodo_id}"), :justification => :center
      pdf.text "\n\n"
      
      
      
      
      
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
      tab.column_order = ["nro","idioma","nombre","cedula", "correo","telefono"]
      tab.columns["nro"] = PDF::SimpleTable::Column.new("nro") { |col|
        col.width = 25
        col.justification = :right
        col.heading = "#"
        col.heading.justification= :center
      }
      tab.columns["idioma"] = PDF::SimpleTable::Column.new("idioma") { |col|
        col.width = 100
        col.justification = :left
        col.heading = "IDIOMA"
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
          "idioma" => to_utf16(reg.tipo_curso.idioma.descripcion),
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

      
    end
    pdf
  end

end




