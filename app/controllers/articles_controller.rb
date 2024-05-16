class ArticlesController < ApplicationController
  #skip_before_action :verify_authenticity_token
  before_action :set_article, only: %i[ show edit update destroy vote vote_up vote_down unvote_up unvote_down boost_web boost unboost ]
  before_action :authenticate_user!, only: %i[create update destroy vote_up vote_down vote unvote_up unvote_down boost_web boost unboost ]
  before_action :check_owner, only: %i[update destroy]

  # GET /articles or /articles.json
  def index
    # Retrieve filter and order parameters
    @order_filter = params[:order_filter] || 'newest'
    @type = params[:type]

    # Set the default articles scope
    @articles = Article.all

    # Apply ordering based on order_filter
    case @order_filter
    when 'top'
      @articles = @articles.select("articles.*, (SELECT COUNT(*) FROM vote_articles WHERE vote_articles.article_id = articles.id AND vote_articles.value = 'up')
                    - (SELECT COUNT(*) FROM vote_articles WHERE vote_articles.article_id = articles.id AND vote_articles.value = 'down') AS vote_score")
                    .order('vote_score DESC')

    when 'commented'
      @articles = @articles.left_outer_joins(:comments)
                           .group(:id)
                           .order('COUNT(comments.id) DESC')
    else
      @articles = @articles.order(created_at: :desc)
    end

    # Apply filtering based on type
    case @type
    when 'thread'
      @articles = @articles.where(article_type: 'thread')
    when 'link'
      @articles = @articles.where(article_type: 'link')
    end
    respond_to do |format|
      format.html
      format.json { render json: @articles, status: :ok }
    end
  end

  # GET /articles/1 or /articles/1.json
  def show
    respond_to do |format|
      format.html
      format.json { render json:  @article.as_custom_json, status: :ok }
      #format.json { render json: article_with_details(@article), status: :ok }
    end
  end

  def search
    @search_text = params[:search_text]
    @articles = Article.where("title LIKE ? OR body LIKE ?", "%#{@search_text}%", "%#{@search_text}%")
    respond_to do |format|
      format.html
      format.json { render json: @articles, status: :ok }
    end
  end

  # GET /articles/new
  def new
    @article = Article.new
    #@show_url_field = false
  end


  #GET /articles/new_link
  def new_link
    @article = Article.new
    #@show_url_field = true
  end

  # GET /articles/1/edit
  def edit
    @article = Article.find(params[:id])
    @show_url_field = @article.url_required?

    # Check if the current user is the creator of the article
    if !current_user.nil? and @article.user == current_user
      # Allow editing
      render :edit
    else
      # Redirect with a notice indicating they are not allowed to edit the article
      redirect_to root_path, notice: "You are not allowed to edit this article."
    end
  end

  # POST /articles or /articles.json
  def create
    @article = @user.articles.build(article_params)
    respond_to do |format|
      if @article.save
        format.html { redirect_to article_url(@article), notice: "Article was successfully created." }
        format.json { render json: @article.as_custom_json, status: :created }
      else
        @show_url_field = @article.url_required?
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { error: @article.errors.full_messages.join(', ') }, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /articles/1 or /articles/1.json
  def update
    respond_to do |format|
      if @article.update(article_params)
        format.html { redirect_to article_url(@article), notice: "Article was successfully updated." }
        format.json { render json: @article.as_custom_json, status: :ok }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @article.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /articles/1 or /articles/1.json
  def destroy
      @article.destroy
      render json: {message: "Article was successfully destroyed."}, status: :ok
  end
=begin
  def destroy
    respond_to do |format|
      if @article.destroy
        format.html { redirect_to articles_url, notice: "Article was successfully destroyed." }
        format.json  { render json: { message: 'Destroyed article uccessfully' }, status: :ok }
      else
        format.html { redirect_to article_url(@article), notice: "ERROR DELETE" }
        format.json { render json: @article.errors, status: :unprocessable_entity }
      end
    end
  end
=end

  #/articles/:id/vote_up
  def vote_up
    vote_api('up')
  end

    #/articles/:id/vote_down
  def vote_down
    vote_api('down')
  end

  def vote
    if !current_user.nil?
      existing_vote = @article.vote_articles.find_by(user_id: current_user.id)
      if existing_vote && existing_vote.value == params[:value]
          existing_vote.destroy
          update_numVote(value, -1)
          respond_to do |format|
            format.html { redirect_back fallback_location: root_path, notice:  'Vote removed successfully' }
            format.json { render json: { message: 'Vote removed successfully' }, status: :ok }
          end
      else
        if existing_vote && existing_vote.value != params[:value]
          existing_vote.destroy
          if 'up' == params[:value]
            @article.votes_down -=1
          else
            @article.votes_up -=1
          end
        end
        @vote_article = current_user.vote_articles.build(article_id: @article.id, value: params[:value])
        update_numVote(params[:value], +1)
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
    else
      respond_to do |format|
        format.html { redirect_to new_user_session_path, notice:  'Only web functionality' }
        format.json { render json: { message: 'Only web functionality' }, status: :unauthorized }
      end
    end
  end

  def unvote_up
    unvote_api('up')
  end

  def unvote_down
    unvote_api('down')
  end

  def boost_web
    if current_user.nil?
      respond_to do |format|
        format.html {redirect_back(fallback_location: root_path, notice: 'Only web access')}
        format.json {render  json: { message: 'Only web access' }, status: :unauthorized }
      end
      return
    end
    if current_user.boosted_articles.exists?(id: @article.id)
      # If the user has already boosted the article, delete the existing boost
      if current_user.boosts.find_by(article_id: @article.id).destroy
        update_num_boost(-1)
        respond_to do |format|
          format.html {redirect_back(fallback_location: root_path, notice: 'Boost removed successfully!')}
          format.json {render  json: { message: 'Boost removed successfully' }, status: :ok }
        end
      end
    else
      # If the user hasn't boosted the article yet, create a new boost
      boost = current_user.boosts.build(article_id: @article.id)
      if boost.save
        update_num_boost(1)
        @article.reload
        respond_to do |format|
          format.html {redirect_back(fallback_location: root_path, notice: 'Article boosted successfully!')}
          format.json {render json: @article.as_custom_json, status: :created }
        end
      else
        respond_to do |format|
          format.html {redirect_back(fallback_location: root_path, notice: 'Unable to boost article')}
          format.json {render json:{ error: 'Unable to boost article' }, status: :unprocessable_entity }
        end
      end
    end
  end

  def boost
    if @user.boosted_articles.exists?(id: @article.id)
      # If the user has already boosted the article, delete the existing boost
      respond_to do |format|
        format.html {redirect_back(fallback_location: root_path, notice: 'You have already boosted this article')}
        format.json {render  json: { message: 'You have already boosted this article' }, status: :unprocessable_entity }
      end
    else
      # If the user hasn't boosted the article yet, create a new boost
      boost = @user.boosts.build(article_id: @article.id)
      respond_to do |format|
        if boost.save
          update_num_boost(1)
          @article.reload
          format.html {redirect_back(fallback_location: root_path, notice: 'Article boosted successfully!')}
          format.json {render json: { article: @article.as_custom_json, boost: boost }, status: :created }
        else
          format.html {redirect_back(fallback_location: root_path, notice: 'Unable to boost article')}
          format.json {render json:{ error: 'Unable to boost article' }, status: :unprocessable_entity }
        end
      end
    end
  end

  def unboost
    if @user.boosted_articles.exists?(id: @article.id)
      # If the user has already boosted the article, delete the existing boost
      respond_to do |format|
        if @user.boosts.find_by(article_id: @article.id).destroy
          update_num_boost(-1)
          format.html {redirect_back(fallback_location: root_path, notice: 'Boost removed successfully!')}
          format.json {render  json: { message: 'Boost removed successfully' }, status: :ok }
        else
          format.html { redirect_back(fallback_location: root_path, notice: "ERROR DELETE Boost" )}
          format.json { render json: @article.errors, status: :unprocessable_entity }
        end
      end
    else
      respond_to do |format|
        format.html { redirect_back(fallback_location: root_path, notice: "Boost not found" )}
        format.json { render json: { error: 'Boost not found' }, status: :not_found }
      end
    end
  end

  def commentOrder
    @article = Article.find(params[:id])
    @commentOrder_filter = params[:commentOrder]
    case params[:commentOrder]
    when 'top'
      @commentOrder_filter = 'top'
    when 'newest'
      @commentOrder_filter = 'newest'
    when 'oldest'
      @commentOrder_filter = 'oldest'
    end
    render :show
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_article
      #@article = Article.find(params[:id])
      @article = Article.includes(:user, :magazine, :vote_articles, :boosts, :comments).find(params[:id])
    rescue ActiveRecord::RecordNotFound => e
      respond_to do |format|
        format.html { redirect_to articles_url, alert: 'Article not found.' }
        format.json { render json: { error:  e.message }, status: :not_found }
      end
      return
    end

    # Only allow a list of trusted parameters through.
    def article_params
      params.require(:article).permit(:title, :body, :article_type, :url, :author, :magazine_id)
    end

  def update_num_boost(count)
    @article.num_boosts += count
    @article.save
  end


  def update_numVote(value, count)
    if value == 'up'
      @article.votes_up += count
    elsif value == 'down'
      @article.votes_down += count
    end
    @article.save
  end

  def vote_api(value)
    if current_user.nil?
      existing_vote = @article.vote_articles.find_by(user_id: @user.id)
      if existing_vote
        respond_to do |format|
          format.html { redirect_back fallback_location: root_path, notice:  'You have already voted this article' }
          format.json { render json: { message: 'You have already voted this article', existing_vote: existing_vote }, status: :unprocessable_entity }
        end
      else
        @vote_article = @user.vote_articles.build(article_id: @article.id, value: value)
        update_numVote(value, +1)
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
  end

  def unvote_api(value)
    if current_user.nil?
      existing_vote = @article.vote_articles.find_by(user_id: @user.id)
      if existing_vote
          existing_value = existing_vote.value
          if existing_value != value
            respond_to do |format|
              format.html { redirect_back fallback_location: root_path, notice:  'Unvote with incorrect value' }
              format.json { render json: { message: 'Unvote with incorrect value', existing_vote: existing_vote }, status: :unprocessable_entity }
            end
          else
            existing_vote.destroy
            update_numVote(value, -1)
            respond_to do |format|
              format.html { redirect_back fallback_location: root_path, notice:  'Vote removed successfully' }
              format.json { render json: { message: 'Vote removed successfully' }, status: :ok }
            end
          end
      else
        respond_to do |format|
          format.html { redirect_back fallback_location: root_path, notice:  'Vote Not found' }
          format.json { render json: { message: 'Vote Not found' }, status: :not_found }
        end
      end
    end
  end

  def authenticate_user!
    if current_user.nil?
      if request.headers['Accept'].present? && !request.headers['Authorization'].present?
        respond_to do |format|
          format.html { redirect_to new_user_session_path, alert: "Missing api key" }
          format.json { render(json: { "error": "Missing api key" }, status: 400) }
        end
        return
      end
      if request.headers['Authorization']
        @user = User.find_by(api_key: request.headers['Authorization'])
        unless @user
          respond_to do |format|
            format.html { redirect_to new_user_session_path, alert: "No user with this apikey" }
            format.json { render(json: { "error": "No user with this apikey" }, status: 401) }
          end
          return
        end
      else
        respond_to do |format|
          format.html { redirect_to new_user_session_path, alert: 'You must be logged in to perform this action.' }
          format.json { render(json: { "error": "Not logged in AUTH" }, status: 401) }
        end
        return
      end
    else
      @user = current_user
    end
  end

  def check_owner
    article_owner = @article.user
    unless article_owner == @user
      respond_to do |format|
        format.html { redirect_to articles_url, alert: 'You are not authorized to perform this action.' }
        format.json { render json: { error: 'You are not authorized to perform this action' }, status: :forbidden }
      end
      return
    end
  end

end