class ArticlesController < ApplicationController
  before_action :set_article, only: %i[ show edit update destroy vote_up vote_down boost]

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
  end

  # GET /articles/1 or /articles/1.json
  def show
  end

  def search
    @search_text = params[:search_text]
    @articles = Article.where("title LIKE ? OR body LIKE ?", "%#{@search_text}%", "%#{@search_text}%")
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
    if current_user.nil?
      respond_to do |format|
        format.html {redirect_to new_user_session_path, notice: 'You need to log in to create article.'}
        format.json {head :no_content }
      end
      return
    end

    @article = current_user.articles.build(article_params)
    respond_to do |format|
      if @article.save
#        if session[:created_ids].nil?
#           session[:created_ids]= [@article.id] #.push(@article.id)
#        else
#           session[:created_ids].push(@article.id)
#        end
        format.html { redirect_to article_url(@article), notice: "Article was successfully created." }
        format.json { render :show, status: :created, location: @article }
      else
        @show_url_field = @article.url_required?
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @article.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /articles/1 or /articles/1.json
  def update
    respond_to do |format|
      if @article.update(article_params)
        format.html { redirect_to article_url(@article), notice: "Article was successfully updated." }
        format.json { render :show, status: :ok, location: @article }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @article.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /articles/1 or /articles/1.json
  def destroy
    @article = Article.find(params[:id])

    # Check if the current user is the creator of the article
    if !current_user.nil? and @article.user == current_user
      @article.destroy
      respond_to do |format|
        format.html { redirect_to articles_url, notice: "Article was successfully destroyed." }
        format.json { head :no_content }
      end
    else
      respond_to do |format|
        format.html { redirect_to root_path, notice: "You are not allowed to delete this article." }
        format.json { head :forbidden }
      end
    end
  end
  #/articles/:id/vote_up
  def vote_up
    vote('up')
  end

    #/articles/:id/vote_down
  def vote_down
    vote('down')
  end

  def boost
    if current_user.nil?
      respond_to do |format|
        format.html {redirect_to new_user_session_path, notice: 'You need to log in to boost.'}
        format.json {head :no_content }
      end
      return
    end
    existing_boost = current_user.boosts.find_by(article: @article)
    begin
      if existing_boost
        existing_boost.destroy
        respond_to do |format|
          format.html {redirect_back(fallback_location: root_path, notice: 'Boost removed successfully!')}
          format.json {render :show, status: :ok, location: @article }
        end
      else
        current_user.boosts.create!(article: @article)
        respond_to do |format|
          format.html {redirect_back(fallback_location: root_path, notice: 'Article boosted successfully!')}
          format.json {render :show, status: :ok, location: @article }
        end
      end
    rescue ActiveRecord::RecordInvalid => e
      respond_to do |format|
        format.html {redirect_to root_path, alert: "Error: #{e.message}"}
        format.json { render json: @article.errors, status: :unprocessable_entity }
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
      @article = Article.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def article_params
      params.require(:article).permit(:title, :body, :article_type, :url, :author, :magazine_id)
    end

    def vote(value)
      if !current_user.nil?
        existing_vote = @article.vote_articles.find_by(user_id: current_user.id)
        if existing_vote
          if existing_vote.value != value
            existing_vote.update(value: value)
            flash[:notice] = "Vote changed"
          else
            existing_vote.destroy
            flash[:notice] = "UnVoted successfully"
          end
        else
          @vote = current_user.vote_articles.build(article_id: @article.id, value: value)
          if @vote.save
            flash[:success] = "Voted successfully"
          else
            current_user.vote_articles.destroy
            flash[:success] = "Error Vote"
          end
        end
      end
      if current_user.nil?
        redirect_to new_user_session_path
      else
        redirect_back(fallback_location: root_path)
      end
    end

end