# encoding: utf-8

class DetalleFacturasController < ApplicationController
  before_action :filtro_logueado
  before_action :filtro_administrador

  def create

  	@factura = Factura.find(params[:factura_id])
  	parametros = params[:detalle_factura]

  	cantidad = parametros[:cantidad]

  	costo_unitario = parametros[:costo_unitario]

  	parametros[:total] = cantidad.to_f*costo_unitario.to_f


    # if(!parametros[:idioma_id].kind_of?(String))
    #   idioma_id, categoria_id = parametros[:idioma_id].join.split("-")
    # else
    #   idioma_id, categoria_id = parametros[:idioma_id].split("-")
    # end

    # parametros[:idioma_id] = idioma_id
    # parametros[:tipo_categoria_id] = categoria_id


    begin
      @detalle_factura = @factura.detalle_facturas.create(parametros)
    rescue
      
      flash[:mensaje] = "No se enuentra el registro de el curso seleccionado, por favor verifique que el curso exista para el periodo seleccionado."
    end

  	redirect_to factura_path(@factura)
  end

  def eliminar
  	@detalle_factura = DetalleFactura.find(params[:id])
  	@detalle_factura.destroy
  	redirect_to factura_path(@detalle_factura.factura)
  end

end