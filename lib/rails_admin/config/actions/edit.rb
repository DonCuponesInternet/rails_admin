module RailsAdmin
  module Config
    module Actions
      class Edit < RailsAdmin::Config::Actions::Base
        RailsAdmin::Config::Actions.register(self)

        register_instance_option :member do
          true
        end

        register_instance_option :http_methods do
          [:get, :put]
        end

        register_instance_option :controller do
          proc do
            if request.get? # EDIT

              respond_to do |format|
                format.html {
                  if @object && [Coupon, Store].include?(@object.class) && @object.deprecated_in.any?
                    flash.now[:alert] = "Precaución: #{{Coupon => 'este cupón está deshabilitado', Store => 'esta tienda está deshabilitada'}.fetch @object.class} para las apps #{@object.deprecated_in.map{|a|"<b>#{a.upcase}</b>"}.join(', ')}.".html_safe
                  end
                  render @action.template_name
                }
                format.js   { render @action.template_name, layout: false }
              end

            elsif request.put? # UPDATE
              sanitize_params_for!(request.xhr? ? :modal : :update)

              @object.set_attributes(params[@abstract_model.param_key])
              @authorization_adapter && @authorization_adapter.attributes_for(:update, @abstract_model).each do |name, value|
                @object.send("#{name}=", value)
              end
              changes = @object.changes
              if @object.save
                @auditing_adapter && @auditing_adapter.update_object(@object, @abstract_model, _current_user, changes)
                respond_to do |format|
                  format.html {
                    redirect_to :back, flash: {success: redirect_to_on_success_caption}
                  }
                  format.js { render json: {id: @object.id.to_s, label: @model_config.with(object: @object).object_label} }
                end
              else
                handle_save_error :edit
              end

            end
          end
        end

        register_instance_option :link_icon do
          'fa fa-pencil'
        end
      end
    end
  end
end
