class ArticlesController < ApplicationController
  before_action :authenticate_user!, only: [:create, :update, :destroy, :boost, :vote_up, :vote_down]
  before_action :set_article, only: %i[ show edit update destroy vote_up vote_down boost]
  before_action :check_owner, only: [:update, :destroy]

  # GET /articles or /articles.json
  def index
    # Retrieve filter and order parameters
    @order_filter = params[:order_filter] || 'newest'
    @type = params[:type]

  # Check if order_filter is valid
    unless %w(newest top commented).include?(@order_filter)
      return render json: { error: "Invalid order_filter parameter. It must be 'newest', 'top', or 'commented'" }, status: :unprocessable_entity
    end

    # Check if type is valid
    unless %w(link thread all).include?(@type)
      return render json: { error: "Invalid type parameter. It must be 'link', 'thread', or 'all'" }, status: :unprocessable_entity
    end

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
    if current_user.nil?
      @user = User.find(params[:user_id]) # Assuming you have user_id in the params
      @article = @user.articles.build(article_params)
    else
      @article = current_user.articles.build(article_params)
    end
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
    if current_user.nil?
      respond_to do |format|
        if @article.update(article_params)
          format.html { redirect_to article_url(@article), notice: "Article was successfully updated." }
          format.json { render json: @article.as_custom_json, status: :ok }
        else
          format.html { render :edit, status: :unprocessable_entity }
          format.json { render json: @article.errors, status: :unprocessable_entity }
        end
      end
    else
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
  end

  # DELETE /articles/1 or /articles/1.json
  def destroy
    @votes = @article.vote_articles

    respond_to do |format|
      if @article.destroy
        format.html { redirect_to articles_url, notice: "Article was successfully destroyed." }
        format.json { head :no_content }
      else
        format.html { redirect_to article_url(@article), notice: "ERROR DELETE" }
        format.json { render json: @article.errors, status: :unprocessable_entity }
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
      @uid = 3
      @user = User.find(@uid)
      @existing_boost = @user.boosts.find_by(article: @article)
    else
      @existing_boost = current_user.boosts.find_by(article: @article)
    end
    begin
      if @existing_boost
        @existing_boost.destroy
        @article.num_boosts -=1
        @article.save
        respond_to do |format|
          format.html {redirect_back(fallback_location: root_path, notice: 'Boost removed successfully!')}
          format.json {render  json: { message: 'Boost removed successfully' }, status: :ok }
        end
      else
        if current_user.nil?
          @user.boosts.create!(article: @article)
        else
          current_user.boosts.create!(article: @article)
        end
        @article.num_boosts +=1
        @article.save
        @article_show =  Article.includes(:user, :magazine, :vote_articles, :boosts, :comments).find(@article.id)
        respond_to do |format|
          format.html {redirect_back(fallback_location: root_path, notice: 'Article boosted successfully!')}
          format.json {render json: @article_show.as_custom_json, status: :ok }
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
      #@article = Article.find(params[:id])
      @article = Article.includes(:user, :magazine, :vote_articles, :boosts, :comments).find(params[:id])
    rescue ActiveRecord::RecordNotFound
      respond_to do |format|
        format.html { redirect_to articles_url, alert: 'Article not found.' }
        format.json { render json: { error: "Not Found" }, status: :not_found }
      end
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
            change_vote_value(@article, value)
            flash[:notice] = "Vote changed"
          else
            existing_vote.destroy
            change_vote(@article, value, '-')
            flash[:notice] = "UnVoted successfully"
          end
        else
          @vote = current_user.vote_articles.build(article_id: @article.id, value: value)
          change_vote(@article, value, '+')
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

    def change_vote_value(article, value)
      if value == 'up'
        article.votes_down -=1
        article.votes_up +=1
      else
        article.votes_down +=1
        article.votes_up -=1
      end
      article.save
    end
    def change_vote(article, value, operation)
      if operation == '+' and value == 'up'
        article.votes_up += 1
      elsif operation == '+' and value == 'down'
        article.votes_down += 1
      elsif operation == '-' and value == 'up'
        article.votes_up -= 1
      elsif operation == '-' and value == 'down'
        article.votes_down -= 1
      end
      article.save
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
        if current_user != @article.user
          respond_to do |format|
            format.html { redirect_to articles_url, alert: 'You are not authorized to perform this action.' }
            format.json { render json: { error: 'You are not authorized to perform this action' }, status: :forbidden }
          end
        end
      end
    end

end