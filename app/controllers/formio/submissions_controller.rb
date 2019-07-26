module Formio
  class SubmissionsController < ApplicationController

    before_action :authenticate_user!
    before_action :check_acting_as

    def new
      @formio_url = params[:formio_url]
      @redirect_url = redirect_url
      render layout: false
    end

    def show
      @formio_url = params[:formio_url]
      render layout: false
    end

    def edit
      @formio_url = params[:formio_url]
      @redirect_url = redirect_url
      render layout: false
    end

    private

    # NUcore’s SurveysController expects a referer param, which contains the page
    # to which NUcore should redirect after it processes a form submission. However,
    # the success_url that we get from UrlService does not include this param. Instead,
    # we get it as a separate pram, so we construct the full redirect_url here to
    # avoid changing having to change code for unrelated integrations
    def redirect_url
      referer_url = URI(params[:referer])
      URI(params[:success_url]).tap do |success_url|
        success_url_params = Rack::Utils.parse_query(success_url.query)
        success_url.query = success_url_params.merge(referer: referer_url.to_s).to_query
      end.to_s
    end

  end
end
