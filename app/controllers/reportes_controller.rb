# encoding: utf-8

class ReportesController < ApplicationController
  before_action :filtro_logueado
  before_action :filtro_administrador 
  def index_reportes_convenios
  	
		@titulo_pagina = "Reportes de Alumnos por Convenios" 
		@convenios = TipoConvenio.where(["id != ?", "REG"])

		@cantidades = []

		@convenios.each{|c|
			@cantidades << HistorialAcademico.where(["tipo_convenio_id = ? AND periodo_id = ? AND tipo_estado_inscripcion_id = ?",c.id,session[:parametros][:periodo_actual],"INS"]).count
		}

  end

  def reportes_convenios_detalle

  	id_convenio = params[:id] 
		@titulo_pagina = "Detalle de Alumnos por Convenio" 
		@subtitulo_pagina = TipoConvenio.where(["id = ?", id_convenio]).first.descripcion

    @historiales = HistorialAcademico.where(["tipo_convenio_id = ? AND periodo_id = ? AND tipo_estado_inscripcion_id = ? ",id_convenio,session[:parametros][:periodo_actual],"INS"])
    if  @historiales.size == 0
      flash[:mensaje] = "No hay información en el periodo para el convenio seleccionado"
      redirect_to :action => "index_reportes_convenios"
      return
    end         
    @historiales = @historiales.sort_by{|x| "#{x.tipo_curso.descripcion} - #{x.tipo_nivel.descripcion} - #{x.usuario.nombre_completo}"}		
  end

  def ver_pdf_convenio
    convenio_id = params[:tipo_convenio] 
    periodo_id = session[:parametros][:periodo_actual]
    descripcion_convenio = TipoConvenio.where(["id = ?", convenio_id]).first.descripcion
    if pdf = DocumentosPDF.generar_listado_convenios(convenio_id,periodo_id,false)
      send_data pdf.render,:filename => "Estudiantes_con_Convenios_#{descripcion_convenio}_#{periodo_id}.pdf",:type => "application/pdf", :disposition => "attachment"
    end
  end
  
  def ver_excel_convenio
    convenio_id = params[:tipo_convenio] 
    periodo_id = session[:parametros][:periodo_actual]
    descripcion_convenio = TipoConvenio.where(["id = ?", convenio_id]).first.descripcion
    ruta_excel = ReportesExcel.listado(convenio_id,periodo_id,false)
    send_file ruta_excel,
      :filename => "listado.xls",
      :type => "application/excel", :disposition => "attachment"
    
  end

  def index_reporte_alumnos_por_idioma
  	
		@titulo_pagina = "Reporte de Cantidad de Alumnos por Idioma" 

		@historiales = HistorialAcademico.select("historial_academico.idioma_id, historial_academico.tipo_categoria_id, count(*) as cantidad").joins("INNER JOIN seccion ON historial_academico.periodo_id = seccion.periodo_id and historial_academico.idioma_id = seccion.idioma_id and historial_academico.tipo_categoria_id = seccion.tipo_categoria_id and historial_academico.tipo_nivel_id = seccion.tipo_nivel_id and historial_academico.seccion_numero = seccion.seccion_numero").where(["historial_academico.periodo_id = ? AND tipo_estado_inscripcion_id = ? and seccion.esta_abierta = ?",session[:parametros][:periodo_actual],"INS",1]).group("historial_academico.idioma_id, historial_academico.tipo_categoria_id")

		if  @historiales.empty?
      flash[:mensaje] = "No hay información en el periodo para el reporte seleccionado"
      redirect_to :controller => "principal_admin", :action => "index"
      return
    end         

  end


  def reporte_alumnos_por_idioma_detalle1
  	
		idioma_id = params[:idioma]
		
		idioma = Idioma.find(idioma_id).descripcion
 
		categoria_id = params[:categoria]

		categoria = TipoCategoria.find(categoria_id).descripcion

		@titulo_pagina = "Cantidad de Alumnos por Nivel en " + idioma + " (" + categoria + ")"

		@historiales = HistorialAcademico.select("historial_academico.idioma_id, historial_academico.tipo_categoria_id, curso.tipo_nivel_id, count(*) as cantidad").joins("INNER JOIN seccion ON historial_academico.periodo_id = seccion.periodo_id and historial_academico.idioma_id = seccion.idioma_id and historial_academico.tipo_categoria_id = seccion.tipo_categoria_id and historial_academico.tipo_nivel_id = seccion.tipo_nivel_id and historial_academico.seccion_numero = seccion.seccion_numero INNER JOIN curso ON historial_academico.idioma_id = curso.idioma_id and historial_academico.tipo_categoria_id = curso.tipo_categoria_id and historial_academico.tipo_nivel_id = curso.tipo_nivel_id").where(["historial_academico.idioma_id = ? AND historial_academico.tipo_categoria_id = ? AND historial_academico.periodo_id = ? AND historial_academico.tipo_estado_inscripcion_id = ? AND seccion.esta_abierta = ?",idioma_id,categoria_id,session[:parametros][:periodo_actual],"INS",1]).group("historial_academico.tipo_nivel_id").order("curso.grado")			

		if  @historiales.empty?
      flash[:mensaje] = "No hay información en el periodo para el reporte seleccionado"
      redirect_to :controller => "principal_admin", :action => "index"
      return
    end         

  end


  def reporte_alumnos_por_idioma_detalle2
  	
		idioma_id = params[:idioma]
		
		idioma = Idioma.find(idioma_id).descripcion
 
		categoria_id = params[:categoria]

		categoria = TipoCategoria.find(categoria_id).descripcion

		nivel_id = params[:nivel]

		nivel = TipoNivel.find(nivel_id).descripcion

		@titulo_pagina = "Cantidad de Alumnos por Horario en " + idioma + " (" + categoria + ") - " + nivel

		@historiales = HistorialAcademico.select("historial_academico.idioma_id, historial_academico.tipo_categoria_id, seccion.*, curso.tipo_nivel_id, count(*) as cantidad").joins("INNER JOIN seccion ON historial_academico.periodo_id = seccion.periodo_id and historial_academico.idioma_id = seccion.idioma_id and historial_academico.tipo_categoria_id = seccion.tipo_categoria_id and historial_academico.tipo_nivel_id = seccion.tipo_nivel_id and historial_academico.seccion_numero = seccion.seccion_numero INNER JOIN curso ON historial_academico.idioma_id = curso.idioma_id and historial_academico.tipo_categoria_id = curso.tipo_categoria_id and historial_academico.tipo_nivel_id = curso.tipo_nivel_id").where(["historial_academico.idioma_id = ? AND historial_academico.tipo_categoria_id = ? AND historial_academico.tipo_nivel_id = ? AND historial_academico.periodo_id = ? AND historial_academico.tipo_estado_inscripcion_id = ? AND seccion.esta_abierta = ?",idioma_id,categoria_id,nivel_id,session[:parametros][:periodo_actual],"INS",1]).group("historial_academico.tipo_nivel_id, seccion.bloque_horario_id").order("curso.grado")		
		
		if  @historiales.empty?
      flash[:mensaje] = "No hay información en el periodo para el reporte seleccionado"
      redirect_to :controller => "principal_admin", :action => "index"
      return
    end         

  end



	def index_reporte_secciones_por_idioma

		@titulo_pagina = "Reporte de Cantidad de Secciones por Idioma" 

		@secciones = Seccion.select("idioma_id, tipo_categoria_id, count(*) as cantidad").where(["periodo_id = ? and esta_abierta = ?",session[:parametros][:periodo_actual],1]).group("idioma_id, tipo_categoria_id")

		if  @secciones.empty?
      flash[:mensaje] = "No hay información en el periodo para el reporte seleccionado"
      redirect_to :controller => "principal_admin", :action => "index"
      return
    end   

	end



	def reporte_secciones_por_idioma_detalle1

		idioma_id = params[:idioma]
		
		idioma = Idioma.find(idioma_id).descripcion
 
		categoria_id = params[:categoria]

		categoria = TipoCategoria.find(categoria_id).descripcion

		@titulo_pagina = "Cantidad de Secciones por Nivel en " + idioma + " (" + categoria + ")"

		@secciones = Seccion.select("seccion.idioma_id, seccion.tipo_categoria_id, curso.tipo_nivel_id, count(*) as cantidad").joins("INNER JOIN curso ON seccion.idioma_id = curso.idioma_id and seccion.tipo_categoria_id = curso.tipo_categoria_id and seccion.tipo_nivel_id = curso.tipo_nivel_id").where(["seccion.idioma_id = ? AND seccion.tipo_categoria_id = ? AND seccion.periodo_id = ? AND seccion.esta_abierta = ?",idioma_id,categoria_id,session[:parametros][:periodo_actual],1]).group("seccion.tipo_nivel_id").order("curso.grado")
	
		if  @secciones.empty?
      flash[:mensaje] = "No hay información en el periodo para el reporte seleccionado"
      redirect_to :controller => "principal_admin", :action => "index"
      return
    end        

	end


  def reporte_secciones_por_idioma_detalle2
  	
		idioma_id = params[:idioma]
		
		idioma = Idioma.find(idioma_id).descripcion
 
		categoria_id = params[:categoria]

		categoria = TipoCategoria.find(categoria_id).descripcion

		nivel_id = params[:nivel]

		nivel = TipoNivel.find(nivel_id).descripcion

		@titulo_pagina = "Cantidad de Secciones por Horario en " + idioma + " (" + categoria + ") - " + nivel
	
		@secciones = Seccion.select("seccion.idioma_id, seccion.tipo_categoria_id, seccion.bloque_horario_id, curso.tipo_nivel_id, count(*) as cantidad").joins("INNER JOIN curso ON seccion.idioma_id = curso.idioma_id and seccion.tipo_categoria_id = curso.tipo_categoria_id and seccion.tipo_nivel_id = curso.tipo_nivel_id").where(["seccion.idioma_id = ? AND seccion.tipo_categoria_id = ? AND seccion.tipo_nivel_id = ? AND seccion.periodo_id = ? AND seccion.esta_abierta = ?",idioma_id,categoria_id,nivel_id,session[:parametros][:periodo_actual],1]).group("seccion.tipo_nivel_id, seccion.bloque_horario_id").order("curso.grado")

		
		if  @secciones.empty?
      flash[:mensaje] = "No hay información en el periodo para el reporte seleccionado"
      redirect_to :controller => "principal_admin", :action => "index"
      return
    end         

  end


  def elegir_idioma_reporte_modal

		@idiomas = Idioma.select("idioma.*,tipo_curso.*").joins(:tipo_curso).where(["id != ? and tipo_curso.tipo_categoria_id != ?", "OR","BBVA"])

		@idiomas.each{|i|
			
			if(i.id=="IN")		
				tipo_categoria = TipoCategoria.where(["id = ?", i.tipo_categoria_id]).limit(1).first	
				i.descripcion = i.descripcion + " - " + tipo_categoria.descripcion
			end

			i.id = i.id + "-" +i.tipo_categoria_id
		
		}
		
    render :layout => false

  end

  def index_reporte_aulas_por_ubicacion


    #Se toman todos los horarios existentes

    @horarios = BloqueHorario.all

    @ubicaciones = TipoUbicacion.where(["id != 'CER' AND id != 'N/A' AND id != 'PD' AND id != 'nul' AND id != 'TOR'"])

    @periodo = session[:parametros][:periodo_actual]

  end 


  def index_reporte_secciones_cerradas

    @secciones = Seccion.where(["periodo_id = ? and esta_abierta = ?", session[:parametros][:periodo_actual],0]).sort_by{|x| "#{x.tipo_curso.id}-#{'%03i'%x.curso.grado}-#{'%03i'%x.seccion_numero}"}

    if  @secciones.empty?
      flash[:mensaje] = "No hay secciones cerradas en el período actual"
      redirect_to :controller => "principal_admin", :action => "index"
      return
    end    

  	periodo = session[:parametros][:periodo_actual]

    @titulo_pagina = "Secciones Cerradas Período #{periodo}"


  end




	def reporte_estadisticas_generales_por_idioma

		idioma_id, categoria_id = params[:idioma].join.split("-")
		
		idioma = Idioma.find(idioma_id).descripcion

		categoria = TipoCategoria.find(categoria_id).descripcion

    @idi = idioma_id
    @peri = session[:parametros][:periodo_actual]
    @cate = categoria_id

		@titulo_pagina = "Reporte General de Alumnos por Nivel en " + idioma + " (" + categoria + ")"

    @historiales = HistorialAcademico.find_by_sql(["
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
ORDER BY t.grado, t.id", idioma_id, categoria_id, idioma_id, categoria_id, session[:parametros][:periodo_actual]])

    if  @historiales.empty?
      flash[:mensaje] = "No hay información en el periodo para el reporte seleccionado"
      redirect_to :controller => "planificacion", :action => "index"
      return
    end         


	end

  def ver_excel_estadisticas_generales
    idioma_id = params[:idioma_id]
    categoria_id = params[:tipo_categoria_id]
    periodo_id = session[:parametros][:periodo_actual]
    #descripcion_convenio = TipoConvenio.where(["id = ?", convenio_id]).first.descripcion
    ruta_excel = ReportesExcel.estadisticas_generales(idioma_id,categoria_id,periodo_id,false)
    send_file ruta_excel,
      :filename => "estadisticas_generales.xls",
      :type => "application/excel", :disposition => "attachment"
    
  end






  def index_reporte_distribucion_depositos_bancarios
  	
		@titulo_pagina = "Distribución de Depósitos Bancarios por Cuenta" 

		@historiales = HistorialAcademico.select("historial_academico.cuenta_bancaria_id, count(*) as cantidad").where(["historial_academico.periodo_id = ? AND tipo_estado_inscripcion_id = ?",session[:parametros][:periodo_actual],"INS"]).group("historial_academico.cuenta_bancaria_id")

		if  @historiales.empty?
      flash[:mensaje] = "No hay información en el periodo para el reporte seleccionado"
      redirect_to :controller => "planificacion", :action => "index"
      return
    end         

  end



  def reporte_distribucion_depositos_detalle
  	
    tipo_cuenta_id = params[:id]
		
    @titulo_pagina = "Detalle de Depósitos Bancarios en la Cuenta de: "
    @subtitulo_pagina =  CuentaBancaria.find(tipo_cuenta_id).descripcion

		@historiales = HistorialAcademico.select("historial_academico.tipo_convenio_id, count(*) as cantidad").where(["periodo_id = ? AND tipo_estado_inscripcion_id = ? AND cuenta_bancaria_id = ?",session[:parametros][:periodo_actual],"INS",tipo_cuenta_id]).group("tipo_convenio_id")

		if  @historiales.empty?
      flash[:mensaje] = "No hay información en el periodo para el reporte seleccionado"
      redirect_to :controller => "planificacion", :action => "index"
      return
    end         

  end


  def ver_excel_distribucion_depositos
    cuenta_id = params[:tipo_cuenta]
    periodo_id = session[:parametros][:periodo_actual]
    
    ruta_excel = ReportesExcel.distribucion_depositos(cuenta_id,periodo_id,false)
    send_file ruta_excel,
      :filename => "distribucion_depositos.xls",
      :type => "application/excel", :disposition => "attachment"
    
  end





  def index_reporte_congelados
		@titulo_pagina = "Alumnos Congelados en el Periodo "+ session[:parametros][:periodo_actual]

		@historiales = HistorialAcademico.where(["historial_academico.periodo_id = ? AND tipo_estado_inscripcion_id = ?",session[:parametros][:periodo_actual],"CON"])

		if  @historiales.empty?
      flash[:mensaje] = "No hay información en el periodo para el reporte seleccionado"
      if p == "planificacion"      
        redirect_to :controller => "planificacion", :action => "index"
        return
      else
        redirect_to :controller => "principal_admin", :action => "index"
        return
      end
    end         

  end

  def ver_pdf_congelados
    periodo_id = session[:parametros][:periodo_actual]
    if pdf = DocumentosPDF.generar_listado_congelados(periodo_id,false)
      send_data pdf.render,:filename => "Estudiantes_Congelados_#{periodo_id}.pdf",:type => "application/pdf", :disposition => "attachment"
    end
  end

  def alumnos_por_edificio
    @titulo_pagina = "Alumnos por edificio"
    #u = TipoUbicacion.where(:id => 'ING').limit(0).first
    @ubicaciones = TipoUbicacion.all
  end
  
  def listado_alumnos_por_edificio
    @ubicacion = TipoUbicacion.where(:id => params[:id]).limit(0).first
    @titulo_pagina = "Listado de alumnos en #{@ubicacion.descripcion}"
    @listado = @ubicacion.listado_alumnos_por_ubicacion(session[:parametros][:periodo_actual])
  end
  
  def modal_horarios_alumnos_por_edificio
    @dias = TipoDia.where(:id => ['LU','MA','MI','JU','SA']).order('orden asc')
    @idiomas = Idioma.where("id <> ?", 'OR').order("descripcion asc")
    session[:id_ubicacion] = params[:parametros][:id]
    render :layout => false
  end
  
  def generar_listado_html_por_edificio
    @titulo_pagina = "Alumnos por Edificio"
    @id = session[:id_ubicacion]
#    session[:id_ubicacion] = nil
    @idioma = params[:idioma][:seleccionado]
    @idioma.delete_if{|x| x == ""} 
    if @idiama == nil || @idioma.size == 0 
      @idioma = ['AL','IN','PG','FR','IT']  #cableaaaado
    end
    @dias = params[:dia][:seleccionado]
    @dias.delete_if{|x| x == ""}
    if @dias == nil || @dias.size == 0
      @dias = ['LU','MA','MI','JU','SA']  #cableaaaado 
    end
    @consulta = consulta_espantosa_alumnos(@id,@dias,@idioma)
    if @consulta.size <= 0
      flash[:mensaje] = "No existen estudiantes para los filtros seleccionados"
    end
  end
  
  def generar_listado_alumnos_por_edificio_pdf
    dias = params[:dias]
    id = params[:id]
    edificio = TipoUbicacion.where(:id => id).limit(0).first
    titulo = "Edificio: #{edificio.descripcion}"
    idiomas = params[:idiomas]
    consulta = consulta_espantosa_alumnos(id,dias,idiomas)
    pdf = DocumentosPDF.generar_listado_alumnos_por_edificio_pdf(consulta,titulo)
    send_data pdf.render,:filename => "listado_alumnos_por_edificio.pdf",:type => "application/pdf", :disposition => "attachment"
  end
  
  def generar_listado_alumnos_por_edificio_excel
    dias = params[:dias]
    id = params[:id]
    edificio = TipoUbicacion.where(:id => id).limit(0).first
    titulo = "Edificio: #{edificio.descripcion}"
    idiomas = params[:idiomas]
    consulta = consulta_espantosa_alumnos(id,dias,idiomas)
    ruta_excel = ReportesExcel.generar_listado_alumnos_por_edificio_excel(consulta,titulo)
    send_file ruta_excel,
      :filename => "listado.xls",
      :type => "application/excel", :disposition => "attachment"
    

  end

  def consulta_espantosa_alumnos(id,dias,idioma)
    TipoUbicacion.find_by_sql(["
        SELECT CONCAT(usuario.apellidos,' ',usuario.nombres) as nombre,
        	usuario.ci as cedula, 
        	aula.descripcion as aula, 
        	idioma.descripcion as idioma,
        	tipo_nivel.descripcion as nivel, 
        	tipo_categoria.descripcion as categoria
        FROM estudiante INNER JOIN usuario ON estudiante.usuario_ci = usuario.ci
        	 INNER JOIN historial_academico ON usuario.ci = historial_academico.usuario_ci
        	 INNER JOIN tipo_nivel ON historial_academico.tipo_nivel_id = tipo_nivel.id
        	 INNER JOIN tipo_categoria ON historial_academico.tipo_categoria_id = tipo_categoria.id
        	 INNER JOIN horario_seccion ON historial_academico.idioma_id = horario_seccion.idioma_id AND historial_academico.tipo_categoria_id = horario_seccion.tipo_categoria_id AND historial_academico.tipo_nivel_id = horario_seccion.tipo_nivel_id AND historial_academico.periodo_id = horario_seccion.periodo_id AND historial_academico.seccion_numero = horario_seccion.seccion_numero
        	 INNER JOIN aula ON horario_seccion.aula_id = aula.id
        	 INNER JOIN idioma ON idioma.id = historial_academico.idioma_id
        WHERE tipo_ubicacion_id = ? and
        historial_academico.periodo_id = ? and
        historial_academico.tipo_estado_inscripcion_id = 'INS' and
        horario_seccion.tipo_dia_id in (?) and
        idioma.id in (?)
        GROUP BY usuario.ci
        ORDER BY usuario.apellidos ASC, usuario.nombres ASC  
    ",id,session[:parametros][:periodo_actual],dias,idioma])

  end

  def nomina_instructores
    @titulo_pagina = "Nómina instructores"
    @instructores = Seccion.where(:periodo_id => session[:parametros][:periodo_actual],:esta_abierta => true).collect{|x| x.instructor}.uniq.compact.sort_by{|i| i.usuario.nombre_completo}
  end

  def nomina_instructores_pdf
    instructores = Seccion.where(:periodo_id => session[:parametros][:periodo_actual],:esta_abierta => true).collect{|x| x.instructor}.uniq.compact.sort_by{|i| i.usuario.nombre_completo}
    pdf = DocumentosPDF.nomina_instructores(instructores,session[:parametros][:periodo_actual])
    send_data pdf.render,:filename => "nomina_instructores.pdf",:type => "application/pdf", :disposition => "attachment"
  end
  
  def nomina_instructores_excel
    instructores = Seccion.where(:periodo_id => session[:parametros][:periodo_actual],:esta_abierta => true).collect{|x| x.instructor}.uniq.compact.sort_by{|i| i.usuario.nombre_completo}
    ruta_excel = ReportesExcel.nomina_instructores(instructores,session[:parametros][:periodo_actual])
    send_file ruta_excel,
      :filename => "nomina_instructores.xls",
      :type => "application/excel", :disposition => "attachment"
  end
  
  
end
