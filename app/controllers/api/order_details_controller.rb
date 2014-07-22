class Api::OrderDetailsController < ApplicationController
  respond_to :json

  http_basic_authenticate_with name: Settings.api.basic_auth_name, password: Settings.api.basic_auth_password

  def show
    od = OrderDetail.find(params[:id])
    account = od.account
    owner = account.owner.user
    ordered_for = od.order.user

    render json: {
      account: {
        id: account.id,
        owner: user_to_hash(owner),
      },
      ordered_for: user_to_hash(ordered_for),
    }
  end

  private

  def user_to_hash(user)
    {
      id: user.id,
      name: user.name,
      username: user.username,
      email: user.email,
    }
  end
end
