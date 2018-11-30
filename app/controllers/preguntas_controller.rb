# encoding: utf-8

class PreguntasController < ApplicationController
  before_action :filtro_logueado
  before_action :filtro_administrador
  skip_before_action  :verify_authenticity_token  

  # GET /preguntas
  # GET /preguntas.json
  def index
    @preguntas = Pregunta.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @preguntas }
    end
  end

  # GET /preguntas/1
  # GET /preguntas/1.json
  def show
    @pregunta = Pregunta.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @pregunta }
    end
  end

  # GET /preguntas/new
  # GET /preguntas/new.json
  def new
    @pregunta = Pregunta.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @pregunta }
    end
  end

  # GET /preguntas/1/edit
  def edit
    @pregunta = Pregunta.find(params[:id])
  end

  # POST /preguntas
  # POST /preguntas.json
  def create

    if params[:actividad_id]    
      @actividad = actividad.find(params[:actividad_id])
      @pregunta = @actividad.preguntas.create(params[:pregunta])
    else
      @pregunta = Pregunta.new(params[:pregunta])
    end

    respond_to do |format|
      if @pregunta.save
          flash[:mensaje] = 'Pregunta agregada con éxito.'
          format.html { redirect_to :controller => "examenes", :action => "wizard_paso2", :id => @actividad.examen.id}

        # format.html { redirect_to @pregunta, :notice => 'Pregunta was successfully created.' }
        # format.json { render :json => @pregunta, :status => :created, :location => @pregunta }
      else
        format.html { render :action => "new" }
        format.json { render :json => @pregunta.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /preguntas/1
  # PUT /preguntas/1.json
  def update
    @pregunta = Pregunta.find(params[:id])

    respond_to do |format|
      if @pregunta.update_attributes(params[:pregunta])
        format.html { redirect_to @pregunta, :notice => 'Pregunta was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @pregunta.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /preguntas/1
  # DELETE /preguntas/1.json
  def destroy
    @pregunta = Pregunta.find(params[:id])
    @pregunta.destroy

    respond_to do |format|
      format.html { redirect_to preguntas_url }
      format.json { head :ok }
    end
  end

  def agregar_sel_multiple
    opciones = params[:opciones]
    # params[:respuesta][:valor] = params[:respuesta][:valor].downcase
    # opciones.each {|op| op.downcase}
    respuesta = params[:respuesta]

    puts "Opciones: <#{opciones.to_s}>"

    puts "Respuesta: #{respuesta[:valor]}"

    esta = false
    # REVISAR LA CREACION DE PREGUNTAS Y RESPUESTAS. VER LA SALIDA CONSOLA (PUT) MENSAJE PARA DETALLES 
    opciones.each{|opc| esta = true if opc.casecmp(respuesta[:valor]).zero?}

    if esta
      valor = params[:pregunta][:valor]
      @pregunta = Pregunta.new(params[:pregunta])
      if @pregunta.save
        flash[:mensaje] = "Pregunta Agregada satisfactoriamente."

        opc_count = 0
        opciones.each do |opc|
          opc_count += 1 if @pregunta.opciones.create(:valor => opc)
        end
        flash[:mensaje] += "#{opc_count} opciones agregadas."
        if @pregunta.respuestas.create(respuesta)
          flash[:mensaje] += "Respuesta correcta agregadas."
        else
          flash[:mensaje] = "Error al intentar cargar la repuesta. Por favor revise los campos e inténtelo nuevamente."
        end

      else
        flash[:mensaje] = "No se pudo agregar la pregunta: #{@pregunta.errors.full_messages.join('-')}."
      end
    else
      flash[:mensaje] = "La respuesta no se encuentra entre las opciones. Por favor verifique la respuesta e inténtelo nuevamente."
    end
    # puts "------------------------------------------------------------------------------"
    # puts "------------------------------------------------------------------------------"
    # puts "------------------------------------------------------------------------------"

    # puts "Mensaje: #{flash[:mensaje]}"

    # puts "------------------------------------------------------------------------------"
    # puts "------------------------------------------------------------------------------"
    # puts "------------------------------------------------------------------------------"

    redirect_to :controller => 'examenes', :action => 'wizard_paso2', :id => params[:examen_id]
    # redirect_to :back
  end


  def agregar_completacion
    respuestas = params[:respuestas]

    pregunta = Pregunta.new(params[:pregunta])

    if pregunta.save
      flash[:mensaje] = "Pregunta Agregada satisfactoriamente."
      agregadas = 0
      respuestas.each do |respuesta|
        respuesta = Respuesta.new respuesta

        respuesta.pregunta_id = pregunta.id

        agregadas += 1 if respuesta.save
      end
      flash[:mensaje] += "#{agregadas} respuestas agregadas."
    else
      flash[:mensaje] = "No se pudo agregar la pregunta: #{pregunta.errors.full_messages.join('-')}."
    end

    redirect_to :controller => 'examenes', :action => 'wizard_paso2', :id => params[:examen_id]

  end

  def actualizar_respuesta
    @examen = Examen.find(params[:examen_id])
    @respuesta = Respuesta.find(params[:id])

    if params[:opciones]
      opciones = params[:opciones]

      opciones.each do |opcion|
        @opcion = Opcion.find opcion[0]
        @opcion.update_attribute :valor, opcion[1]
      end 
    end

    @respuesta.update_attributes params[:respuesta]
    respond_to do |format|
      format.html {redirect_to :back}
      format.js
    end
  end


  def actualizar_valor_pregunta
    @examen = Examen.find(params[:examen_id])
    @pregunta = Pregunta.find(params[:id])
    @pregunta.update_attribute :valor, params[:valor]
    info_bitacora "Usuario: #{session[:usuario].ci} actualizó la pregunta #{@pregunta.id} con valor: #{params[:valor]}"
    respond_to do |format|
      format.html {redirect_to :back}
      format.js
    end
  end

  def validar_respuesta
    # @examen = Examen.find params[:examen_id]
    @respuesta = Respuesta.find params[:respuesta][:id]
    params[:respuesta][:valor] = limpiar_string params[:respuesta][:valor]
    @correcta = "Incorrecta"
    @correcta = "Correcta" if @respuesta.correcta? params[:respuesta][:valor]

    respond_to do |format|
      format.html {redirect_to :back}
      format.js
    end
  end



end
