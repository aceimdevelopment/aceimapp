# encoding: utf-8

class ArchivosController < ApplicationController
  # GET /archivos
  # GET /archivos.json

  before_action :filtro_logueado
  before_action :filtro_administrador
  skip_before_action  :verify_authenticity_token

  def index
    #@archivos = Archivo.all


    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @archivos }
    end
  end

  # GET /archivos/1
  # GET /archivos/1.json
  def show
    @archivo = Archivo.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @archivo }
    end
  end

  # GET /archivos/new
  # GET /archivos/new.json
  def new
    @archivo = Archivo.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @archivo }
    end
  end

  # GET /archivos/1/edit
  def edit
    @archivo = Archivo.find(params[:id])
  end

  # POST /archivos
  # POST /archivos.json
  def create
    if params[:archivo][:upload_file]
      begin
        data = params[:archivo][:upload_file]
        url = "#{Rails.root}/attachments/archivos/#{data.original_filename}"
        data = data.tempfile
        File.open("#{url}", "wb") {|file| file.write data.read; file.close}
        params[:archivo][:url] = url
      rescue Exception => e
        flash[:mensaje] = "Error: #{e.message}"
      end
      params[:archivo].delete :upload_file
    else
      params[:archivo][:url] = "#{Rails.root}/attachments/archivos/"+params[:archivo][:url]
    end


    @archivo = Archivo.new(params[:archivo])

    respond_to do |format|
      if  @archivo.save
        format.html { redirect_to archivos_path+"##{@archivo.idioma_id}", flash: {mensaje: 'Archivo creado con éxito.'}}
        format.json { render json: @archivo, status: :created, location: @archivo }
      else
        format.html { render action: "new" }
        format.json { render json: @archivo.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /archivos/1
  # PUT /archivos/1.json
  def update

    params[:archivo][:url] = "#{Rails.root}/attachments/archivos/"+params[:archivo][:url]

    @archivo = Archivo.find(params[:id])

    respond_to do |format|
      if @archivo.update_attributes(params[:archivo])
        format.html { redirect_to archivos_path+"##{@archivo.idioma_id}", flash: {mensaje: 'Archivo actualizado con éxito.'} }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @archivo.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /archivos/1
  # DELETE /archivos/1.json
  def destroy
    @archivo = Archivo.find(params[:id])

    @idioma_id = @archivo.idioma_id

    begin
      File.delete(@archivo.url)
      flash[:mensaje] = "Archivo Eliminado del sistema."
    rescue Exception => e
      flash[:mensaje] = "Error al intentar eliminar. #{e.message}"
    end

    @archivo.destroy

    redirect_to archivos_path+"##{@idioma_id}"
  end
end
