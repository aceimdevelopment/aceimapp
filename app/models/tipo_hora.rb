# encoding: utf-8

#creada por db2models
class TipoHora < ApplicationRecord


  def descripcion_hora

    hora = "#{hora_entrada.strftime("%l")} - #{hora_salida.strftime("%l")}"

    return hora

  end


  def descripcion_hora2


    hora = " #{hora_entrada.strftime("%I:%M%p")} - #{hora_salida.strftime("%I:%M%p")}"

    return hora

  end


end
