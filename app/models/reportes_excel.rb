# encoding: utf-8

class ReportesExcel

  def self.listado(convenio_id, periodo,guardar=false)
    Spreadsheet.client_encoding = 'UTF-8'
    #     ruta = File.join(Rails.root,"prueba.xls").to_s
    libro = Spreadsheet::Workbook.new
    formato_libro = Spreadsheet::Format.new :size => 12
    libro.default_format = formato_libro
    #     libro = Spreadsheet.open '/path/to/an/excel-file.xls'

    hoja = libro.create_worksheet :name => 'convenios'

    historiales = HistorialAcademico.where(["tipo_convenio_id = ? AND periodo_id = ? AND tipo_estado_inscripcion_id = ? ",convenio_id,periodo,"INS"])
    historiales = historiales.sort_by{|x| "#{x.tipo_curso.descripcion} - #{x.tipo_nivel.descripcion} - #{x.usuario.nombre_completo}"}


    hoja.row(0).insert 0, "Universidad Central de Venezuela"
    hoja.row(1).insert 0, "Facultad de Humanidades y Educación"
    hoja.row(2).insert 0, "Escuela de Idiomas Modernos - FUNDEIM"
    hoja.row(3).insert 0, "Período: #{periodo}"
    hoja.row(4).insert 0, "Convenio: #{historiales.last.tipo_convenio.descripcion_convenio}"

    formato = Spreadsheet::Format.new :weight => :bold,:size => 12, :align => :center, :border => true
    formato2 = Spreadsheet::Format.new :border => true
    if historiales.size > 0
      hoja.row(7).insert 0,"Nombre","Cédula", "Horario","Teléfono","Idioma","Nivel"
      (0..5).each{|ind|
        hoja.row(7).set_format(ind,formato)
      }
      historiales.each_with_index{|reg,ind|
        hoja.row(8 + ind).insert 0, (reg.usuario.nombre_completo), (reg.usuario_ci), (reg.seccion.horario),
        (reg.usuario.telefono_movil) ,(reg.tipo_curso.descripcion), (reg.tipo_nivel.descripcion)
        (0..5).each{|i|
          hoja.row(8+ind).set_format(i,formato2)
        }
      }
    end

    ruta = File.join(Rails.root,"prueba.xls").to_s
    libro.write(ruta)
    return ruta

  end

  def self.generar_listado_alumnos_por_edificio_excel(consulta,titulo)
    Spreadsheet.client_encoding = 'UTF-8'
    #     ruta = File.join(Rails.root,"prueba.xls").to_s
    libro = Spreadsheet::Workbook.new
    formato_libro = Spreadsheet::Format.new :size => 12
    libro.default_format = formato_libro
    #     libro = Spreadsheet.open '/path/to/an/excel-file.xls'

    hoja = libro.create_worksheet :name => 'alumnos_por_edif'
    hoja.row(0).insert 0, "Universidad Central de Venezuela"
    hoja.row(1).insert 0, "Facultad de Humanidades y Educación"
    hoja.row(2).insert 0, "Escuela de Idiomas Modernos - FUNDEIM"
    hoja.row(3).insert 0, titulo

    formato = Spreadsheet::Format.new :weight => :bold,:size => 12, :align => :center, :border => true
    formato2 = Spreadsheet::Format.new :border => true

    hoja.row(7).insert 0,"Nombre","Cédula", "Aula","Idioma","Nivel", "Categoría"
    (0..5).each{|ind|
      hoja.row(7).set_format(ind,formato)
    }
    consulta.each_with_index{|con,ind|
      hoja.row(8 + ind).insert 0, (con.nombre), (con.cedula), (con.aula),
      (con.idioma) ,(con.nivel), (con.categoria)
      (0..5).each{|i|
        hoja.row(8+ind).set_format(i,formato2)
      }
    }
    ruta = File.join(Rails.root,"listado_alumnos_por_edificio.xls").to_s
    libro.write(ruta)
    return ruta
  end


  def self.nomina_instructores(instructores,periodo)
    Spreadsheet.client_encoding = 'UTF-8'
    #     ruta = File.join(Rails.root,"prueba.xls").to_s
    libro = Spreadsheet::Workbook.new
    formato_libro = Spreadsheet::Format.new :size => 12
    libro.default_format = formato_libro
    #     libro = Spreadsheet.open '/path/to/an/excel-file.xls'

    hoja = libro.create_worksheet :name => 'nomina'
    hoja.row(0).insert 0, "Universidad Central de Venezuela"
    hoja.row(1).insert 0, "Facultad de Humanidades y Educación"
    hoja.row(2).insert 0, "Escuela de Idiomas Modernos - FUNDEIM"
    hoja.row(3).insert 0, "Nómina de instructores (#{periodo})"

    formato = Spreadsheet::Format.new :weight => :bold,:size => 12, :align => :center, :border => true
    formato2 = Spreadsheet::Format.new :border => true

    hoja.row(7).insert 0,"Nombre","Cantidad de secciones", "Horarios"
    (0..2).each{|ind|
      hoja.row(7).set_format(ind,formato)
    }
    instructores.each_with_index{|ins,ind|
      hoja.row(8 + ind).insert 0, (ins.usuario.nombre_completo), (ins.secciones_que_dicta(periodo).size.to_s), (ins.horario_secciones_que_dicta(periodo).join(" // "))
      (0..2).each{|i|
        hoja.row(8+ind).set_format(i,formato2)
      }
    }
    ruta = File.join(Rails.root,"listado_alumnos_por_edificio.xls").to_s
    libro.write(ruta)
    return ruta
  end


  def self.estadisticas_generales(idioma_id, categoria_id,periodo_id,guardar=false)
    Spreadsheet.client_encoding = 'UTF-8'
    #     ruta = File.join(Rails.root,"prueba.xls").to_s
    libro = Spreadsheet::Workbook.new
    formato_libro = Spreadsheet::Format.new :size => 12
    libro.default_format = formato_libro
    #     libro = Spreadsheet.open '/path/to/an/excel-file.xls'

    hoja = libro.create_worksheet :name => 'estadisticas_generales'

    historiales = HistorialAcademico.find_by_sql(["
      select t1.periodo_id, t1.idioma_id, t1.cat1, t.grado, t.tipo_nivel_id, tip.descripcion as descnivel, t1.seccion_numero, t.id as bloque_horario_id, t.idioma, t.tipo_categoria_id, t.id, t.descripcion as desc_hor, IF(t1.total is null, 0, t1.total) as total, IF(t1.aprobados is null, 0, t1.aprobados) as aprobados, IF(t1.reprobados is null, 0, t1.reprobados) as reprobados, IF(t1.pi is null, 0, t1.pi) as pi, IF(t1.sc is null, 0, t1.sc) as sc
      from
      (select c.idioma_id idioma, c.tipo_categoria_id, c.tipo_nivel_id, c.grado, bh.id, bh.descripcion from curso c JOIN bloque_horario bh WHERE c.idioma_id = ? AND c.tipo_categoria_id = ? AND c.grado != 0) t
      LEFT JOIN
      (
      select s.periodo_id, s.idioma_id, s.seccion_numero, s.bloque_horario_id, his.idioma_id idi, his.tipo_categoria_id cat1, his.tipo_nivel_id nivel, s.bloque_horario_id as horario, count(*) AS total, SUM(IF(his.tipo_estado_calificacion_id = 'AP', 1, 0)) AS aprobados, SUM(IF(his.tipo_estado_calificacion_id = 'RE', 1, 0)) AS reprobados, SUM(IF(his.tipo_estado_calificacion_id = 'PI', 1, 0 )) AS pi, SUM(IF(his.tipo_estado_calificacion_id = 'SC', 1, 0)) AS sc
      from historial_academico his
      INNER JOIN seccion s ON his.idioma_id = s.idioma_id AND his.tipo_categoria_id = s.tipo_categoria_id AND his.tipo_nivel_id = s.tipo_nivel_id
      AND his.periodo_id = s.periodo_id AND his.seccion_numero = s.seccion_numero AND s.esta_abierta = 1
      where his.idioma_id = ? and his.tipo_categoria_id = ?
      and his.tipo_estado_inscripcion_id = 'INS' AND his.periodo_id = ?
      GROUP BY his.tipo_nivel_id, s.bloque_horario_id
      ) t1
      ON t.idioma = t1.idi and t.tipo_categoria_id = t1.cat1 and t.tipo_nivel_id = t1.nivel AND t.id = t1.horario
      INNER JOIN tipo_nivel tip ON tip.id = t.tipo_nivel_id
    ORDER BY t.grado, t.id", idioma_id, categoria_id, idioma_id, categoria_id, periodo_id])

    idioma_desc = Idioma.find(idioma_id).descripcion
    categoria_desc = TipoCategoria.find(categoria_id).descripcion

    hoja.row(0).insert 0, "Universidad Central de Venezuela"
    hoja.row(1).insert 0, "Facultad de Humanidades y Educación"
    hoja.row(2).insert 0, "Escuela de Idiomas Modernos - FUNDEIM"
    hoja.row(3).insert 0, "Período: #{periodo_id}"
    hoja.row(4).insert 0, "Estadísticas Generales para: " + idioma_desc + " (" + categoria_desc + ")"

    formato = Spreadsheet::Format.new :weight => :bold,:size => 12, :align => :center, :border => true
    formato2 = Spreadsheet::Format.new :border => true

    hoja.row(7).insert 0,"Nivel","Horario", "Total Inscritos","Aprobados","Reprobados","Pérdida por Inasistencia","Sin Calificar","Alumnos Estimados / Recomendación"
    (0..7).each{|ind|
      hoja.row(7).set_format(ind,formato)
    }
    historiales.each_with_index{|h,ind|

      if h.tipo_nivel_id != "BI" && h.tipo_nivel_id != "BE"
        horario = h.bloque_horario_id
        nivel = h.nivel_anterior(idioma_id, h.tipo_categoria_id, h.grado)
        aprobados = h.aprobados_nivel_anterior(horario, nivel, idioma_id, periodo_id, h.tipo_categoria_id).to_i
        reprobados = h.reprobados.to_i
        cantidad_estudiantes_estimados = reprobados + aprobados

        if idioma_id == "IN"
          divisor = 18
          resto = 0.43
        else
          divisor = 12
          resto = 0.6
        end
        recomendacion_parte_entera = (cantidad_estudiantes_estimados / divisor).to_i
        recomendacion_parte_decimal = (cantidad_estudiantes_estimados / divisor.to_f) - recomendacion_parte_entera.to_f
        if recomendacion_parte_entera >= 1

          if recomendacion_parte_decimal < resto
            if recomendacion_parte_entera == 1
              recomendacion = recomendacion_parte_entera.to_s+" Sección"
            else
              recomendacion = recomendacion_parte_entera.to_s+" Secciones"
            end
          else
            recomendacion_parte_entera2 = recomendacion_parte_entera + 1
            recomendacion = "Entre "+recomendacion_parte_entera.to_s+" y "+recomendacion_parte_entera2.to_s+" Secciones"
          end
        else
          if recomendacion_parte_decimal > resto
            recomendacion = "1 Sección"
          else
            recomendacion = "0 Secciones"
          end
        end
        estimacion_recomendacion = cantidad_estudiantes_estimados.to_i.to_s+" ("+aprobados.to_s+" ap niv ant + "+reprobados.to_s+" rep niv act)" + "  /  " + recomendacion
      else
        estimacion_recomendacion = "---"
      end

      hoja.row(8 + ind).insert 0, (h.descnivel), (h.desc_hor), (h.total.to_i),
      (h.aprobados.to_i) ,(h.reprobados.to_i), (h.pi.to_i), (h.sc.to_i),(estimacion_recomendacion)
      (0..7).each{|i|
        hoja.row(8+ind).set_format(i,formato2)
      }
    }

    ruta = File.join(Rails.root,"estadisticas_generales.xls").to_s
    libro.write(ruta)
    return ruta

  end





  def self.distribucion_depositos(cuenta_id,periodo_id,guardar=false)
    Spreadsheet.client_encoding = 'UTF-8'
    libro = Spreadsheet::Workbook.new
    formato_libro = Spreadsheet::Format.new :size => 12
    libro.default_format = formato_libro

    hoja = libro.create_worksheet :name => 'distribucion_depositos'


    historiales = HistorialAcademico.select("historial_academico.tipo_convenio_id, count(*) as cantidad, historial_academico.cuenta_bancaria_id").where(["periodo_id = ? AND tipo_estado_inscripcion_id = ? AND cuenta_bancaria_id = ?",periodo_id,"INS",cuenta_id]).group("tipo_convenio_id")

    hoja.row(0).insert 0, "Universidad Central de Venezuela"
    hoja.row(1).insert 0, "Facultad de Humanidades y Educación"
    hoja.row(2).insert 0, "Escuela de Idiomas Modernos - FUNDEIM"
    hoja.row(3).insert 0, "Período: #{periodo_id}"
    hoja.row(4).insert 0, "Detalle de Depósitos Bancarios en la cuenta de: #{historiales.first.cuenta_nombre}"

    formato = Spreadsheet::Format.new :weight => :bold,:size => 12, :align => :center, :border => true
    formato2 = Spreadsheet::Format.new :border => true

    hoja.row(7).insert 0,"Tipo de Ingreso","Cantidad de depositantes"
    (0..1).each{|ind|
      hoja.row(7).set_format(ind,formato)
    }
    historiales.each_with_index{|h,ind|


      hoja.row(8 + ind).insert 0, (h.tipo_convenio.descripcion), (h.cantidad)
      (0..1).each{|i|
        hoja.row(8+ind).set_format(i,formato2)
      }
    }

    ruta = File.join(Rails.root,"distribucion_depositos.xls").to_s
    libro.write(ruta)
    return ruta

  end

  def self.generar_listado_nivelacion_confirmados(periodo_id, idioma_id = nil)

    Spreadsheet.client_encoding = 'UTF-8'
    libro = Spreadsheet::Workbook.new
    formato_libro = Spreadsheet::Format.new :size => 12
    libro.default_format = formato_libro

    hoja = libro.create_worksheet :name => 'confirmados_nivelacion'

    if idioma_id
      historial = EstudianteNivelacion.where(:periodo_id=>periodo_id, :confirmado => 1, :idioma_id => idioma_id)
    else
      historial = EstudianteNivelacion.where(:periodo_id=>periodo_id, :confirmado => 1)
    end
    historial = historial.sort_by{|x| x.usuario.nombre_completo}


    hoja.row(0).insert 0, "Universidad Central de Venezuela"
    hoja.row(1).insert 0, "Facultad de Humanidades y Educación"
    hoja.row(2).insert 0, "Escuela de Idiomas Modernos - FUNDEIM"
    hoja.row(3).insert 0, "Período: #{periodo_id}"
    hoja.row(4).insert 0, "Esduiantes en nivelacion confirmados periodo: #{periodo_id}"

    formato = Spreadsheet::Format.new :weight => :bold,:size => 12, :align => :center, :border => true
    formato2 = Spreadsheet::Format.new :border => true

    hoja.row(7).insert 0,"NRO","IDIOMA","NOMBRE COMPLETO", "CEDULA", "CORREO", "TELEDONO"
    (0..5).each{|ind|
      hoja.row(7).set_format(ind,formato)
    }
    historial.each_with_index{|h,ind|


      hoja.row(8 + ind).insert 0, (ind+1), h.tipo_curso.idioma.descripcion, h.usuario.nombre_completo, h.usuario_ci, h.usuario.correo, h.usuario.telefono_movil

      (0..5).each{|i|
        hoja.row(8+ind).set_format(i,formato2)
      }
    }

    ruta = File.join(Rails.root,"confirmados_nivelacion.xls").to_s
    libro.write(ruta)
    return ruta


  end








end
