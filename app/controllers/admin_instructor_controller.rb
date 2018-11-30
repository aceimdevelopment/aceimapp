# encoding: utf-8

class AdminInstructorController < ApplicationController
  before_action :filtro_logueado
  before_action :filtro_administrador


  def index
    @periodo_actual = ParametroGeneral.periodo_actual 
    @titulo_pagina = "Listado de Instructores"  
    @instructores = Instructor.all.sort_by{|x| x.usuario.nombre_completo}

    @instructor_con_cursos_periodo_actual = Instructor.all.delete_if{|instructor| instructor.secciones_que_dicta(@periodo_actual.id).count < 1}
    @instructor_sin_cursos_periodo_actual = Instructor.all.delete_if{|instructor| instructor.secciones_que_dicta(@periodo_actual.id).count > 0}
    @instructores_tabs = ["actual", "otros"]

  end

  def nuevo
    if session[:administrador].tipo_rol_id > 3 
      flash[:mensaje] = "Usted no posee los privilegios para acceder a esta función"
      redirect_to :action => 'index'
    end
    @titulo_pagina = "Agregar instructor" 
    @usuario = Usuario.new

  end

  def nuevo_guardar 
    ci = params[:usuario][:ci]
    
		@instructor = Instructor.where(:usuario_ci=>ci).limit(1).first
		@usuario = Usuario.where(:ci=>ci).limit(1).first
    if @instructor 
      flash[:mensaje] = "El usuario ya existia"
      redirect_to :action => "index"
      return
    end                       

    unless @usuario
      @usuario = Usuario.new
      @usuario.ci = ci   
    end

    @usuario.nombres = params[:usuario][:nombres]
    @usuario.apellidos = params[:usuario][:apellidos]
    @usuario.correo = params[:usuario][:correo]
    @usuario.tipo_sexo_id = params[:usuario][:tipo_sexo_id]
    @usuario.fecha_nacimiento = "1990-01-01"
    @usuario.contrasena = @usuario.ci
    @usuario.telefono_habitacion = params[:usuario][:telefono_habitacion]
    @usuario.telefono_movil  = params[:usuario][:telefono_movil]
    @usuario.contrasena = ci
    
    if @usuario.save 
      unless @instructor
        @instructor = Instructor.new
        @instructor.usuario_ci = ci
        @instructor.save

				bloque_horario = BloqueHorario.all
				bloque_horario.each{|bh|
					horario_disponible_instructor = HorarioDisponibleInstructor.new
					horario_disponible_instructor.instructor_ci = ci
					horario_disponible_instructor.idioma_id = "OR"
					horario_disponible_instructor.bloque_horario_id = bh.id
					horario_disponible_instructor.save
				}

      end
  	  flash[:mensaje]="Instructor agregado satisfactoriamente" 
  	  redirect_to :action => "index"
  	  return
  	else    
  	  render :action => "nuevo"
	  end
  end

  def modificar
    if session[:administrador].tipo_rol_id > 3 
      flash[:mensaje] = "Usted no posee los privilegios para acceder a esta función"
      redirect_to :action => 'index'
    end 
    @titulo_pagina = "Modificar instructor" 
    session[:instructor_ci] = params[:ci] if params[:ci]
    @usuario = Usuario.find(session[:instructor_ci])
    
  end
  
  def modificar_guardar 
    usr = params[:usuario]
    @usuario = Usuario.where(:ci=>usr[:ci]).limit(1).first
    @usuario.nombres = usr[:nombres]
    @usuario.apellidos = usr[:apellidos]
    @usuario.tipo_sexo_id = usr[:tipo_sexo_id]
    @usuario.fecha_nacimiento = usr[:fecha_nacimiento]
    @usuario.correo = usr[:correo]
    @usuario.telefono_movil = usr[:telefono_movil]
    @usuario.telefono_habitacion = usr[:telefono_habitacion]
    @usuario.direccion = usr[:direccion]
	
		respond_to do |format|
      if @usuario.save
        flash[:mensaje] = "Instructor Actualizado Satisfactoriamente"
        format.html { redirect_to(:action=>"index") }
      else
        format.html { render :action => "modificar" }
        format.xml  { render :xml => @usuario.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  
  def secciones
    ci = params[:ci]
    periodo_actual = ParametroGeneral.periodo_actual
    @secciones = Seccion.where(:periodo_id=>periodo_actual.id,:instructor_ci=>ci)
    @titulo_pagina = "Secciones de: #{Usuario.where(:ci=>ci).limit(1).first.descripcion}" 
  end

  
  def generar_pdf_instructor
    
    if pdf = DocumentosPDF.generar_listado_instructores(false)
      periodo_actual = ParametroGeneral.periodo_actual
      send_data pdf.render,:filename => "Instructores_periodo_#{periodo_actual.id}.pdf",:type => "application/pdf", :disposition => "attachment"
    end
    
  end
  
  def generar_xls_instructor
    DocumentosPDF.generar_listado_instructores_xls
  end


	def ingresar_horario_disponible_instructores

 		@titulo_pagina = "Ingresar Horarios Disponibles de los Instructores" 

		@idiomas = Idioma.select("idioma.*,tipo_curso.*").joins(:tipo_curso).where(["id != ? and tipo_curso.tipo_categoria_id NOT IN (?)", "OR",["BBVA","NI","TE"]])

		@bloques_horarios = BloqueHorario.all

		@cant_horarios = @bloques_horarios.size

    @instructores_disponibles = HorarioDisponibleInstructor.select("instructor.*,horario_disponible_instructor.*").joins("INNER JOIN instructor ON instructor.usuario_ci = horario_disponible_instructor.instructor_ci").where(["instructor.asignado = ?", 1]).order("horario_disponible_instructor.idioma_id ASC, horario_disponible_instructor.instructor_ci ASC, horario_disponible_instructor.bloque_horario_id ASC")

		@tipos_curso = @instructores_disponibles .collect{|y| y.idioma}.uniq

	end


	def guardar_horario_disponible_instructores

		if(params[:horarios_instructor] != nil)

		  instructor_ci = params[:instructor][:ci]

	  	idioma_id = params[:instructor][:idioma]

			instructor = Instructor.find(instructor_ci)
			instructor.asignado = 1
			instructor.save
      entrar = "SI"
      
			horario_disponible_instructor = HorarioDisponibleInstructor.where(["instructor_ci = ? and idioma_id = ?",instructor_ci,"OR"]).first

			if(horario_disponible_instructor.nil?)

				horario_disponible_instructor = HorarioDisponibleInstructor.where(["instructor_ci = ? and idioma_id = ?",instructor_ci,idioma_id]).first

				if(horario_disponible_instructor.nil?)
        	bloque_horario = BloqueHorario.all
					bloque_horario.each{|bh|
						horario_disponible_instructor = HorarioDisponibleInstructor.new
						horario_disponible_instructor.instructor_ci = instructor_ci
						horario_disponible_instructor.idioma_id = idioma_id
						horario_disponible_instructor.bloque_horario_id = bh.id
						horario_disponible_instructor.save
					}
				else
          flash[:mensaje] = "El instructor ya había sido asociado al idioma seleccionado, revise la tabla inferior"
      	  entrar = "NO" 
        end

      else
				HorarioDisponibleInstructor.update_all({:idioma_id => idioma_id},['instructor_ci = ?',instructor_ci])   
      end
  
      if entrar == "SI"
 			  params[:horarios_instructor].each{|hi|
	
				  horario_disponible_instructor = HorarioDisponibleInstructor.where(["instructor_ci = ? and idioma_id = ? and bloque_horario_id = ?",instructor_ci,idioma_id,hi.at(0)]).first
				  horario_disponible_instructor.disponible = 1
				  horario_disponible_instructor.save

			  }
		
		    flash[:mensaje] = "Horarios del instructor almacenadas con éxito"
      end

  	  redirect_to(:action=>"ingresar_horario_disponible_instructores")

		else
		
			flash[:mensaje] = "Debe elegir al menos un horario"
  	  redirect_to(:action=>"ingresar_horario_disponible_instructores")				
	
		end

	end

	def modal_modificar_horario_disponible_instructores
    @p = params[:parametros]
    @ci = @p[:ci]
    @idioma = @p[:idioma]

		@bloques_horarios = BloqueHorario.all
		@cant_horarios = @bloques_horarios.size

    @horarios_disponibles = HorarioDisponibleInstructor.select("instructor.*,horario_disponible_instructor.*").joins("INNER JOIN instructor ON instructor.usuario_ci = horario_disponible_instructor.instructor_ci").where(["horario_disponible_instructor.instructor_ci = ? AND horario_disponible_instructor.idioma_id = ?", @ci, @idioma ]).order("horario_disponible_instructor.bloque_horario_id ASC")

    render :layout => false
	end



  def cambiar_instructor_guardar
    
    instructor_ci = params[:ci]
    idioma_id = params[:idioma_id]

    if params[:horarios_instructor] != nil
    
      params[:horarios_instructor].each{|hi|
	
				horario_disponible_instructor = HorarioDisponibleInstructor.where(["instructor_ci = ? and idioma_id = ? and bloque_horario_id = ?",instructor_ci,idioma_id,hi.at(0)]).first
				horario_disponible_instructor.disponible = 1
				horario_disponible_instructor.save

			}
		
		  flash[:mensaje] = "Horarios del instructor almacenadas con éxito"
      
    else

      HorarioDisponibleInstructor.update_all({:disponible => 0},['instructor_ci = ? and idioma_id = ?',instructor_ci,idioma_id])
      
      tiene_otros_idiomas = HorarioDisponibleInstructor.where(['instructor_ci = ? and disponible = ?',instructor_ci,1]).first

      if(tiene_otros_idiomas.nil?)
        instructor = Instructor.find(instructor_ci)
			  instructor.asignado = 0
			  instructor.save

        HorarioDisponibleInstructor.update_all({:idioma_id => "OR"},['instructor_ci = ? and idioma_id = ?',instructor_ci,idioma_id])
      else
        HorarioDisponibleInstructor.delete_all(['instructor_ci = ? and idioma_id = ?',instructor_ci,idioma_id])   
      end        

      flash[:mensaje] = "Instructor Actualizado Exitosamente"

    end
  
    redirect_to(:action=>"ingresar_horario_disponible_instructores") 
 
  end

  
end

