class RailsAdmin::DoncuponesHelpers
  
  def self.is_bulk_edit_controller? controller
    controller.params[:bulk_action] == 'bulk_edit' || controller.action_name == 'bulk_edit'
  end
  
  # given a form field in a BulkEdit action, this method returns the value which all the underlying records have, **if** they all have the same value. 
  def self.unique_value_among_bulk_edit_fields bindings, name
    values = bindings[:object].class.find(bindings[:controller].params[:bulk_ids]).map{|object|
      object.safe_send(name)
    }
    if values.uniq.size == 1 # i.e., if all the values are the same
      values.first
    else
      nil
    end
  end
  
end