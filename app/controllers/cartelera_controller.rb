class CarteleraController < ApplicationController

	def show
		@cartelera = ContenidoWeb.where(:id => 'INI_CONTENT').first
		# @cartelera = ParametroGeneral.find 'CARTELERA'
	end

	def edit
		@cartelera = ContenidoWeb.where(:id => 'INI_CONTENT').first
		# @cartelera = ParametroGeneral.find 'CARTELERA'
	end

	def save
		@cartelera = ContenidoWeb.where(:id => 'INI_CONTENT').first
		# cartelera = ParametroGeneral.find 'CARTELERA'
		@cartelera.update(contenido: params[:text])
		redirect_to action: 'show'		
	end

end
