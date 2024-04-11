class ArticlesController < ApplicationController
  before_action :set_article, only: %i[ show edit update destroy vote_up vote_down]

  # GET /articles or /articles.json
  def index
    @active_filter = params[:filter] || 'newest'
    case params[:filter]
    when 'hot'
      @articles = Article.all.order(votes_up: :desc)
    else
      @articles = Article.all.order(created_at: :desc)
    end
  end

  # GET /articles/1 or /articles/1.json
  def show
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


  private
    # Use callbacks to share common setup or constraints between actions.
    def set_article
      @article = Article.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def article_params
      params.require(:article).permit(:title, :body, :url, :author)
    end
end
