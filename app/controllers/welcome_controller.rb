class WelcomeController < ApplicationController

	def index
		@cartelera = GeneralParameter.find 'CARTELERA'
	end

	def cartelera
		@cartelera = GeneralParameter.find 'CARTELERA'
	end

	def guardar_cartelera
		cartelera = GeneralParameter.find 'CARTELERA'
		cartelera.update(value: params[:text])

		redirect_to action: 'index'
		
	end

end
