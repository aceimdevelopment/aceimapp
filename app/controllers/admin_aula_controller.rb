# encoding: utf-8

class AdminAulaController < ApplicationController
  before_action :filtro_logueado
  before_action :filtro_administrador
  before_action :filtro_super_administrador
    
  def index
    @titulo_pagina = "Listado de Aulas"  
    @aulas = Aula.all
  end
  
  def nuevo
    if session[:administrador].tipo_rol_id > 3 
      flash[:mensaje] = "Usted no posee los privilegios para acceder a esta función"
      redirect_to :action => 'index'
    end
  	@titulo_pagina = "Agregar Aula" 
    @aula = Aula.new
  end

  def nuevo_guardar
    if params[:aula][:id]!="" && params[:aula][:id].to_i.integer?
  	  id = "#{params[:aula][:tipo_ubicacion_id]}-#{"%002i"%params[:aula][:id]}" 
    else
      id=""
    end  
    if Aula.where(:id=>id).limit(1).first
  		flash[:mensaje] = "El Aula ya existe"
  		redirect_to :action => "nuevo"
  		return
  	end 

  	@aula = Aula.new
  	@aula.id = id
    @aula.tipo_ubicacion_id = params[:aula][:tipo_ubicacion_id]
    @aula.descripcion = params[:aula][:descripcion] + ", " + "Aula "+ params[:aula][:id]
    @aula.conjunto_disponible = 1

    respond_to do |format|
      if @aula.save

				tipo_bloque = TipoBloque.where("pareja != ?", "-1").order("orden")

				tipo_bloque.each{|tb|
					bloque_aula_disponible = BloqueAulaDisponible.new
					bloque_aula_disponible.tipo_hora_id = tb.tipo_hora_id
					bloque_aula_disponible.tipo_dia_id = tb.tipo_dia_id
					bloque_aula_disponible.aula_id = id
					bloque_aula_disponible.save
				}

        info_bitacora("Nueva Aula Agregada: #{id}")
        flash[:mensaje] = "Aula registrada Satisfactoriamente"
        format.html { redirect_to(:action=>"index") }
      else
        flash[:mensaje] = "Errores en el Formulario impiden que el estudiante sea actualizado"
        format.html { render :action => "nuevo" }
        @aula.id = params[:aula][:id]
        format.xml  { render :xml => @aula.errors, :status => :unprocessable_entity }
      end
    end

  end

  def modificar
    if session[:administrador].tipo_rol_id > 3 
      flash[:mensaje] = "Usted no posee los privilegios para acceder a esta función"
      redirect_to :action => 'index'
    end
    id = params[:parametros][:id]
  	@aula = Aula.find(id)
  	render :layout => false   
  end
  
  def modificar_guardar
    id = params[:aula][:id]
    @aula=Aula.where(:id=>id).limit(1).first
    @aula.tipo_ubicacion_id = params[:aula][:tipo_ubicacion_id]
    @aula.descripcion = params[:aula][:descripcion]
    @aula.conjunto_disponible = params[:aula][:conjunto_disponible]
    
    respond_to do |format|
      if @aula.save
        info_bitacora("Aula: #{id} Actualizada")
        flash[:mensaje] = "Aula actualizada Satisfactoriamente"
        format.html { redirect_to(:action=>"index") }
      else
        flash[:mensaje] = "Errores en el Formulario impiden que el estudiante sea actualizado"
        format.html { render :action => "modificar" }
        @aula.id = params[:aula][:id]
        format.xml  { render :xml => @aula.errors, :status => :unprocessable_entity }
      end
    end
    
  end

  def ingresar_aulas_planificacion
    @titulo_pagina = "Ingresar Aulas Disponibles"  
    @aulas_disponibles = Aula.where(:conjunto_disponible=>1).order("tipo_ubicacion_id ASC, id ASC")

    @ubicaciones = @aulas_disponibles.collect{|w| w.tipo_ubicacion}.uniq
       
  end

  def guardar_aulas_planificacion

    aulas_marcadas = []
    aulas_disponibles = Aula.all

    params[:aula_marcada][0].each{|x| 
      aulas_marcadas << x[0]
    }

    aulas_disponibles.each {|ad|

      aula = Aula.where(:id=>"#{ad.id}").limit(1).first

      if aulas_marcadas.include?(ad.id)
        aula.usada = 1
      else
        aula.usada = 0
      end
      
      aula.save
    }

    flash[:mensaje] = "Aulas asignadas almacenadas con éxito"
    redirect_to(:action=>"index", :controller => "planificacion")

  end

  def ingresar_horario_aulas_planificacion
    @tipo_dias = TipoDia.where("id != 'VI' and id != 'null'").order('orden2')
    @titulo_pagina = "Ingresar Horarios de Aulas Disponibles"  
    @aulas_disponibles = Aula.includes(:bloque_aula_disponible => [:tipo_dia,:tipo_hora]).where(:usada=>1).order("aula.tipo_ubicacion_id ASC, aula.id ASC, tipo_hora.orden ASC,tipo_dia.orden2 ASC")
    @cant_horarios = BloqueHorario.count
    @ubicaciones = @aulas_disponibles.collect{|w| w.tipo_ubicacion}.uniq

  end

  def guardar_horario_aulas_planificacion

    if params[:horario_aula_disponible] != nil
  
      bloque_aula_disponible = BloqueAulaDisponible.all
		
		  BloqueAulaDisponible.update_all "asignada = 0"
		  BloqueAulaDisponible.update_all "pareja = 0"
		
		  params[:horario_aula_disponible][0].each {|aula, a|

		      a.each {|dia, b|

		        b.each {|horario, c|

						  bloque = BloqueAulaDisponible.where(['tipo_hora_id = ? AND tipo_dia_id = ? AND aula_id = ?', horario, dia, aula]).limit(1).first

						  bloque.asignada = 1

						  bloque.save

		        }
		      }
		  }
      
      flash[:mensaje] = "Horarios elegidos con éxito"
      redirect_to(:action=>"emparejar_aulas")

    else

      flash[:mensaje] = "No puede dejar los campos vacíos"
      redirect_to(:action=>"ingresar_horario_aulas_planificacion")

    end

  end



  def emparejar_aulas
 
		aulas = BloqueAulaDisponible.where(:asignada=>"1") #Se seleccionan todas las aulas elegidas con sus horarios respectivos
    
		i = 1

		aulas.each {|a|


			if(a.tipo_dia_id != "SA") #Se eligen todos los horarios excepto el del sabado que no necesita emparejarse

				pareja1 = BloqueAulaDisponible.where(["aula_id = ? AND tipo_hora_id = ? AND tipo_dia_id = ? AND asignada = ? ", a.aula_id, a.tipo_hora_id, a.tipo_dia_id, 1]).limit(1).first

				if (pareja1.pareja == 0) #Si pareja1 no ha sido emparejada aun, entra aqui

					#Buscamos el dia complemento de pareja1 (su pareja)

					case a.tipo_dia_id
						when "LU"
							dia = "MI"
						when "MI"
							dia = "LU"
						when "MA"
							dia = "JU"
						when "JU"
							dia = "MA"
					end #endcase

					#Buscamos si existe la pareja para pareja1
					pareja2 = BloqueAulaDisponible.where(["aula_id = ? AND tipo_hora_id = ? AND tipo_dia_id = ? AND asignada = ? ", a.aula_id, a.tipo_hora_id, dia, 1]).limit(1).first
			
					#Si existe esa pareja complemento, entramos aqui
					if(pareja2 != nil)

						#Le asignamos un numero de pareja a la pareja
						pareja1.pareja = i
						pareja2.pareja = i

						pareja1.save
						pareja2.save
			
			      i = i + 1

					end #endif(pareja2 != nil)

				end #endif (pareja1.pareja == 0)

			end #endif(a.tipo_dia_id != "SA")


		} #end aulas.each {|a|


    aulas_ya_emparejadas = ParejaAulasTemporal.select("pareja_aulas_temporal.*").joins("INNER JOIN bloque_aula_disponible ON bloque_aula_disponible.tipo_dia_id = pareja_aulas_temporal.tipo_dia_id AND bloque_aula_disponible.tipo_hora_id = pareja_aulas_temporal.tipo_hora_id AND bloque_aula_disponible.aula_id = pareja_aulas_temporal.aula_id").where(["bloque_aula_disponible.asignada = ? AND bloque_aula_disponible.pareja = ? AND bloque_aula_disponible.tipo_dia_id != ? ", 1 ,0, "SA"])

    #IMPORTANTE NO BORRAR ESTE PUTS, deja de funcionar el metodo si se borra 
    puts aulas_ya_emparejadas

    ParejaAulasTemporal.delete_all()

    aulas_ya_emparejadas.each{|ay|
      pareja_aula_temporal = ParejaAulasTemporal.new
      pareja_aula_temporal.tipo_hora_id = ay.tipo_hora_id
      pareja_aula_temporal.tipo_dia_id = ay.tipo_dia_id
      pareja_aula_temporal.aula_id = ay.aula_id
      pareja_aula_temporal.pareja = ay.pareja
      pareja_aula_temporal.save
    }#endeach aulas_ya_emparejadas ay


    aulas_ya_emparejadas.each{|aul|
      
      pareja1 = BloqueAulaDisponible.where(["aula_id = ? AND tipo_hora_id = ? AND tipo_dia_id = ? AND asignada = ? ", aul.aula_id, aul.tipo_hora_id, aul.tipo_dia_id, 1]).limit(1).first

      pareja1aux = ParejaAulasTemporal.where(["aula_id = ? AND tipo_hora_id = ? AND tipo_dia_id = ?", aul.aula_id, aul.tipo_hora_id, aul.tipo_dia_id]).limit(1).first
  
      pareja2aux = ParejaAulasTemporal.where(["pareja = ? AND tipo_dia_id != ?", pareja1aux.pareja,pareja1aux.tipo_dia_id]).limit(1).first

      if pareja2aux != nil
  
        pareja2 = BloqueAulaDisponible.where(["aula_id = ? AND tipo_hora_id = ? AND tipo_dia_id = ? AND asignada = ? ", pareja2aux.aula_id, pareja2aux.tipo_hora_id, pareja2aux.tipo_dia_id, 1]).limit(1).first

        if(pareja2 != nil)

			    indice_pareja = BloqueAulaDisponible.where(["asignada = ? AND tipo_dia_id != ?", 1, "SA"]).order("pareja DESC").limit(1).first
          num_nueva_pareja = indice_pareja.pareja + 1

					pareja1.pareja = num_nueva_pareja
					pareja2.pareja = num_nueva_pareja

					pareja1.save
					pareja2.save
        
        end
  
      else
        pareja1aux.destroy
      end

    }#endeach aulas_ya_emparejadas aul

    flash[:mensaje] = "Horarios Seleccionados con éxito, ahora por favor empareje las aulas"
    redirect_to(:action=>"emparejar_aulas_manualmente")

  end


	def emparejar_aulas_manualmente

    @titulo_pagina = "Emparejar Aulas" 
    @aulas_sin_pareja = BloqueAulaDisponible.where(["asignada = ? AND pareja = ? AND tipo_dia_id != ? ", 1, 0, "SA"]).sort_by{|x| "#{x.aula_id}-#{x.tipo_dia.orden}-#{x.tipo_hora_id}"}

    if @aulas_sin_pareja.empty?
      @mostrar_aulas_a_emparejar = false
      flash[:mensaje] = "Todas las aulas ya han sido emparejadas, proceso finalizado con éxito"
    else
      @mostrar_aulas_a_emparejar = true
    end
 
    @aulas_emparejadas = ParejaAulasTemporal.all.sort_by{|x| "#{x.pareja}-#{x.tipo_dia.orden}-#{x.tipo_hora_id}"}

    if(params[:pareja_aula] != nil)		
    
      aulas_emparejadas = []

  		aulas_emparejadas[0] = {:aula => nil, :dia => nil, :horario => nil}
  		aulas_emparejadas[1] = {:aula => nil, :dia => nil, :horario => nil}

			if(params[:pareja_aula][0].size != 2)

		  	flash[:mensaje] = "Debe marcar dos aulas"
				redirect_to(:action=>"emparejar_aulas_manualmente")

			else
		
				i = 0

				params[:pareja_aula][0].each {|aula,x|

					x.each{|dia, y|

						y.each{|horario, z|

							aulas_emparejadas[i]["aula"] = aula
							aulas_emparejadas[i]["dia"] = dia
							aulas_emparejadas[i]["horario"] = horario	

							i = i + 1

						}

					}

				}


				case aulas_emparejadas[0]["dia"]
					when "LU"
						dia1 = "MI"
					when "MI"
						dia1 = "LU"
					when "MA"
						dia1 = "JU"
					when "JU"
						dia1 = "MA"
				end #endcase

				case aulas_emparejadas[1]["dia"]
					when "LU"
						dia2 = "MI"
					when "MI"
						dia2 = "LU"
					when "MA"
						dia2 = "JU"
					when "JU"
						dia2 = "MA"
				end #endcase

				if(aulas_emparejadas[0]["horario"] == aulas_emparejadas[1]["horario"] && aulas_emparejadas[0]["dia"] == dia2 && aulas_emparejadas[1]["dia"] == dia1 )

					indice_pareja = BloqueAulaDisponible.where(["asignada = ? AND tipo_dia_id != ?", 1, "SA"]).order("pareja DESC").limit(1).first

					num_nueva_pareja = indice_pareja.pareja + 1

					
					aula_emparejada1 = BloqueAulaDisponible.where(["aula_id = ? AND tipo_hora_id = ? AND tipo_dia_id = ? AND asignada = ? ", aulas_emparejadas[0]["aula"], aulas_emparejadas[0]["horario"], aulas_emparejadas[0]["dia"], 1]).limit(1).first

					aula_emparejada1.pareja = num_nueva_pareja

					aula_emparejada1.save	

					pareja_aula_temporal = ParejaAulasTemporal.new
					pareja_aula_temporal.tipo_hora_id = aulas_emparejadas[0]["horario"]
					pareja_aula_temporal.tipo_dia_id = aulas_emparejadas[0]["dia"]
					pareja_aula_temporal.aula_id = aulas_emparejadas[0]["aula"]
          pareja_aula_temporal.pareja = num_nueva_pareja
					pareja_aula_temporal.save


					aula_emparejada2 = BloqueAulaDisponible.where(["aula_id = ? AND tipo_hora_id = ? AND tipo_dia_id = ? AND asignada = ? ", aulas_emparejadas[1]["aula"], aulas_emparejadas[1]["horario"], aulas_emparejadas[1]["dia"], 1]).limit(1).first

					aula_emparejada2.pareja = num_nueva_pareja

					aula_emparejada2.save	

          pareja_aula_temporal = ParejaAulasTemporal.new
					pareja_aula_temporal.tipo_hora_id = aulas_emparejadas[1]["horario"]
					pareja_aula_temporal.tipo_dia_id = aulas_emparejadas[1]["dia"]
					pareja_aula_temporal.aula_id = aulas_emparejadas[1]["aula"]
          pareja_aula_temporal.pareja = num_nueva_pareja
					pareja_aula_temporal.save

					flash[:mensaje] = "Aula emparejada con éxito"
					redirect_to(:action=>"emparejar_aulas_manualmente")

        else
					flash[:mensaje] = "Debe elegir las aulas en un mismo horario y en un día complementario"
					redirect_to(:action=>"emparejar_aulas_manualmente")				
				end				

			end #endif(params[:pareja_aula][0].size)
		
    else

			if params[:campo] != nil && !(@aulas_sin_pareja.empty?)
        flash[:mensaje] = "Debe marcar dos aulas, no puede dejar los checks vacíos"
      end

	  end

	end



  def confirmar_eliminar_pareja

    p=params[:parametros]

    pareja = p[:pareja]

	  @aula1 = ParejaAulasTemporal.where(["pareja = ? ", pareja]).limit(1).first

    @aula2 = ParejaAulasTemporal.where(["pareja = ? AND tipo_dia_id != ?", pareja,@aula1.tipo_dia_id]).limit(1).first

    render :layout => false
 
  end


  def eliminar_pareja

    pareja = params[:pareja]

    ParejaAulasTemporal.delete_all(['pareja = ?',pareja])

    aula1 = BloqueAulaDisponible.where(["aula_id = ? AND tipo_hora_id = ? AND tipo_dia_id = ? AND asignada = ? ", params[:aula_id], params[:tipo_hora],params[:tipo_dia], 1]).limit(1).first

    aula2 = BloqueAulaDisponible.where(["pareja = ? AND tipo_dia_id != ?", aula1.pareja,aula1.tipo_dia_id]).limit(1).first

    aula1.pareja = 0
    aula1.save

    aula2.pareja = 0
    aula2.save

    flash[:mensaje] = "Pareja eliminada con éxito"
    redirect_to(:action=>"emparejar_aulas_manualmente")

    #pareja_temporal1 = ParejaAulasTemporal.where(["pareja = ? ", pareja]).limit(1).first
    #pareja_temporal2 = ParejaAulasTemporal.where(["pareja = ? AND tipo_dia_id != ?", pareja,pareja_temporal1.tipo_dia_id]).limit(1).first

    #pareja_temporal.destroy

  end

  def eliminar
    @aula = Aula.find(params[:id])
    flash[:mensaje] = @aula.destroy ? "Aula Eliminada con éxito" : "El Aula no pudo ser eliminada"
    redirect_to(:controller => "admin_aula")

  end


end





