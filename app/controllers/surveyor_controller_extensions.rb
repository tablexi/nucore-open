module SurveyorControllerExtensions
  def self.included(base)
    base.extend(ClassMethods)
    base.send(:include, InstanceMethods)
    base.class_eval do
      # Same as typing in the class
      # before_filter :pimp_my_ride
      before_filter :check_if_completed, :only => [:update]
      before_filter :init_current_facility, :only => [:show]
      layout 'application'
    end
  end
  
  module ClassMethods
  end
  
  module InstanceMethods
    # def pimp_my_ride
    #   flash[:notice] = "pimped!"
    # end

    def check_if_completed
      # skip if its not an html request
      return true unless request.format.html?
      responses = params[:responses]
      # check for missing answers
      completed = true
      responses.each_pair do |key, hash|
        # each hash should have a question_id and some type of answer
        completed = false if hash.keys.size < 2
        # if the hash looks like '12345' => {'string_value' => ''}, we are missing a string answer
        hash.each_pair do |key, value|
          next unless value.is_a?(Hash)
          value.each_pair do |k, v|
            completed = false if v.blank?
          end
        end
      end
      if !completed
        logger.debug("*** survey not complete")
        flash[:notice] = "Please answer all questions"
        redirect_to :action => "edit", :anchor => anchor_from(params[:section]), :params => {:section => section_id_from(params[:section])} and return
      end
      true
    end
    
    def finish_survey_method
      # find response set, and related order detail + order
      response_set  = ResponseSet.find_by_access_code(params[:response_set_code])
      order_detail  = OrderDetail.find_by_response_set_id(response_set.id)
      order         = order_detail.try(:order)
      
      if order
        # redirect to order show
        return order_path(order)
      else
        # find service associated with this survey; redirect to manage service path
        ss      = ServiceSurvey.find_by_preview_code(response_set.access_code)
        service = ss.service
        return manage_facility_service_path(service.facility, service)
      end
    end

    # extend survey routes
    # def surveyor_default(type = :finish)
    #   # figure out where to go
    #   debugger
    #   case arg = Surveyor::Config["default.#{type.to_s}"]
    #   when String
    #     return arg
    #   when Symbol
    #     return self.send(arg)
    #   else
    #     return available_surveys_path
    #   end
    # end

  end
  
  module Actions
    # Redefine the controller actions [index, new, create, show, update] here
    # def new
    #   render :text =>"surveys are down"
    # end
    
    # GET /orders/1/details/3/survey/123abc
    # start survey, and attach it to the specified order and order detail
    def create
      @order        = Order.find(params[:order_id])
      @detail       = @order.order_details.find(params[:od_id])
      @survey       = Survey.find_by_access_code(params[:survey_code])
      @response_set = @survey.response_sets.create
      if (@survey && @response_set)
        # attach response_set to order detail
        @detail.response_set!(@response_set)
        flash[:notice] = "Survey was successfully started."
        redirect_to(edit_my_survey_path(:survey_code => @survey.access_code, :response_set_code => @response_set.access_code))
      else
        flash[:notice] = "Unable to find that survey"
        redirect_to(available_surveys_path)
      end
    end

    # GET /facilities/1/services/1/survey/xyz/preview
    def show
      @service      = Service.find_by_url_name(params[:service_id])
      @survey       = @service.surveys.find_by_access_code(params[:survey_code])
      # find or create the special preview response set
      @through      = @service.service_surveys.find_by_survey_id(@survey.id)
      @response_set = @through.find_or_create_preview_response_set

      redirect_to(edit_my_survey_path(:survey_code => @survey.access_code, :response_set_code => @response_set.access_code))
    end

  end
end

# Add "surveyor_controller" to config['extend'] array in config/initializers/surveyor.rb to activate these extensions
