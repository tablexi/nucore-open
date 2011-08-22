class AffiliatesController < GlobalSettingsController

  def new
    @affiliate=Affiliate.new
  end


  def create
    attrs=params[:affiliate]

    if attrs.blank?
      flash[:error]='Affiliate attributes not found!'
      return redirect_to new_affiliate_path
    end

    @affiliate=Affiliate.create(attrs)
    return render :action => :new unless @affiliate.errors.empty?

    flash[:notice]="Affiliate #{@affiliate.name} created"
    redirect_to affiliates_path
  end


  def edit
    id=params[:id]

    begin
      @affiliate=Affiliate.find(id.to_i)
    rescue ActiveRecord::RecordNotFound
      flash[:error]="Affiliate with id #{id} not found!"
      return redirect_to affiliates_path
    end
  end


  def update
    id=params[:id]

    begin
      @affiliate=Affiliate.find(id.to_i)
    rescue ActiveRecord::RecordNotFound
      flash[:error]="Affiliate with id #{id} not found!"
    else
      attrs=params[:affiliate]

      if attrs.blank?
        flash.now[:error]='Affiliate attributes not found!'
        return render :action => :edit
      end

      return render :action => :edit unless @affiliate.update_attributes(attrs)

      flash[:notice]="Affiliate #{@affiliate.name} updated"
    end

    redirect_to affiliates_path
  end


  def destroy
    id=params[:id]

    begin
      affiliate=Affiliate.find(id.to_i)
    rescue ActiveRecord::RecordNotFound
      flash[:error]="Affiliate with id #{id} not found!"
    else
      affiliate.destroy

      if affiliate.destroyed?
        flash[:notice]="Affiliate #{affiliate.name} removed"
      else
        flash[:error]="Affiliate #{affiliate.name} could not be removed"
      end
    end

    redirect_to affiliates_path
  end

end