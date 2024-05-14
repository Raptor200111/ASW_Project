class VoteArticlesController < ApplicationController
  before_action :authenticate_user!, only: [:create, :update, :destroy]
  before_action :set_vote_article, only: [:show, :update, :destroy]
  before_action :check_owner, only: [:update, :destroy]

  def index
    @vote_articles = VoteArticle.all
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @vote_articles }
    end
  end

  def show
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @vote_article }
    end
  end

  def new
    @vote_article = VoteArticle.new
  end

  def edit
  end

# POST /vote_articles
  def create
      @article = Article.find(params[:article_id])
      if current_user.nil?
        @existing_vote = @article.vote_articles.find_by(user_id: params[:user_id])
      else
        @existing_vote = @article.vote_articles.find_by(user_id: current_user.id)
      end

      if @existing_vote && @existing_vote.value == params[:value]
        @existing_vote.destroy
        respond_to do |format|
          format.html { redirect_back fallback_location: root_path, notice:  'Vote removed successfully' }
          format.json { render json: { message: 'Vote removed successfully' }, status: :ok }
        end
      else
        if current_user.nil?
          @vote_article = @article.vote_articles.find_or_initialize_by(user_id: params[:user_id])
        else
          @vote_article = @article.vote_articles.find_or_initialize_by(user_id: current_user.id)
        end

        @vote_article.value = params[:value]

        respond_to do |format|
          if @vote_article.save
            format.html { redirect_back fallback_location: root_path, notice: 'Vote was successfully created.' }
            format.json { render json: @vote_article, status: :created }
          else
            format.html { redirect_back fallback_location: root_path, status: :unprocessable_entity }
            format.json { render json: { error: @vote_article.errors.full_messages.join(', ') }, status: :unprocessable_entity }
          end
        end
      end

  end


# PUT /vote_articles/:id
  def update
    respond_to do |format|
      if @vote_article.update(vote_article_params)
        format.html { redirect_to @vote_article, notice: 'Vote was successfully updated.' }
        format.json { render json: @vote_article }
      else
        format.html { render :edit }
        format.json { render json: @vote_article.errors, status: :unprocessable_entity }
      end
    end
  end

# DELETE /vote_articles/:id
  def destroy
    @vote_article.destroy
    respond_to do |format|
      if @vote_article.destroy
        format.html { redirect_back fallback_location: root_path, notice: 'Vote was successfully destroyed.' }
        format.json { head :no_content }
      else
        format.html { redirect_to articles_url }
        format.json { render json: @vote_article.errors, status: :unprocessable_entity }
      end
    end
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

  def authenticate_user!
    if current_user.nil?
      if request.headers['Accept'].present? and !request.headers['Authorization'].present?
        respond_to do |format|
          format.html { redirect_to new_user_session_path, alert: "Missing api key" }
          format.json { render(json: {"error": "Missing api key"}, status: 400)}
        end
        return
      end
      if 'Liliu' !=request.headers['Authorization']
        #!User.exists?(api_key: request.headers['key'])
        respond_to do |format|
          format.html { redirect_to new_user_session_path, alert: 'You must be logged in to perform this action.' }
          format.json { render(json: {"error": "Not logged in AUTH"}, status: 401)}
        end
        return
      end
    end
  end

  def check_owner
    if current_user.nil?
      if request.headers['Accept'].present? and request.headers['Authorization'].present? and 'Liliu'!= request.headers['Authorization']
        #!User.exists?(api_key: request.headers['key'])
        #@article.user != User.find_by(api_key: request.headers['Authorization'])
        respond_to do |format|
          format.html { redirect_to articles_url, alert: 'You are not authorized to perform this action.' }
          format.json { render json: { error: 'You are not authorized to perform this action' }, status: :forbidden }
        end
        return
      end
    else
      if current_user != @vote_article.user
        respond_to do |format|
          format.html { redirect_to articles_url, alert: 'You are not authorized to perform this action.' }
          format.json { render json: { error: 'You are not authorized to perform this action' }, status: :forbidden }
        end
      end
    end
  end

  def vote_article_params
    params.require(:vote_article).permit(:value, :user_id, :article_id)
  end
end