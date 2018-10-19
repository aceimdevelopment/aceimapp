# encoding: utf-8

class AdminSeccionController < ApplicationController
  before_action :filtro_logueado
  before_action :filtro_super_administrador
  
  def index
    @titulo_pagina = "Listado de Secciones"  

    @secciones = Seccion.where(["periodo_id = ?", session[:parametros][:periodo_actual]]).sort_by{|x| "#{x.tipo_curso.id}-#{'%03i'%x.curso.grado}-#{'%03i'%x.seccion_numero}"}

    @filtro = params[:filtrar] 
    @filtro = nil if @filtro == nil || @filtro.strip.size == 0
    @filtro2 = params[:filtrar2] 
    @filtro2 = nil if @filtro2 == nil || @filtro2.strip.size == 0
    @filtro3 = params[:filtrar3] 
    @filtro3 = nil if @filtro3 == nil || @filtro3.strip.size == 0
   
		periodo = session[:parametros][:periodo_actual]
    @total_no_confirmados = HistorialAcademico.where(periodo_id: periodo, tipo_estado_inscripcion_id: "PRE").count

    @subtitulo_pagina = "Período #{periodo}"

    @tipos_curso = @secciones.collect{|y| y.tipo_curso}.uniq
    @ubicaciones = @secciones.collect{|x| x.horario_seccion }.flatten.collect{|w| w.aula }.compact.collect{|y| y.tipo_ubicacion }.uniq
    @horarios = @secciones.collect{|z| z.horario}.uniq

    if @filtro
      idioma_id , tipo_categoria_id = @filtro.split ","
      @secciones = Seccion.where(:periodo_id=>periodo,
        :idioma_id => idioma_id, :tipo_categoria_id => tipo_categoria_id ).sort_by{|x| "#{x.tipo_curso.id}-#{'%03i'%x.curso.grado}-#{x.horario}-#{x.seccion_numero}"}
      return
    end    
 
    if @filtro2
      secciones1 = []
      @secciones.each{|s|
        aula = s.horario_seccion.first.aula
        secciones1 << s if aula && aula.tipo_ubicacion_id == @filtro2
      }                
      @secciones = secciones1
      return
    end
    
    if @filtro3
      @secciones = Seccion.where(:periodo_id=>periodo).delete_if{|s| !s.mach_horario?(@filtro3)}
    end


  end
  

  def nuevo

  	@titulo_pagina = "Agregar Sección" 
    @seccion = Seccion.new
    @periodo = params[:periodo]
	@idioma_cat = params[:idioma]

	if(!params[:idioma].kind_of?(String))
	@idioma_id, @categoria_id = params[:idioma].join.split("-")
	else
	@idioma_id, @categoria_id = params[:idioma].split("-")
	end

    @idioma = Idioma.where(:id => @idioma_id).limit(1).first
    @categoria = TipoCategoria.where(:id => @categoria_id).limit(1).first
    @secciones = Seccion.where(["periodo_id = ? and idioma_id = ? and tipo_categoria_id = ?", @periodo, @idioma_id, @categoria_id]).sort_by{|x| "#{x.tipo_curso.id}-#{'%03i'%x.curso.grado}-#{'%03i'%x.seccion_numero}"}

		@niveles = TipoNivel.select("curso.*, tipo_nivel.*").joins(:curso).where(["curso.idioma_id = ? AND curso.tipo_categoria_id = ? AND curso.tipo_nivel_id != 'NI' AND curso.tipo_nivel_id != 'BBVA' AND curso.grado != ?", @idioma_id, @categoria_id, 0]).order("grado")

    @horarios = @seccion.horarios

    
    
  end





  def nuevo_guardar

	periodo = params[:seccion][:periodo]
	idioma = params[:seccion][:idioma]
	idioma_cat = params[:seccion][:idioma_cat]
	categoria = params[:seccion][:categoria]
	nivel = params[:seccion][:tipo_nivel_id]
    horario = params[:horario][:id]
    cantidad = params[:cantidad][:id].to_i
    ubi = params[:ubicacion][:ubicacion_id]

    if ( (params[:seccion][:periodo] != nil) && 
         (params[:seccion][:idioma] != nil) &&
         (params[:seccion][:idioma_cat] != nil) &&
         (params[:seccion][:categoria] != nil) &&
         (params[:seccion][:tipo_nivel_id] != nil) &&
         (params[:horario][:id] != nil && params[:horario][:id] != "") &&
         (params[:cantidad][:id] != nil) )

      dia1, resto = horario.split"."

      if(dia1 == "SA")
        hora = resto
        dia2= dia1
      else
        dia1, dia2, hora = horario.split"."
      end

		  #Antes de guardar en seccion, se debe guardar en curso_periodo
		
		  curso_p = CursoPeriodo.where(["periodo_id = ? AND idioma_id = ? AND tipo_categoria_id = ? AND tipo_nivel_id = ?", periodo, idioma, categoria, nivel])

		  if(curso_p.empty?)
			  curso_periodo = CursoPeriodo.new
			  curso_periodo.periodo_id = periodo
			  curso_periodo.idioma_id = idioma
			  curso_periodo.tipo_categoria_id = categoria
			  curso_periodo.tipo_nivel_id = nivel
			  curso_periodo.save
		  end
	
		  for i in 1..cantidad
			
			  #Se busca el indice que determina el numero de seccion

			  indice = Seccion.where(["periodo_id = ? AND idioma_id = ? AND tipo_categoria_id = ? AND tipo_nivel_id = ?", periodo, idioma, categoria, nivel]).order("seccion_numero DESC").limit(1).first

			  if(indice == nil) #Si es la primera seccion que se crea de un curso dado, entra aqui

				  numero_seccion = 1

			  else

				  numero_seccion = indice.seccion_numero + 1

			  end

			  #Se busca el bloque_horario asociado a dicho dia y hora elegidos (para determinar si es H1, H2, etc)

			  bloq_h = BloqueHorario.select("id").where(:tipo_dia_id1 => dia1, :tipo_dia_id2 => dia2, :tipo_hora_id => hora).first

			  @seccion = Seccion.new
			  @seccion.periodo_id = periodo
			  @seccion.idioma_id = idioma
			  @seccion.tipo_categoria_id = categoria
			  @seccion.tipo_nivel_id = nivel
			  @seccion.seccion_numero = numero_seccion
			  @seccion.esta_abierta = 1
			  @seccion.bloque_horario_id = bloq_h.id
			  @seccion.save

			  #Una vez creada la seccion, se debe almacenar en horario_seccion con un aula

			  horario_seccion1 = HorarioSeccion.new
			  horario_seccion1.periodo_id = periodo
			  horario_seccion1.idioma_id = idioma
			  horario_seccion1.tipo_categoria_id = categoria
			  horario_seccion1.tipo_nivel_id = nivel
			  horario_seccion1.seccion_numero = numero_seccion
			  horario_seccion1.tipo_hora_id = hora
			  horario_seccion1.tipo_dia_id = dia1	
			  horario_seccion1.aula_id = "PD"

        if(dia1 != "SA")

				  horario_seccion2 = HorarioSeccion.new
				  horario_seccion2.periodo_id = periodo
				  horario_seccion2.idioma_id = idioma
				  horario_seccion2.tipo_categoria_id = categoria
				  horario_seccion2.tipo_nivel_id = nivel
				  horario_seccion2.seccion_numero = numero_seccion
				  horario_seccion2.tipo_hora_id = hora
				  horario_seccion2.tipo_dia_id = dia2	
          horario_seccion2.aula_id = "PD"

        end


        #Se buscan las aulas disponibles para ese trimestre      

        aulas = Aula.where(:tipo_ubicacion_id => ubi, :conjunto_disponible => 1, :usada => 1).collect{|a| a.id}

        aulas_disp = BloqueAulaDisponible.where(["aula_id IN (?) AND tipo_hora_id = ? AND tipo_dia_id = ? AND asignada = ?", aulas, hora, dia1, 1]).collect{|a| a.aula_id}

        aulas_disp.each{|aula|

          #Se verifica si el aula se encuentra libre

          horario_sec = HorarioSeccion.where(["periodo_id = ? AND tipo_dia_id = ? AND tipo_hora_id = ? AND aula_id = ?", periodo, dia1, hora, aula])

          if(horario_sec.empty?) #Si el aula no ha sido asignada para ese horario, se asigna a esta nueva seccion

			      horario_seccion1.aula_id = aula

			      if(dia1 != "SA")

              #Se debe buscar la pareja del aula que fue asignada para el dia1
              pareja = BloqueAulaDisponible.where(["aula_id = ? AND tipo_hora_id = ? AND tipo_dia_id = ? AND asignada = ?", aula, hora, dia1, 1]).limit(1).first
              aula_complemento = BloqueAulaDisponible.where(["pareja = ? AND tipo_dia_id = ? AND tipo_hora_id = ? ", pareja.pareja, dia2, hora]).limit(1).first

		          #Se asigna el aula complemento
		          if aula_complemento
				      horario_seccion2.aula_id = aula_complemento.aula_id
				  else
				  	horario_seccion1.aula_id = "PD"
				  	horario_seccion2.aula_id = "PD"
				  end

			      end

          end

          break if horario_sec.empty?;

        }


        #Se guarda el segundo registro de la nueva seccion
        if(dia1 != "SA")
          horario_seccion2.save
        end


			  if horario_seccion1.save
          info_bitacora("Nueva Sección Agregada: periodo: #{periodo}, idioma: #{idioma}, categoria: #{categoria}, nivel: #{nivel}, numero: #{numero_seccion}")
				  flash[:mensaje] = "Sección creada satisfactoriamente"
			  else

				  flash[:mensaje] = "No se ha podido crear la sección"
				  redirect_to(:action=>"nuevo" ,:periodo => periodo, :idioma => idioma_cat, :categoria => categoria)
				  return
			  end

		  end
		
    else
  	  flash[:mensaje] = "Debe elegir todos los parámetros correspodientes"
    end
    
    redirect_to(:action=>"nuevo" ,:periodo => periodo, :idioma => idioma_cat, :categoria => categoria)	
    return
  end




  #Metodo invocado desde el modulo para gestionar secciones
  def modificar

		@periodo_id = params[:parametros][:periodo_id]
		@idioma_id = params[:parametros][:idioma_id]
		@tipo_categoria_id = params[:parametros][:tipo_categoria_id]
		@tipo_nivel_id = params[:parametros][:tipo_nivel_id]
		@seccion_numero = params[:parametros][:seccion_numero]
		@bloque_horario_id = params[:parametros][:bloque_horario_id]

		e = Seccion.select("esta_abierta").where(:periodo_id => @periodo_id, :idioma_id => @idioma_id, :tipo_categoria_id => @tipo_categoria_id, :tipo_nivel_id => @tipo_nivel_id, :seccion_numero => @seccion_numero, :bloque_horario_id => @bloque_horario_id).first

		@esta_abierta = e.esta_abierta

		@idioma_cats = @idioma_id + "-" + @tipo_categoria_id

		@seccion = Seccion.where(:periodo_id => @periodo_id, :idioma_id  => @idioma_id, :tipo_categoria_id => @tipo_categoria_id, :tipo_nivel_id => @tipo_nivel_id, :seccion_numero => @seccion_numero).first

		@idiomas = Idioma.select("idioma.*,tipo_curso.*").joins(:tipo_curso).where(["id != ? and tipo_curso.tipo_categoria_id != ?", "OR","BBVA"])

		@idiomas.each{|i|
			
			tipo_categoria = TipoCategoria.where(["id = ?", i.tipo_categoria_id]).limit(1).first

			if(i.id=="IN")			
				i.descripcion = i.descripcion + "-" + tipo_categoria.descripcion
			end

			i.id = i.id + "-" +i.tipo_categoria_id
		
		}
    
    @secciones = Seccion.new
		@horarios = @secciones.horarios
		@horario_secciones = @seccion.horario_sec

		render :layout => false   

  end
  


  def modificar_guardar

		#Se obtienen los parametros necesarios para modificar la seccion
    idioma_id, tipo_categoria_id = params[:seccion][:idioma_cat].split("-")
		tipo_nivel_id = params[:tipo_nivel][0]
		tipo_dia_id1, tipo_dia_id2, tipo_hora_id = params[:horario].join.split(".")


		if (tipo_dia_id1 == "SA")
    	tipo_hora_id = tipo_dia_id2
			tipo_dia_id2 = tipo_dia_id1
    end

		periodo = params[:seccion][:periodo]
		idioma_actual = params[:seccion][:idioma]
		categoria_actual = params[:seccion][:categoria]
		nivel_actual = params[:seccion][:nivel]
		seccion_numero = params[:seccion][:num_seccion]
		bloque_horario_id = params[:seccion][:bloque_horario_id]

		curso_p = CursoPeriodo.where(["periodo_id = ? AND idioma_id = ? AND tipo_categoria_id = ? AND tipo_nivel_id = ?", periodo, idioma_id, tipo_categoria_id, tipo_nivel_id])

		#Si las caracteristicas de la seccion a modificar no se encuentra en CursoPeriodo, se añade ese nuevo registro
		if(curso_p.empty?)
			curso_p = CursoPeriodo.new
			curso_p.periodo_id = periodo
			curso_p.idioma_id = idioma_id
			curso_p.tipo_categoria_id = tipo_categoria_id
			curso_p.tipo_nivel_id = tipo_nivel_id
			curso_p.save
		end

		bloque_horario = BloqueHorario.select("id").where(:tipo_dia_id1 => tipo_dia_id1, :tipo_hora_id => tipo_hora_id).first

		seccion = Seccion.where(["periodo_id = ? AND idioma_id = ? AND tipo_categoria_id = ? AND tipo_nivel_id = ? AND seccion_numero = ?", periodo, idioma_actual, categoria_actual, nivel_actual, seccion_numero]).first

		indice = Seccion.where(["periodo_id = ? AND idioma_id = ? AND tipo_categoria_id = ? AND tipo_nivel_id = ?", periodo, idioma_id, tipo_categoria_id, tipo_nivel_id]).order("seccion_numero DESC").limit(1).first


		aula_id1 = "PD"
		aula_id2 = "PD"



		if(indice == nil)#Si es la primera seccion que se crea de un curso dado, entra aqui
			numero_seccion = 1

		else
			if (tipo_nivel_id != nivel_actual)#Si el nivel cambia, el número de la sección debe cambiar
				numero_seccion = indice.seccion_numero + 1
			else
				numero_seccion = seccion_numero
			end
		end

		horario_actual = seccion.bloque_horario_id

		seccion.esta_abierta = 1
		seccion.periodo_id = periodo
		seccion.idioma_id = idioma_id
		seccion.tipo_categoria_id = tipo_categoria_id
		seccion.tipo_nivel_id = tipo_nivel_id
		seccion.seccion_numero = numero_seccion
		seccion.bloque_horario_id = bloque_horario.id
		seccion.save


		#Si cambia el horario, se borra el horario viejo y se inserta el horario nuevo
		if(horario_actual != bloque_horario.id)
			#Se borran los horarios de la sección para ser añadidos luego
			HorarioSeccion.delete_all(["periodo_id = ? AND idioma_id = ? AND tipo_categoria_id = ? AND tipo_nivel_id = ? AND seccion_numero = ?", periodo, idioma_actual, categoria_actual, tipo_nivel_id, numero_seccion])

		
			#Se crea el primer registro para el horario
			horario_seccion1 = HorarioSeccion.new
			horario_seccion1.periodo_id = periodo
			horario_seccion1.idioma_id = idioma_id
			horario_seccion1.tipo_categoria_id = tipo_categoria_id
			horario_seccion1.tipo_nivel_id = tipo_nivel_id
			horario_seccion1.seccion_numero = numero_seccion
			horario_seccion1.tipo_hora_id = tipo_hora_id
			horario_seccion1.tipo_dia_id = tipo_dia_id1	
			horario_seccion1.aula_id = 'PD'	
			horario_seccion1.save

			if(tipo_dia_id1	 != "SA")
				horario_seccion2 = HorarioSeccion.new
				horario_seccion2.periodo_id = periodo
				horario_seccion2.idioma_id = idioma_id
				horario_seccion2.tipo_categoria_id = tipo_categoria_id
				horario_seccion2.tipo_nivel_id = tipo_nivel_id
				horario_seccion2.seccion_numero = numero_seccion
				horario_seccion2.tipo_hora_id = tipo_hora_id
				horario_seccion2.tipo_dia_id = tipo_dia_id2	
				horario_seccion2.aula_id = aula_id2
				horario_seccion2.save
			end
		end

		#Si la seccion modificada es la unica que cumple con las condiciones de CursoPeriodo, hay que eliminarla
		otra_seccion = Seccion.where(["periodo_id = ? AND idioma_id = ? AND tipo_categoria_id = ? AND tipo_nivel_id = ?", periodo, idioma_actual, categoria_actual, nivel_actual])

		if(otra_seccion.empty?)

			CursoPeriodo.delete_all(["periodo_id = ? AND idioma_id = ? AND tipo_categoria_id = ? AND tipo_nivel_id = ?",periodo, idioma_actual, categoria_actual, nivel_actual])
		end


    info_bitacora("Sección Modificada: periodo: #{periodo}, idioma: #{idioma_actual}, categoria: #{categoria_actual}, nivel: #{nivel_actual}, numero: #{seccion_numero}, bloque horario: #{bloque_horario_id} ... a: #{periodo}, idioma: #{idioma_id}, categoria: #{tipo_categoria_id}, nivel: #{tipo_nivel_id}, numero: #{numero_seccion}, bloque horario: #{bloque_horario.id}")

		flash[:mensaje] = "Sección modificada satisfactoriamente"

		redirect_to(:action=>"index")


  end


  def elegir_periodo_idioma_modal

		@idiomas = Idioma.select('idioma.*,tipo_curso.*').joins(:tipo_curso).where(["id != ? and tipo_curso.tipo_categoria_id != ?", "OR","BBVA"])

		@idiomas.each{|i|
			
			tipo_categoria = TipoCategoria.where(["id = ?", i.tipo_categoria_id]).limit(1).first

			if(i.id=="IN")			
				i.descripcion = i.descripcion + " - " + tipo_categoria.descripcion
			end

			i.id = i.id + "-" +i.tipo_categoria_id
		
		}
		
    @periodo_actual = session[:parametros][:periodo_actual]

    render :layout => false

  end




  def elegir_ubicacion_segun_horario

    #Se toman los datos provenientes del metodo "mostrar_ubicacion_segun_horario" de global.js.coffe

		tipo_dia_id1, tipo_dia_id2, tipo_hora_id = params[:identificador].split(".")

    periodo_id = session[:parametros][:periodo_actual]

		if (tipo_dia_id1 == "SA")
    	tipo_hora_id = tipo_dia_id2
			tipo_dia_id2 = tipo_dia_id1
    end


    #Se buscan las ubicaciones de aulas en donde aún queden aulas disponibles

    ubicacion = BloqueAulaDisponible.joins("LEFT JOIN horario_seccion hs ON hs.aula_id = bloque_aula_disponible.aula_id AND hs.tipo_hora_id = bloque_aula_disponible.tipo_hora_id AND hs.tipo_dia_id = bloque_aula_disponible.tipo_dia_id AND hs.periodo_id = '#{periodo_id}'").where("hs.periodo_id is null AND bloque_aula_disponible.tipo_dia_id = '#{tipo_dia_id1}' AND bloque_aula_disponible.tipo_hora_id = '#{tipo_hora_id}' AND bloque_aula_disponible.asignada = 1")

    @ubicaciones2 = ubicacion.collect{|y| y.aula.tipo_ubicacion}.uniq

    ubica = ubicacion.collect{|y| y.aula.tipo_ubicacion}.uniq

    i = ubica.size
    j = 0

    @ubicaciones = Array.new(i) {Hash.new}


    while(j < i )

      @ubicaciones[j]['id'] = ubica[j].id

      aulas_libres = BloqueAulaDisponible.joins("LEFT JOIN horario_seccion hs ON hs.aula_id = bloque_aula_disponible.aula_id AND hs.tipo_hora_id = bloque_aula_disponible.tipo_hora_id AND hs.tipo_dia_id = bloque_aula_disponible.tipo_dia_id AND hs.periodo_id = '#{periodo_id}'").where("hs.periodo_id is null AND bloque_aula_disponible.tipo_dia_id = '#{tipo_dia_id1}' AND bloque_aula_disponible.tipo_hora_id = '#{tipo_hora_id}' AND bloque_aula_disponible.asignada = 1").collect{|a| a.aula_id}

      cant_aulas = Aula.where("tipo_ubicacion_id = ? AND conjunto_disponible = ? AND usada = ? AND id IN (?)", ubica[j].id, 1, 1, aulas_libres).count

      @ubicaciones[j]['desc'] = ubica[j].descripcion_corta + " - Aulas disponibles: " + cant_aulas.to_s

      j = j + 1

    end
   
    render :layout => false

  end



  def confirmar_abrir_seccion

		periodo_id = params[:parametros][:periodo_id]
		idioma_id = params[:parametros][:idioma_id]
		tipo_categoria_id = params[:parametros][:tipo_categoria_id]
		tipo_nivel_id = params[:parametros][:tipo_nivel_id]
		seccion_numero = params[:parametros][:seccion_numero]
		@bloque_horario_id = params[:parametros][:bloque_horario_id]
		@accion = params[:parametros][:accion]
		@controlador = params[:parametros][:controlador]
    @p = params[:parametros][:seccion]

		@seccion = Seccion.where(:periodo_id => periodo_id, :idioma_id => idioma_id, :tipo_categoria_id => tipo_categoria_id, :tipo_nivel_id => tipo_nivel_id, :seccion_numero => seccion_numero, :bloque_horario_id => @bloque_horario_id).first

		render :layout => false

  end



  def abrir


		periodo_id, idioma_id,tipo_categoria_id,tipo_nivel_id,seccion_numero = params[:seccion].split(",")

    bloque_horario_id = params[:horario]

    seccion = Seccion.where(:periodo_id=>periodo_id, :idioma_id=>idioma_id, :tipo_categoria_id=>tipo_categoria_id, :tipo_nivel_id=>tipo_nivel_id, :seccion_numero=>seccion_numero, :bloque_horario_id => bloque_horario_id).limit(1).first

		accion = params[:accion]
		controlador = params[:controlador]

	  seccion.esta_abierta = 1
		seccion.periodo_id = periodo_id
		seccion.idioma_id = idioma_id
		seccion.tipo_categoria_id = tipo_categoria_id
		seccion.tipo_nivel_id = tipo_nivel_id
		seccion.seccion_numero = seccion_numero
		seccion.bloque_horario_id = bloque_horario_id
		seccion.save

    redirect_to :action=> accion, :controller => controlador

  end



  def confirmar_cerrar_seccion

		periodo_id = params[:parametros][:periodo_id]
		idioma_id = params[:parametros][:idioma_id]
		tipo_categoria_id = params[:parametros][:tipo_categoria_id]
		tipo_nivel_id = params[:parametros][:tipo_nivel_id]
		seccion_numero = params[:parametros][:seccion_numero]
		@bloque_horario_id = params[:parametros][:bloque_horario_id]
		@accion = params[:parametros][:accion]
		@controlador = params[:parametros][:controlador]
    @p = params[:parametros][:seccion]

		@seccion = Seccion.where(:periodo_id => periodo_id, :idioma_id => idioma_id, :tipo_categoria_id => tipo_categoria_id, :tipo_nivel_id => tipo_nivel_id, :seccion_numero => seccion_numero, :bloque_horario_id => @bloque_horario_id).first

		render :layout => false


  end



  def cerrar


		periodo_id, idioma_id,tipo_categoria_id,tipo_nivel_id,seccion_numero = params[:seccion].split(",")

    bloque_horario_id = params[:horario]

    seccion = Seccion.where(:periodo_id=>periodo_id, :idioma_id=>idioma_id, :tipo_categoria_id=>tipo_categoria_id, :tipo_nivel_id=>tipo_nivel_id, :seccion_numero=>seccion_numero, :bloque_horario_id => bloque_horario_id).limit(1).first

		accion = params[:accion]
		controlador = params[:controlador]

	  seccion.esta_abierta = 0
		seccion.periodo_id = periodo_id
		seccion.idioma_id = idioma_id
		seccion.tipo_categoria_id = tipo_categoria_id
		seccion.tipo_nivel_id = tipo_nivel_id
		seccion.seccion_numero = seccion_numero
		seccion.bloque_horario_id = bloque_horario_id
		seccion.save

    #Se debe liberar el aula una vez que se cierra la seccion

    horario_seccion = HorarioSeccion.where(["periodo_id = ? AND idioma_id = ? AND tipo_categoria_id = ? AND tipo_nivel_id = ? AND seccion_numero = ?", periodo_id, idioma_id, tipo_categoria_id, tipo_nivel_id, seccion_numero])

    horario_seccion.each{|h|

      h.aula_id = 'PD'
      h.save
  
    }



    redirect_to :action=> accion, :controller => controlador

  end


  

end





