require 'rails_admin/doncupones_helpers'
require 'rails_admin/config/fields/base'
require 'rails_admin/support/datetime'

module RailsAdmin
  module Config
    module Fields
      module Types
        class Datetime < RailsAdmin::Config::Fields::Base
          
          STRFTIME_FORMAT = '%Y/%m/%d %H:%M'
          
          RailsAdmin::Config::Fields::Types.register(self)

          def parser
            @parser ||= RailsAdmin::Support::Datetime.new(STRFTIME_FORMAT)
          end

          def parse_value(value)
            parser.parse_string(value)
          end

          def parse_input(params)
            params[name] = parse_value(params[name]) if params[name]
          end

          def value
            parent_value = super
            if %w(DateTime Date Time).include?(parent_value.class.name)
              parent_value.in_time_zone
            else
              parent_value
            end
          end

          register_instance_option :date_format do
            :long
          end

          register_instance_option :i18n_scope do
            [:time, :formats]
          end

          register_instance_option :strftime_format do
            # hardcoded value, essential for the datepicker to work (due to rails_admin faulty design). don't change this.
            # for customizing how dates look in tables, override/custome something else instead.
            STRFTIME_FORMAT
          end

          register_instance_option :datepicker_options do
            {
              showTodayButton: true,
              format: parser.to_momentjs,
            }
          end

          register_instance_option :html_attributes do
            {
              required: required?,
              size: 22,
            }
          end

          register_instance_option :sort_reverse? do
            true
          end

          register_instance_option :formatted_value do
            if RailsAdmin::DoncuponesHelpers.is_bulk_edit_controller?(@bindings.fetch(:controller))
              time = RailsAdmin::DoncuponesHelpers.unique_value_among_bulk_edit_fields(@bindings, name)
              if value
                localized_time time
              else
                nil
              end
            else
              time = value || default_value
              (time ||= DateTime.current) if ['new', 'edit', 'edit_first'].include?(bindings[:controller].action_name)
              if time && (bindings[:object].class == Coupon)
                unless bindings[:object].id
                  time = time.change(sec: 0)
                  if name == :start_date
                    time = time.change(min: 1)
                  elsif name == :end_date
                    time = time.change(min: 59)
                  end
                end
              end
              localized_time time if time
            end
          end
          
          def localized_time time
            @i18n_reloaded ||= begin # workaround. I believe translations are half-loaded in production.
              I18n.reload!
              true
            end
            ::I18n.l(time, format: strftime_format, locale: :es) # don't use the STRFTIME_FORMAT constant here - not needed
          end
          
          register_instance_option :partial do
            :form_datetime
          end
        end
      end
    end
  end
end
