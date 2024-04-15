class ArticlesController < ApplicationController
  before_action :set_article, only: %i[ show edit update destroy vote_up vote_down toggle_boosted]

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
      @articles = @articles.order(votes_up: :desc)
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
    @show_url_field = false
  end


  #GET /articles/new_link
  def new_link
    @article = Article.new
    @show_url_field = true
  end

  # GET /articles/1/edit
  def edit
  end

  # POST /articles or /articles.json
  def create
    @article = Article.new(article_params)

    respond_to do |format|
      if @article.save
        if session[:created_ids].nil?
           session[:created_ids]= [@article.id] #.push(@article.id)
        else
           session[:created_ids].push(@article.id)
        end
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
    if session[:created_ids].nil? || !session[:created_ids].include?(@article.id)
      respond_to do |format|
        format.html { redirect_to root_path, notice: "You are not allowed to delete this article" }
        format.json { head :forbidden }
        end

    else
      session[:created_ids].delete(@article.id)
      @article.destroy

     respond_to do |format|
       format.html { redirect_to articles_url, notice: "Article was successfully destroyed." }
       format.json { head :no_content }
      end
    end
  end
  #vote_up /
  def vote_up
    @article.votes_up+=1
    if @article.save
        respond_to do |format|
          format.html { redirect_to root_path, notice: "article was successfully VoteUp." }
          format.json { head :no_content }
        end
    else
        respond_to do |format|
          format.html { redirect_to root_path notice: "NOT VoteUp" }
          format.json { head :no_content }
        end
    end
  end

    #vote_down /
  def vote_down
    @article.votes_down+=1
    if @article.save
        respond_to do |format|
          format.html { redirect_to root_path, notice: "article was successfully VoteDown." }
          format.json { head :no_content }
        end
    else
        respond_to do |format|
          format.html { redirect_to root_path notice: "NOT VoteDown" }
          format.json { head :no_content }
        end
    end
  end


  def toggle_boosted
    @article.toggle_boost!
    if @article.save
        respond_to do |format|
          format.html { redirect_to root_path, notice: "Article boost status toggled successfully." }
          format.json { head :no_content }
        end
    else
        respond_to do |format|
          error_messages = @article.errors.full_messages.join(", ")
          format.html { redirect_to article_url(@article), notice: "NOT Boosted: #{error_messages}" }
          format.json { head :no_content }
        end
    end
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
end
