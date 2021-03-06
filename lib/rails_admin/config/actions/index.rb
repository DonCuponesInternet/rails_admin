module RailsAdmin
  module Config
    module Actions
      class Index < RailsAdmin::Config::Actions::Base
        RailsAdmin::Config::Actions.register(self)

        register_instance_option :collection do
          true
        end

        register_instance_option :http_methods do
          [:get, :post]
        end

        register_instance_option :route_fragment do
          ''
        end

        register_instance_option :breadcrumb_parent do
          parent_model = bindings[:abstract_model].try(:config).try(:parent)
          if am = parent_model && RailsAdmin.config(parent_model).try(:abstract_model)
            [:index, am]
          else
            [:dashboard]
          end
        end

        register_instance_option :controller do
          proc do
            @objects ||= list_entries
            
            unless @model_config.list.scopes.empty?
              if params[:scope].blank?
                unless @model_config.list.scopes.first.nil?
                  @objects = @objects.send(@model_config.list.scopes.first)
                end
              elsif @model_config.list.scopes.collect(&:to_s).include?(params[:scope])
                @objects = @objects.send(params[:scope].to_sym)
              end
            end
            
            the_association_scope = @association.try(:doncupones_scope).presence # used for autocomplete dropdowns
            the_params_scope = params[:doncupones_scope].presence # used for plain index actions
            
            tenancy_scope = the_association_scope || the_params_scope
            
            if tenancy_scope
              @objects = @objects.send(tenancy_scope)
              if the_params_scope
                @objects = @objects.send(Kaminari.config.page_method_name, params[:page]).per(params[:per])
              end
            end
            
            respond_to do |format|
              format.html do
                render @action.template_name, status: (flash[:error].present? ? :not_found : 200)
              end

              format.json do
                output = begin
                  if params[:compact]
                    is_coupon_class = @abstract_model.model == Coupon
                    is_store_class = @abstract_model.model == Store
                    primary_key_method = @association ? @association.associated_primary_key : @model_config.abstract_model.primary_key
                    label_method = (@model_config.filtering_select_to_s || is_coupon_class || is_store_class) ? :filtering_select_to_s : @model_config.object_label_method
                    is_tenancy_per_locale = @abstract_model.model.is_a?(TenancyPerLocale)
                    @objects.collect { |o|
                      result = 
                        {
                          id: o.send(primary_key_method).to_s,
                          label: "#{o.send(label_method).to_s}",
                          class: (is_coupon_class ? "coupon-publication-status-#{o.publication_status}" : '')
                        }
                      if is_tenancy_per_locale
                        result.merge!({
                          enable_for_all_locales: o.enable_for_all_locales,
                          enabled_locales: o.enabled_locales,
                        })
                      end
                      result
                    }
                  else
                    @objects.to_json(@schema)
                  end
                end
                if params[:send_data]
                  send_data output, filename: "#{params[:model_name]}_#{DateTime.now.strftime('%Y-%m-%d_%Hh%Mm%S')}.json"
                else
                  render json: output, root: false
                end
              end

              format.xml do
                output = @objects.to_xml(@schema)
                if params[:send_data]
                  send_data output, filename: "#{params[:model_name]}_#{DateTime.now.strftime('%Y-%m-%d_%Hh%Mm%S')}.xml"
                else
                  render xml: output
                end
              end

              format.csv do
                header, encoding, output = CSVConverter.new(@objects, @schema).to_csv(params[:csv_options])
                if params[:send_data]
                  send_data output,
                            type: "text/csv; charset=#{encoding}; #{'header=present' if header}",
                            disposition: "attachment; filename=#{params[:model_name]}_#{DateTime.now.strftime('%Y-%m-%d_%Hh%Mm%S')}.csv"
                else
                  render text: output
                end
              end
            end
          end
        end

        register_instance_option :link_icon do
          'fa fa-th-list'
        end
      end
    end
  end
end
