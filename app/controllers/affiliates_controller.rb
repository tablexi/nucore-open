class AffiliatesController < GlobalSettingsController

  def new
  end


  def create
    Affiliate.create!(params[:affiliate])
    redirect_to affiliates_path
  end


  def edit
    @affiliate=Affiliate.find(params[:id].to_i)
  end


  def update
    Affiliate.find(params[:id].to_i).update_attributes(params[:affiliate])
    redirect_to affiliates_path
  end


  def destroy
    Affiliate.destroy(params[:id].to_i)
    redirect_to affiliates_path
  end

end