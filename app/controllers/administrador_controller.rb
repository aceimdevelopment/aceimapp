# encoding: utf-8

class AdministradorController < ApplicationController
	before_action :filtro_logueado
 	before_action :filtro_super_administrador
 	

	def index
		@administradores = Administrador.where("tipo_rol_id <> ? OR tipo_rol_id IS NULL", 2)
	end

	def agregar
 		@accion = 'agregar_guardar'
 		@administrador = Administrador.new
 		render :layout => false 
 		
 	end

	def agregar_guardar		
		if usuario = Usuario.where(:ci  => params[:administrador][:usuario_ci]).limit(1).first
			administrador = Administrador.new(params[:administrador]) 
			if administrador.save
				flash[:mensaje] = "Agregado con Éxito"
			else
				flash[:mensaje] = "No se pudo Agregar"
			end			
		else
			flash[:mensaje] = "No se Encontró el Usuario"
		end
		redirect_to :action => 'index'
	end

	def nuevo
		if session[:administrador].tipo_rol_id > 2 
		  flash[:mensaje] = "Usted no posee los privilegios para acceder a esta función"
		  redirect_to :action => 'index'
		end
		@titulo_pagina = "Agregar Usuario"
		@administrador = Administrador.new
		@usuario = Usuario.new
    	@controlador = params[:controlador]
    	@accion = params[:accion]
		# render :layout => false
	end

	def nuevo_guardar
		usuario = Usuario.new(params[:usuario])
		if usuario.save
			administrador = Administrador.new()
			administrador.usuario_ci = usuario.ci
			administrador.tipo_rol_id = params[:tipo_rol_id]
			if administrador.save
				flash[:mensaje] = "Administrador creado Correctamente"
			else
				usuario.destroy
				flash[:mensaje] = "No se pudo guardar el Administrador: #{administrador.errors.full_messages.join(". ")}"
			end
		else
			flash[:mensaje] = "No se pudo guardar el Usuario: #{usuario.errors.full_messages.join(". ")}"
		end
		redirect_to :action => "index"	
	end

	def editar
		@accion = 'editar_guardar'
		ci = params[:parametros][:id]
  		@administrador = Administrador.where(:usuario_ci => ci).limit(1).first
  		render :layout => false  
	end

	def editar_guardar
		administrador = Administrador.where(:usuario_ci  => params[:administrador][:usuario_ci]).limit(1).first
		administrador.tipo_rol_id = params[:administrador][:tipo_rol_id]
		
		if administrador.save
			flash[:mensaje] = "Actualización Correcta"
		else
			flash[:mensaje] = "No se pudo actualizar"
		end

		redirect_to :action => "index"
	end

	def eliminar
		administrador = Administrador.where(:usuario_ci => params[:ci]).limit(1).first
		administrador.destroy
		flash[:mensaje] = "Usuario Adminstrador Eliminado Correctamente"
		redirect_to :action => 'index'
	end

end