# encoding: utf-8

class FacturasController < ApplicationController
  before_action :filtro_logueado
  before_action :filtro_administrador

  def index
    @facturas = Factura.all
    @titulo_pagina = "Facturas"
    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @facturas }
    end
  end

  def show
    @factura = Factura.find(params[:id])
    @idiomas = Idioma.select("idioma.*,tipo_curso.*").joins(:tipo_curso).where(["id != ? and tipo_curso.tipo_categoria_id != ?", "OR","BBVA"])

    @idiomas.each{|i|
      
      tipo_categoria = TipoCategoria.where(["id = ?", i.tipo_categoria_id]).limit(1).first

      if(i.id=="IN")      
        i.descripcion = i.descripcion + " - " + tipo_categoria.descripcion
      end

      i.id = i.id + "-" +i.tipo_categoria_id
    
    }

    @idiomas = Idioma.all.delete_if{|i| i.id.eql? "OR"}

    # @cursos = CursoPeriodo.select("curso_periodo.*, curso.*").joins(:curso)

    @niveles = TipoNivel.select("tipo_nivel.*, curso.*").joins(@cursos)

    @niveles = TipoNivel.all.delete_if{|n| n.id.eql? "null"}

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @factura }
    end
  end

  def nueva
    @factura = Factura.new
    @cliente = session[:cliente_id].blank? ? Cliente.new : Cliente.find(session[:cliente_id]) 
    @factura.cliente = @cliente 
    @accion = "registrar"
    @titulo_pagina = "Nueva Factura"
    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @factura }
    end
  end


  def editar
    @factura = Factura.find(params[:id])
    @accion = 'update'
    @titulo_pagina = 'Edición de factura'
  end

  def registrar
    @factura = Factura.new(params[:factura])

    respond_to do |format|
      if @factura.save
        session[:cliente_id] = nil
        flash[:mensaje] = 'Datos generales de la facturas registrada exitosamente.'
        format.html { redirect_to factura_path (@factura)}
        format.json { render :json => @factura, :status => :created, :location => @factura }
      else
        @titulo_pagina = "Nueva Factura"
        @accion = "registrar"
        flash[:mensaje] = "#{@factura.errors.count} error(es) impiden el registro de la factura: #{@factura.errors.full_messages.join(". ")}."
        format.html { render :action => "nueva" }
        format.json { render :json => @factura.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /facturas/1
  # PUT /facturas/1.json
  def update
    @factura = Factura.find(params[:id])

    respond_to do |format|
      if @factura.update_attributes(params[:factura])
        flash[:mensaje] = 'Factura actualizada'
        format.html{redirect_to factura_path(@factura)}
        format.json{head :ok}
      else
        @titulo_pagina = "Nueva Factura"
        @accion = "update"
        format.html { render :action => "editar" }
        format.json { render :json => @factura.errors, :status => :unprocessable_entity }
      end
    end
  end

  def imprimir_factura
    @factura = Factura.find(params[:id])  
    info_bitacora "Se imprimio la factura #{@factura.id}"
    pdf = DocumentosPDF.factura(@factura)
    send_data pdf.render,:filename => "factura_#{@factura.id}.pdf", :type => "application/pdf", :disposition => "attachment"
  end


  # def eliminar
  #   @factura = Factura.find(params[:id])
  #   @factura.destroy

  #   respond_to do |format|
  #     format.html { redirect_to facturas_url }
  #     format.json { head :ok }
  #   end
  # end


  def actualizar_idioma_select
    @idioma = CursoPeriodo.where(:periodo_id => params[:periodo_id])
    cp = CursoPeriodo.where(:periodo_id => params[:periodo_id]).select(:idioma_id).map(&:idioma_id).uniq
    return Idioma.find(cp)
  end

end
