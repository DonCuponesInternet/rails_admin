require 'builder'

module RailsAdmin
  module MainHelper
    def rails_admin_form_for(*args, &block)
      options = args.extract_options!.reverse_merge(builder: RailsAdmin::FormBuilder)
      (options[:html] ||= {})[:novalidate] ||= !RailsAdmin::Config.browser_validations

      form_for(*(args << options), &block) << after_nested_form_callbacks
    end

    def get_indicator(percent)
      return '' if percent < 0          # none
      return 'info' if percent < 34     # < 1/100 of max
      return 'success' if percent < 67  # < 1/10 of max
      return 'warning' if percent < 84  # < 1/3 of max
      'danger'                          # > 1/3 of max
    end

    def get_column_sets(properties)
      sets = []
      property_index = 0
      set_index = 0

      while property_index < properties.length
        current_set_width = 0
        loop do
          sets[set_index] ||= []
          sets[set_index] << properties[property_index]
          current_set_width += (properties[property_index].column_width || 120)
          property_index += 1
          break if current_set_width >= RailsAdmin::Config.total_columns_width || property_index >= properties.length
        end
        set_index += 1
      end
      sets
    end

    def filterable_fields
      @filterable_fields ||= @model_config.list.fields.select(&:filterable?)
    end
    
    def queryable_fields
      @queryable_fields ||= @model_config.list.fields.select(&:queryable?)
    end
    
    def queryable_fields_placeholder
      model = @model_config.abstract_model.to_param
      queryable_fields.reject(&:no_searchbox_hint).map{|f|
        name = f.name
        I18n.t!("activerecord.attributes.#{model}.#{name}") rescue name.to_s.titleize
      }.join(', ')
    end

    def ordered_filters
      return @ordered_filters if @ordered_filters.present?
      @index = 0
      
      the_filters = params[:f] || @model_config.list.filters
      
      if the_filters.blank?
        
        the_filters = [["id", {"id"=>{"o"=>"default", "v"=>["", "", ""]}}]]
        
        if @abstract_model.try(:model) == Coupon
          
          the_filters << ["store", {"store"=>{"o"=>"default", "v"=>[""]}}]
          
        end
        
      end
      
      @ordered_filters = the_filters.inject({}) do |memo, filter|
        field_name = filter.is_a?(Array) ? filter.first : filter
        (filter.is_a?(Array) ? filter.last : {(@index += 1) => {'v' => ''}}).each do |index, filter_hash|
          if filter_hash['disabled'].blank?
            memo[index] = {field_name => filter_hash}
          else
            params[:f].delete(field_name)
          end
        end
        memo
      end.to_a.sort_by(&:first)
    end

    def ordered_filter_string
      @ordered_filter_string ||= ordered_filters.map do |duplet|
        options = {index: duplet[0]}
        filter_for_field = duplet[1]
        filter_name = filter_for_field.keys.first
        filter_hash = filter_for_field.values.first
        unless (field = filterable_fields.find { |f| f.name == filter_name.to_sym })
          fail "#{filter_name} is not currently filterable; filterable fields are #{filterable_fields.map(&:name).join(', ')}"
        end
        case field.type
        when :enum
          options[:select_options] = options_for_select(field.with(object: @abstract_model.model.new).enum, filter_hash['v'])
        when :date, :datetime, :time
          options[:datetimepicker_format] = field.parser.to_momentjs
        end
        options[:label] = field.label
        options[:name]  = field.name
        options[:type]  = field.type
        options[:value] = filter_hash['v']
        options[:label] = field.label
        options[:operator] = filter_hash['o']
        %{$.filters.append(#{options.to_json});}
      end.join("\n").html_safe if ordered_filters
    end
  end
end
