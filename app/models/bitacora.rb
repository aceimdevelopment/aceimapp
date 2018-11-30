class Bitacora < ApplicationRecord

  # ASOCIACIONES
  belongs_to :usuario,
    foreign_key: 'usuario_ci'

  belongs_to :estudiante_usuario,
    class_name: 'Estudiante',
    foreign_key: 'estudiante_usuario_ci'

  belongs_to :administrador_usuario,
    class_name: 'Administrador',
    foreign_key: 'administrador_usuario_ci'

  # FUNCIONES
  def self.info(params = {}) 
    predeterminados = {
      :descripcion => nil,
      :fecha_hora => Time.now,
      :estudiante_usuario_ci => nil,
      :usuario_ci => nil,
      :administrador_usuario_ci => nil,
      :ip_origen => nil
    }                    
    params = predeterminados.merge params   
    b = Bitacora.new
    b.fecha = params[:fecha_hora]
    b.descripcion = params[:descripcion]
    b.usuario_ci = params[:usuario_ci]
    b.estudiante_usuario_ci = params[:estudiante_usuario_ci]
    b.administrador_usuario_ci = params[:administrador_usuario_ci]
    b.ip_origen = params[:ip_origen]
    b.save
  end

end
