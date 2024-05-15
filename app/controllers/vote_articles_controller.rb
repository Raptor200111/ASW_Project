class VoteArticlesController < ApplicationController
  before_action :set_vote_article, only: [:show, :update, :destroy]


  def index
    @vote_articles = VoteArticle.all
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @vote_articles }
    end
  end

  def show
  end

  def new
    @vote_article = VoteArticle.new
  end

  def edit
  end

# POST /vote_articles
  def create
  end


# PUT /vote_articles/:id
  def update
  end

# DELETE /vote_articles/:id
  def destroy
  end

  private

  def set_vote_article
    @vote_article = VoteArticle.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.html { redirect_to articles_url, alert: 'Vote not found.' }
      format.json { render json: { error: "Not Found" }, status: :not_found }
    end
  end

end
