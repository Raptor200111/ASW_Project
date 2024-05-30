class UsersController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :set_user, only: [:update, :deleteAvatar, :deleteBack, :show_boosts]

  def profile
    @user = User.find(params[:id])
    respond_to do |format|
      format.html
      format.json { render json: @user.as_custom_json.merge(
        avatar_url: @user.avatar.attached? ? url_for(@user.avatar) : nil,
        background_url: @user.background.attached? ? url_for(@user.background) : nil ),
      status: :ok }
    end
  end

  def update
    @requested_user = User.find(params[:id])
    if (@requested_user == @user)
      @user = User.find_by(id: params[:id])
      @user.full_name = params[:user][:full_name]
      @user.description = params[:user][:description]
      if params[:user][:avatar] != nil
        @user.avatar = params[:user][:avatar]
      end
      if params[:user][:background] != nil
        @user.background = params[:user][:background]
      end
      @user.save
      respond_to do |format|
        format.html { redirect_to user_path(@user.id) }
        format.json { render json: {message: "User Updated"},  status: :ok }
      end
    else
      render :json => { "status" => "403", "error" => "Unauthorized User" }, status: :unauthorized and return
    end
  end

  def deleteAvatar
    @requested_user = User.find(params[:id])
    if (@requested_user == @user)
      @user = User.find_by(id: params[:id])
      @user.avatar.purge
      respond_to do |format|
        format.html { redirect_to user_path(@user.id) }
        format.json { render json: {message: "User Avatar Deleted"},  status: :ok }
      end
    else
      render :json => { "status" => "403", "error" => "Forbidden User" }, status: :unauthorized and return
    end
  end

  def deleteBack
    @requested_user = User.find(params[:id])
    if (@requested_user == @user)
      @user = User.find_by(id: params[:id])
      @user.background.purge
      respond_to do |format|
        format.html { redirect_to user_path(@user.id) }
        format.json { render json: {message: "User Updated"},  status: :ok }
      end
    else
      render :json => { "status" => "403", "error" => "Forbidden User" }, status: :unauthorized and return
    end
  end

  def show_articles
    @requested_user = User.find(params[:id])
    @articles = @requested_user.articles

    respond_to do |format|
      format.html { render partial: 'u/articles', locals: { articles: @articles } }
      format.json { render json:  @articles, status: :ok }
    end
  end

  def show_comments
    @requested_user = User.find(params[:id])
    @comments = @requested_user.comments

    respond_to do |format|
      format.html { render partial: 'u/comments', locals: { comments: @comments } }
      format.json { render json:  @comments, status: :ok }
    end
  end

  def show_boosts
    @requested_user = User.find(params[:id])
    if (@user == @requested_user)
      @boosts = @requested_user.boosts
      respond_to do |format|
        format.html { render partial: 'u/boosts', locals: { boosts: @boosts } }
        format.json { render json:  @boosts, status: :ok }
      end
    else
      render :json => { "status" => "403", "error" => "Forbidden User" }, status: :unauthorized and return
    end
  end

  private
  def set_user
    if request.headers[:Accept] == "application/json"
      api_key = request.headers[:Authorization]
      @user = nil
      if api_key.nil?
        render :json => { "status" => "401", "error" => "No Api key provided." }, status: :unauthorized and return
      else
        @user = User.find_by_api_key(api_key)
        if @user.nil?
          render :json => { "status" => "403", "error" => "No User found with the Api key provided." }, status: :unauthorized and return
        end
      end
    else
      @user = current_user
    end
  end
end