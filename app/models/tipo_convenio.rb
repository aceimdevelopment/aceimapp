# encoding: utf-8


class TipoConvenio < ApplicationRecord
  include ActiveModel::Validations 
  
    validates :id, :presence => true
    validates :descripcion, :presence => true
    validates :monto, :presence => true
    validates :descuento, :presence => true

  def descripcion_convenio
    "#{descripcion}"
  end

end


