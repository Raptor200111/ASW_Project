class CommentsController < ApplicationController
  before_action :set_comment, only: %i[ show edit update destroy vote_up vote_down ]

  # GET /comments or /comments.json
  def index
    @comments = Comment.all
  end

  # GET /comments/1 or /comments/1.json
  def show
  end

  # GET /comments/new
  def new
    @article = Article.find(params[:article_id])
    @comment = @article.comments.new(parent_id: params[:parent_id])
  end

  # GET /comments/1/edit
  def edit
    @article = Article.find(params[:article_id])
    if !current_user.nil? and @comment.user == current_user
      render :edit
    else
      # Redirect with a notice indicating they are not allowed to edit the article
      redirect_to @article, notice: "You are not allowed to edit this comment."
    end
  end

  # POST /comments or /comments.json
  def create

    @article = Article.find(params[:article_id])

    if current_user.nil?
      respond_to do |format|
        format.html {redirect_to @article, notice: "You need to log in to comment."}
        format.json {head :no_content}
      end
      return
    end

    @comment = @article.comments.new(comment_params) do |c|
      c.user = current_user
    end

    @comment.votes_down = 0;
    @comment.votes_up = 0;

    respond_to do |format|
      if @comment.save
        format.html { redirect_to @article, notice: "Comment was successfully created." }
        format.json { render :show, status: :created, location: @comment }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @comment.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /comments/1 or /comments/1.json
  def update
    @article = Article.find(params[:article_id])

    respond_to do |format|
      if @comment.update(comment_params)
        format.html { redirect_to @article, notice: "Comment was successfully updated." }
        format.json { render :show, status: :ok, location: @comment }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @comment.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /comments/1 or /comments/1.json
  def destroy
    @article = Article.find(params[:article_id])
    @comment = @article.comments.find(params[:id])
    if !current_user.nil? and @article.user == current_user
      @comment.destroy
      respond_to do |format|
        format.html { redirect_to @article, notice: "Comment was successfully destroyed." }
        format.json { head :no_content }
      end
    else
      respond_to do |format|
        format.html { redirect_to @article, notice: "You are not allowed to delete this comment." }
        format.json { head :forbidden }
      end
    end
  end

  #vote_up /
  def vote_up
    vote('up')
  end

    #vote_down /
  def vote_down
    vote('down')
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_comment
      @comment = Comment.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def comment_params
      params.require(:comment).permit(:body, :article_id, :parent_id)
    end

    def vote(value)
      @article = Article.find(params[:article_id])
      @comment = @article.comments.find(params[:id])

      if !current_user.nil?
        existing_vote = @comment.vote_comments.find_by(user_id: current_user.id)
        if existing_vote
          if existing_vote.value != value
            existing_vote.update(value: value)
            flash[:notice] = "Vote changed."
          else
            existing_vote.destroy
            flash[:notice] = "Unvoted successfully."
          end
        else
          @vote = current_user.vote_comments.build(comment_id: @comment.id, value: value)
          if @vote.save
            flash[:notice] = "Voted successfully."
          else
            current_user.vote_comments.destroy
            flash[:notice] = "Error voting"
            flash[:notice] = @vote.errors.full_messages
            flash[:notice] = @vote
            flash[:notice] = value
          end
        end
      else
        flash[:notice] = "You must be logged in to vote"
      end
      redirect_back(fallback_location: @article)
    end
end
