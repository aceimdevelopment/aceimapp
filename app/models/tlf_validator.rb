#encoding: utf-8
  class TlfValidator < ActiveModel::EachValidator
    def validate_each(record, attribute, value)
      record.errors[attribute] << (options[:message] || "no tiene formato de número telefónico") unless
      value =~ /(\d{10})/
    end
  end
  
  
