class PlanificacionController < ApplicationController
  before_action :filtro_logueado
  before_action :filtro_super_administrador

  def index

  @titulo_pagina = "Opciones del SuperAdministrador"

  end

  
end
