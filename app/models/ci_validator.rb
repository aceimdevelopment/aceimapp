# encoding: utf-8

class CiValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    record.errors[attribute] << (options[:message] || "no tiene formato de cédula de Identidad") unless
    value =~ /\A(^[1-9])\d+/
  end
end
  
  
