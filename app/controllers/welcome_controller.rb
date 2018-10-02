class WelcomeController < ApplicationController

	def index
		@cartelera = ParametroGeneral.find 'CARTELERA'
	end

	def cartelera
		@cartelera = ParametroGeneral.find 'CARTELERA'
	end

	def guardar_cartelera
		cartelera = ParametroGeneral.find 'CARTELERA'
		cartelera.update(valor: params[:text])

		redirect_to action: 'index'
		
	end

end
