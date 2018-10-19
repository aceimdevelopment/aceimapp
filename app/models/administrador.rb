# encoding: utf-8

# class Administrador < Usuario
class Administrador < ApplicationRecord

  self.primary_keys = :usuario_ci

  validates_presence_of :usuario_ci, :tipo_rol_id 
  validates :usuario_ci, :uniqueness => true
  #autogenerado por db2models

  belongs_to :usuario,
  foreign_key: :usuario_ci
  accepts_nested_attributes_for :usuario

  belongs_to :tipo_rol
end
