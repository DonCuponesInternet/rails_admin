class RailsAdmin::DoncuponesHelpers
  
  def self.is_bulk_edit_controller? controller
    controller.params[:bulk_action] == 'bulk_edit' || controller.action_name == 'bulk_edit'
  end
  
end