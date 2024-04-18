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

  private

  def set_user
    @user = User.find(params[:id])
  end

  def show_threads
    @user = User.find(params[:id])
    @threads = @user.articles
    render partial: 'u/articles', locals: { articles: @articles }
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