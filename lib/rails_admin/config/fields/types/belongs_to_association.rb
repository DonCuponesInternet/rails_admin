require 'rails_admin/config/fields/association'

module RailsAdmin
  module Config
    module Fields
      module Types
        class BelongsToAssociation < RailsAdmin::Config::Fields::Association
          RailsAdmin::Config::Fields::Types.register(self)
                    
          register_instance_option :formatted_value do
            label_method = associated_model_config.filtering_select_to_s ? :filtering_select_to_s : associated_model_config.object_label_method
            (o = value) && o.send(label_method)
          end

          register_instance_option :sortable do
            @sortable ||= abstract_model.adapter_supports_joins? && associated_model_config.abstract_model.properties.collect(&:name).include?(associated_model_config.object_label_method) ? associated_model_config.object_label_method : {abstract_model.table_name => method_name}
          end

          register_instance_option :searchable do
            @searchable ||= associated_model_config.abstract_model.properties.collect(&:name).include?(associated_model_config.object_label_method) ? [associated_model_config.object_label_method, {abstract_model.model => method_name}] : {abstract_model.model => method_name}
          end

          register_instance_option :partial do
            nested_form ? :form_nested_one : :form_filtering_select
          end

          register_instance_option :inline_add do
            true
          end

          register_instance_option :inline_edit do
            true
          end

          def selected_id
            if RailsAdmin::DoncuponesHelpers.is_bulk_edit_controller?(bindings[:controller])
              value.try :id
            else
              bindings[:object].send(foreign_key)
            end
          end

          def method_name
            nested_form ? "#{name}_attributes".to_sym : association.foreign_key
          end

          def multiple?
            false
          end
        end
      end
    end
  end
end
