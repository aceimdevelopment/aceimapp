class TipoActividadesController < ApplicationController

  before_action :filtro_logueado
  before_action :filtro_administrador
  skip_before_action  :verify_authenticity_token 
  # GET /tipo_actividades
  # GET /tipo_actividades.json
  def index
    @tipo_actividades = TipoActividad.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @tipo_actividades }
    end
  end

  # GET /tipo_actividades/1
  # GET /tipo_actividades/1.json
  def show
    @tipo_actividad = TipoActividad.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @tipo_actividad }
    end
  end

  # GET /tipo_actividades/new
  # GET /tipo_actividades/new.json
  def new
    @tipo_actividad = TipoActividad.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @tipo_actividad }
    end
  end

  # GET /tipo_actividades/1/edit
  def edit
    @tipo_actividad = TipoActividad.find(params[:id])
  end

  # POST /tipo_actividades
  # POST /tipo_actividades.json
  def create
    @tipo_actividad = TipoActividad.new(params[:tipo_actividad])

    respond_to do |format|
      if @tipo_actividad.save
        format.html { redirect_to @tipo_actividad, :notice => 'Tipo Actividad creada satisfactoriamente.' }
        format.json { render :json => @tipo_actividad, :status => :created, :location => @tipo_actividad }
      else
        format.html { render :action => "new" }
        format.json { render :json => @tipo_actividad.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /tipo_actividades/1
  # PUT /tipo_actividades/1.json
  def update
    @tipo_actividad = TipoActividad.find(params[:id])

    respond_to do |format|
      if @tipo_actividad.update_attributes(params[:tipo_actividad])
        format.html { redirect_to @tipo_actividad, :notice => 'Tipo Activiadad actualizado satisfactoriamente.' }
        format.json { head :ok }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @tipo_actividad.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /tipo_actividades/1
  # DELETE /tipo_actividades/1.json
  def destroy
    @tipo_actividad = TipoActividad.find(params[:id])
    @tipo_actividad.destroy

    respond_to do |format|
      format.html { redirect_to tipo_actividades_url }
      format.json { head :ok }
    end
  end
end
