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
        owner: {
          id: owner.id,
          name: owner.name,
          username: owner.username,
          email: owner.email,
        },
      },
      ordered_for: {
        id: ordered_for.id,
        name: ordered_for.name,
        username: ordered_for.username,
        email: ordered_for.email,
      },
    }
  end
end
