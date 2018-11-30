# encoding: utf-8

class ClientesController < ApplicationController
  before_action :filtro_logueado
  before_action :filtro_administrador

  def index
    @clientes = Cliente.all
    @titulo_pagina = "Lista de clientes"
    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @clientes }
    end
  end

  def ver
    @cliente = Cliente.find(params[:id])
    respond_to do |format|
      format.json { render :json => @cliente}
    end
    return
  end

  def nuevo
    @cliente = Cliente.new
    @titulo_pagina = "Nuevo Cliente"
    @accion = "registrar"
    render :layout => false 
  end


  def editar
    @controlador = params[:parametros][:controlador] if params[:parametros]
    @accion = "actualizar"
    @titulo_pagina = "Edicción de Cliente"
    @cliente = Cliente.find(params[:id])
    render :layout => false 

  end


  def registrar
    params[:cliente][:rif] = (params[:cliente][:rif]).upcase 
    @cliente = Cliente.new(params[:cliente])

    respond_to do |format|
      if @cliente.save
        flash[:mensaje] = 'Cliente registrado'
        session[:cliente_id] = @cliente.id
        format.html { redirect_to :controller => 'facturas', :action => 'nueva' }
        format.json { render :json => @cliente, :status => :created, :location => @cliente }
      else
        @titulo_pagina = "Nuevo Cliente"
        @accion = "registrar"
        flash[:mensaje] = "#{@cliente.errors.count} error(es) impide(n) que el cliente sea registrado: #{@cliente.errors.full_messages.join(". ")}."
        session[:cliente_id] = nil
        format.html  { redirect_to :controller => 'facturas', :action => 'nueva' }
        format.json { render :json => @cliente.errors, :status => :unprocessable_entity }
      end
    end
  end

  def actualizar
    @cliente = Cliente.find(params[:id])
    
    respond_to do |format|
      if @cliente.update_attributes(params[:cliente])
        flash[:mensaje] = 'Cliente actualizado'
        
        session[:cliente_id] = @cliente.id
        controlador_retorno = params[:controlador] ? params[:controlador] : 'facturas' 
        format.html { redirect_to :controller => controlador_retorno}
        format.json { head :ok }
      else
        @titulo_pagina = "Edicción de Cliente"
        @accion = "actualizar"
        flash[:mensaje] = "#{@cliente.errors.count} error(es) impide(n) que el cliente sea actualizado: #{@cliente.errors.full_messages.join(". ")}."
        format.html { redirect_to :controller => 'facturas', :action => 'nueva' }
        format.json { render :json => @cliente.errors, :status => :unprocessable_entity }
      end
    end
  end

  def detalle
    @titulo_pagina = "Detalle Cliente"
    @cliente = Cliente.find(params[:id])

  end
  # def eliminar
  #   @cliente = Cliente.find(params[:id])
  #   @cliente.destroy

  #   respond_to do |format|
  #     format.html { redirect_to clientes_url }
  #     format.json { head :ok }
  #   end
  # end
end
