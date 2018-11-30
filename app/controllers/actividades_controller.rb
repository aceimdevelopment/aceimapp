# encoding: utf-8

class ActividadesController < ApplicationController
  before_action :filtro_logueado
  before_action :filtro_administrador
  skip_before_action  :verify_authenticity_token  

  # GET /actividades
  # GET /actividades.json
  def index
    @actividades = Actividad.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @actividades }
    end
  end

  # GET /actividads/1
  # GET /actividads/1.json
  def show
    @actividad = Actividad.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @actividad }
    end
  end

  # GET /actividads/new
  # GET /actividads/new.json
  def new
    @actividad = Actividad.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @actividad }
    end
  end

  # GET /actividads/1/edit
  def edit
    @actividad = Actividad.find(params[:id])
  end

  # POST /actividads
  # POST /actividads.json
  def create
    1/0
    if params[:parte_examen_id]
      @parte_examen = ParteExamen.find(params[:parte_examen_id])
      @actividad = @parte_examen.actividades.create(params[:actividad])
    else
      @actividad = Actividad.new(params[:actividad])      
    end
    respond_to do |format|
      if @actividad.save
        # if params[:examen_id]
          flash[:mensaje] = 'Actividad creado con éxito.'
          format.html { redirect_to :controller => "admin_examenes", :action => "wizard_paso2", :id => @examen.id}
        # else
          # format.html { redirect_to examen_path(@examen), :notice => 'actividad was successfully created.' }          

          format.json { render :json => @examen, :status => :created, :location => @examen }
      else
        # accion = params[:examen_id] ? "admin_examenes/wizard_paso2/#{@examen.id}" : 'new'
        format.html { render :action => 'new' }
        format.json { render :json => @actividad.errors, :status => :unprocessable_entity }
      end
    end
  end


  # def actualizar_actividad
  #   @actividad = Actividad.find(params[:id])
  #   if @actividad.update_attributes(params[:actividad])
  #     flash[:mensaje] = "Datos elementales de la actividad actualizados"
  #   else
  #     flash[:mensaje] = "No se pudo actualizar los datos de la actividad"
  #   end
  #   redirect_to :back
  # end

  # def eliminar_actividad
  #   @actividad = Actividad.find(params[:id])
  #   flash[:mensaje] = "Actividad Eliminada con éxito" if @actividad.destroy

  #   redirect_to :back
  # end



  # PUT /actividades/1
  # PUT /actividades/1.json
  def update

    @actividad = Actividad.find(params[:id])
    if @actividad.update_attributes(params[:actividad])
      info_bitacora "Usuario: #{session[:usuario].ci} actualizó datos elementales de la actividad #{@actividad.id} actualizados."
      flash[:mensaje] = "Instrucciones de la actividad actualizados"
    else
      flash[:mensaje] = "No se pudo actualizar los datos de la actividad"
    end
    redirect_to :back
  end

  # DELETE /actividades/1
  # DELETE /actividades/1.json
  def destroy
    @actividad = Actividad.find(params[:id])
    actividad_id = @actividad.id
    if @actividad.destroy
      info_bitacora "Usuario: #{session[:usuario].ci} eliminó actividad #{actividad_id}."
      flash[:mensaje] = "Actividad Eliminada con éxito" 
    end

    redirect_to :back 
  end
end
