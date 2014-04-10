require 'chronic'

class ImportMapping < ActiveRecord::Base
  belongs_to :csv_import
  attr_accessible :column, :type
  acts_as_list scope: :csv_import_id

  def type=(val)
    self.data_type = val
  end


  def apply(value, model)
    apply_column = column
    transformed_value = transform(value)

    if transformed_value.present?
      while apply_column =~ /\./
        sender, apply_column = apply_column.split('.')
        model = model.send(sender)
      end

      if apply_column.match /(\w+)\[([^\]]+)\]/
        model = model.send($1)
        apply_column = $2
      end

      if apply_column =~ /\[\]/
        apply_column, attrs = apply_column.split('[]', 2)
        model = model.send(apply_column)
        apply_column = attrs.gsub(/(?:^\[)|(?:\]$)/,'')
      end

      if apply_column.blank?
        model.push(transformed_value)
      elsif transformed_value.kind_of?(Enumerable) && model.respond_to?(:build)
        transformed_value.each do |v|
          model.build do |m|
            put_value(m, apply_column, v)
          end
        end
      else
        put_value(model, apply_column, transformed_value)
      end
    end
  end

  private

  def transform(value)
    if value.present?
      case data_type
      when "string" then value.to_s
      when "geolocation" then value.to_s
      when "person" then Person.for_name(value)
      when "array" then transform_array(value)
      when "short_text" then value.to_s
      when "number" then parse_to_i(value)
      when "text" then value.to_s
      when "date" then Chronic.parse(value, :context => :past) rescue nil
      when "*" then value.to_s
      end
    else
      value
    end
  end

  def transform_array(value)
    csv = value.gsub(/,\s+\"/,',"')
    v = CSV.parse(csv).try(:first) || []
    v.map{|x| x.gsub(/(?:^\s+)|(?:\s$)/, '') }
  end

  def put_value(model, key, value)
    if model.respond_to?(:"#{key}=")
      model.send(:"#{key}=", value)
    elsif model.respond_to?(:[]=)
      model[key.intern] = value
    end
  end

  def parse_to_i(value)
    if value.include? ':'
      Time.parse(value).seconds_since_midnight
    else
      value.to_i
    end
  end
end
