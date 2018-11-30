# encoding: utf-8

class ConvenioController < ApplicationController
  before_action :filtro_logueado 
  before_action :filtro_super_administrador 
  
  def index
    @titulo_pagina = "Actualizar la Matricula de los Cursos" 
    @precios = TipoConvenio.find(:all)
    @precio_planilla = ParametroGeneral.find("COSTO_PLANILLA").valor.to_f
    @precio_nuevos = ParametroGeneral.find("COSTO_NUEVOS").valor.to_f
    @precio_examen = ParametroGeneral.find("COSTO_EXAMEN").valor.to_f
    @precio_ninos = ParametroGeneral.find("COSTO_NINOS").valor.to_f

  end


  def nuevo
    @titulo_pagina = "Agregar Tipo de Convenio" 
    @convenio = TipoConvenio.new
  end


  def nuevo_guardar

    id = params[:tipo_convenio][:id]

    if TipoConvenio.where(:id=>id).limit(1).first
      flash[:mensaje] = "El Convenio ya existe"
      redirect_to :action => "nuevo"
      return
    end 

    @convenio = TipoConvenio.new
    @convenio.id = id
    @convenio.descripcion = params[:tipo_convenio][:descripcion]
    @convenio.descuento = params[:tipo_convenio][:descuento]

    precio_planilla = ParametroGeneral.find("COSTO_PLANILLA").valor.to_f
    monto_base=TipoConvenio.where(:id=>"REG").limit(1).first.monto.to_f - precio_planilla
    @convenio.monto = monto_base - (monto_base * @convenio.descuento.to_f/100) + precio_planilla 

    respond_to do |format|
      if @convenio.save
        info_bitacora("Nueva Convenio Agregado: #{id}")
        flash[:mensaje] = "Nuevo convenio registrado satisfactoriamente"
        format.html { redirect_to(:action=>"index") }
      else
        flash[:mensaje] = "Errores en el formulario impiden que el convenio sea registrado"
        format.html { render :action => "nuevo" }
        @convenio.id = params[:tipo_convenio][:id]
        format.xml  { render :xml => @convenio.errors, :status => :unprocessable_entity }
      end
    end

  end


  def modificar

    id = params[:parametros][:id]
    precio_planilla = ParametroGeneral.find("COSTO_PLANILLA").valor.to_f
    @convenio = TipoConvenio.find(id)
    @convenio.monto = @convenio.monto - precio_planilla 
    render :layout => false   

  end


  def modificar_guardar

    id = params[:tipo_convenio][:id]
    precio_planilla = ParametroGeneral.find("COSTO_PLANILLA").valor.to_f

    @convenio=TipoConvenio.where(:id=>id).limit(1).first
    @convenio.descripcion = params[:tipo_convenio][:descripcion]
    @convenio.monto = params[:tipo_convenio][:monto].to_f + precio_planilla
    @convenio.descuento = params[:tipo_convenio][:descuento]

    convenios = TipoConvenio.find(:all)

    respond_to do |format|
      if @convenio.save

        @convenio=TipoConvenio.where(:id=>"REG").limit(1).first
        monto =  @convenio.monto.to_f - precio_planilla

        convenios.each do |c|

          @convenio=TipoConvenio.where(:id=>c.id).limit(1).first

					if(c.id!="EXO")
            @convenio.monto = monto - (monto * @convenio.descuento.to_f/100) + precio_planilla
            @convenio.save
          end

       
        end #endeach

        flash[:mensaje] = "Convenio actualizado satisfactoriamente"
        format.html { redirect_to(:action=>"index") }

      else

        flash[:mensaje] = "Errores en el Formulario impiden que el convenio sea actualizado"
        format.html { render :action => "modificar" }
        @convenio.id = params[:tipo_convenio][:id]
        format.xml  { render :xml => @convenio.errors, :status => :unprocessable_entity }
      end
    end
    
  end


  def modificar_monto_planilla
    @precio_planilla = ParametroGeneral.find("COSTO_PLANILLA")
    render :layout => false   
  end

  def modificar_monto_examen
    @precio_planilla = ParametroGeneral.find("COSTO_EXAMEN")
    render :layout => false   
  end

  def modificar_monto_nuevos
    @precio_planilla = ParametroGeneral.find("COSTO_NUEVOS")
    render :layout => false   
  end

  def modificar_monto_ninos
    @precio_planilla = ParametroGeneral.find("COSTO_NINOS")
    render :layout => false   
  end

  def guardar_monto_planilla

		id = params[:parametro_general][:id]

		#Se obtiene el precio anterior de la planilla
		@planilla = ParametroGeneral.where(:id=>id).limit(1).first
		precio_viejo = @planilla.valor.to_f
		
		#Se almacena el nuevo precio
    @planilla.valor = params[:parametro_general][:valor]

    respond_to do |format|
      if @planilla.save

				#Se obtiene el monto del convenio general
				@convenio=TipoConvenio.where(:id=>"REG").limit(1).first
   			monto =  @convenio.monto.to_f - precio_viejo
			
				convenios = TipoConvenio.find(:all)
				#Se obtiene el nuevo monto de la planilla
				precio_planilla = @planilla.valor.to_f
				
				#Se procede a actualizar todos los nuevos montos en base al nuevo monto de la planilla
				convenios.each do |c|
			 		@convenio=TipoConvenio.where(:id=>c.id).limit(1).first
					if(c.id!="EXO")
			 			@convenio.monto = monto - (monto * @convenio.descuento.to_f/100) + precio_planilla
					end			 		
					@convenio.save
				end #endeach
				
        info_bitacora("Monto de la Planilla Actualizado: #{id}")
        flash[:mensaje] = "Monto de la planilla actualizado satisfactoriamente"
        format.html { redirect_to(:action=>"index") }
      else
        flash[:mensaje] = "Errores en el formulario impiden que el convenio sea registrado"
        format.html { render :action => "modificar_monto_planilla" }
        @planilla.id = params[:parametro_general][:id]
        format.xml  { render :xml => @planilla.errors, :status => :unprocessable_entity }
      end
    end

  end

  def guardar_monto_examen

    id = params[:parametro_general][:id]

    #Se obtiene el precio anterior de la planilla
    @planilla = ParametroGeneral.where(:id=>id).limit(1).first
    precio_viejo = @planilla.valor.to_f
    
    #Se almacena el nuevo precio
    @planilla.valor = params[:parametro_general][:valor]

    @planilla.save

    info_bitacora("Monto del examen Actualizado: #{id}")
    flash[:mensaje] = "Monto del examen actualizado satisfactoriamente"
    redirect_to(:action=>"index")
  end

 def guardar_monto_nuevos

    id = params[:parametro_general][:id]

    #Se obtiene el precio anterior de la planilla
    @planilla = ParametroGeneral.where(:id=>id).limit(1).first
    precio_viejo = @planilla.valor.to_f
    
    #Se almacena el nuevo precio
    @planilla.valor = params[:parametro_general][:valor]

    @planilla.save

    info_bitacora("Monto de los nuevos Actualizado: #{id}")
    flash[:mensaje] = "Monto de los nuevos actualizado satisfactoriamente"
    redirect_to(:action=>"index")
  end	

 def guardar_monto_ninos

    id = params[:parametro_general][:id]

    #Se obtiene el precio anterior de la planilla
    @planilla = ParametroGeneral.where(:id=>id).limit(1).first
    precio_viejo = @planilla.valor.to_f
    
    #Se almacena el nuevo precio
    @planilla.valor = params[:parametro_general][:valor]

    @planilla.save

    info_bitacora("Monto de los niños Actualizado de: <#{precio_viejo}> a <#{@planilla.valor}> con id:#{id}")
    flash[:mensaje] = "Monto de los niños actualizado satisfactoriamente"
    redirect_to(:action=>"index")
  end
  
  
end
