class MainController < ApplicationController
  def start
    respond_to do |format|
      format.html # main.html.erb
    end
  end
end
