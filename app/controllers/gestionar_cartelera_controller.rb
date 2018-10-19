#encoding: utf-8

class GestionarCarteleraController < ApplicationController

  def index
    redirect_to :action => "modificar", :controller => "gestionar_cartelera"
  end

  def modificar
    @content = ContenidoWeb.where(:id => 'INI_CONTENT').first
  end

  def guardar
    content = params[:content]
    reg = ContenidoWeb.where(:id => 'INI_CONTENT').first
    reg.contenido = content
    reg.save
		flash[:mensaje] = "Cartelera modificada con éxito: Vista Preliminar"
    redirect_to :action => "visualizar", :controller => "gestionar_cartelera"
  end

  def visualizar
    @content = ContenidoWeb.where(:id => 'INI_CONTENT').first  
		render :layout => 'visitante'
	end

end
