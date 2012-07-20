module ApprovalNotification  
  class NewOrder
    def on_status_change(order_detail, old_status, new_status)
      puts "#{order_detail} has been moved to New!!!!"
    end
  end

  class InProcess
    def on_status_change(order_detail, old_status, new_status)
      puts "#{order_detail} has been moved to In Progress"
    end
  end
end
