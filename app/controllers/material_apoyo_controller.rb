class MaterialApoyoController < ApplicationController
  # GET /material_apoyos
  # GET /material_apoyos.json
  before_action :filtro_logueado
  before_action :filtro_administrador


  def index
    @material_apoyos = MaterialApoyo.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @material_apoyos }
    end
  end

  # GET /material_apoyos/1
  # GET /material_apoyos/1.json
  def show
    @material_apoyo = MaterialApoyo.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @material_apoyo }
    end
  end

  # GET /material_apoyos/new
  # GET /material_apoyos/new.json
  def new
    @material_apoyo = MaterialApoyo.new
    @cursos = Curso.where(:tipo_categoria_id => 'AD').order(:grado).delete_if{|c| c.tipo_nivel_id.eql? "CC" or c.tipo_nivel_id.eql? "NI" or c.tipo_nivel_id.eql? "BBVA";}.sort_by{|c| "#{c.idioma_id} #{c.grado}"}
    # @tipo_material_apoyo = all
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @material_apoyo }
    end
  end

  # GET /material_apoyos/1/edit
  def edit
    @material_apoyo = MaterialApoyo.find(params[:id])
    @cursos = Curso.where(:tipo_categoria_id => 'AD').order(:grado).delete_if{|c| c.tipo_nivel_id.eql? "CC" or c.tipo_nivel_id.eql? "NI" or c.tipo_nivel_id.eql? "BBVA";}.sort_by{|c| "#{c.idioma_id} #{c.grado}"}    
  end

  # POST /material_apoyos
  # POST /material_apoyos.json
  def create
    @material_apoyo = MaterialApoyo.new(params[:material_apoyo])
    begin
      data = params[:archivo][:datafile]
      ext = data.original_filename.split('.').last
      nombre = "material_apoyo_#{@material_apoyo.id}.#{ext}"
      archivo = "#{Rails.root}/attachments/material_apoyo/#{nombre}"

      @material_apoyo.nombre = nombre
      @material_apoyo.tipo_material_apoyo_id = 'TEXT'
      @material_apoyo.nombre_original = data.original_filename
      @material_apoyo.url = archivo
      data = data.tempfile
      File.open("#{archivo}", "wb") {|file| file.write data.read; file.close}
      if @material_apoyo.save
        flash[:mensaje] += "Material de apoyo Agregado"
        params[:cursos_ids].each_key do |curso_id| 
          idioma_id,tipo_categoria_id,tipo_nivel_id = curso_id.split ","
          MaterialApoyoCurso.create(:material_apoyo_id => @material_apoyo.id, :curso_idioma_id => idioma_id, :curso_tipo_categoria_id => tipo_categoria_id, :curso_tipo_nivel_id => tipo_nivel_id)
        end
      end 
    rescue Exception => e
      flash[:mensaje] = "Error: #{e.message}"
    end
    redirect_to :action => 'index'
  end

  # PUT /material_apoyos/1
  # PUT /material_apoyos/1.json
  def update
    @material_apoyo = MaterialApoyo.find(params[:id])

    respond_to do |format|
      if @material_apoyo.update_attributes(params[:material_apoyo])
        format.html { redirect_to @material_apoyo, notice: 'Material apoyo was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @material_apoyo.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /material_apoyos/1
  # DELETE /material_apoyos/1.json
  def destroy
    @material_apoyo = MaterialApoyo.find(params[:id])

    begin
      File.delete(@material_apoyo.url)
      @material_apoyo.destroy
      flash[:mensaje] = "Archivo Eliminado del sistema."
    rescue Exception => e
      flash[:mensaje] = "Error al intentar eliminar. #{e.message}"
    end
    respond_to do |format|
      format.html { redirect_to material_apoyos_url }
      format.json { head :ok }
    end
  end
end
