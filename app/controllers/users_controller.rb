class UsersController < ApplicationController
  before_action :set_user
  def profile
    #@user.update(views: @user.views + 1)
    #@posts = @user.posts.includes(:rich_text_body).order(created_at: :desc)
    #@total_views = 0

    #@posts.each do |post|
    #  @total_views += post.views
    #end
  end


  def update
    @user = User.find_by(id: params[:id])
    @user.full_name = params[:user][:full_name]
    if params[:user][:avatar] != nil
      @user.avatar = params[:user][:avatar]
    end
    if params[:user][:background] != nil
      @user.background = params[:user][:background]
    end
    @user.save
    redirect_to user_path(@user.id)
  end

  def deleteAvatar
    @user = User.find_by(id: params[:id])
    @user.avatar.purge
    redirect_to user_path(@user.id)
  end

  def deleteBack
    @user = User.find_by(id: params[:id])
    @user.background.purge
    redirect_to user_path(@user.id)
  end

  private

  def set_user
    if request.headers[:Accept] == "application/json"
      api_key = request.headers[:HTTP_X_API_KEY]

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

  def show_threads
    set_user
    if @user.nil?
      @user = User.find(params[:id])
      @threads = @user.articles
      render partial: 'u/articles', locals: { articles: @articles }
    end
  end

  def show_comments
    @user = User.find(params[:id])
    @comments = @user.comments
    render partial: 'u/comments', locals: { comments: @comments }
  end

  def show_boosts
    @user = User.find(params[:id])
    @boosts = @user.boosts
    render partial: 'u/boosts', locals: { boosts: @boosts }
  end
end