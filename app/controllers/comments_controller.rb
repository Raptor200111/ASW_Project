class CommentsController < ApplicationController
  before_action :set_comment, only: %i[ show edit update destroy vote_up vote_down ]
  before_action :authenticate_user!, only: %i[ create update destroy vote_up vote_down]

  # GET /comments or /comments.json
  def index
    @article = Article.find(params[:article_id])
    @comments = @article.comments

    order = params[:order]
    case order
    when 'oldest'
      @comments = @comments.order(created_at: :asc)
    when 'newest'
      @comments = @comments.order(created_at: :desc)
    else
      @comments = @comments.order(votes_up: :desc)
    end

    # prints the comments and their replies (prints duplicates for each reply?)
    render json: @comments.as_json(include: :replies)
  end

  # GET /comments/1 or /comments/1.json
  def show
    render :json => @comment
  end

  # GET /comments/new
  def new
    @article = Article.find(params[:article_id])
    @comment = @article.comments.new(parent_id: params[:parent_id])
  end

  # GET /comments/1/edit
  # def edit
  #   @article = Article.find(params[:article_id])
  #   if (check_owner())
  #     render :edit
  #   else
  #     format.json { render json: "you are not the owner" }
  #     format.html { redirect_to @article, notice: "You are not allowed to edit this comment." }
  #   end
  # end

  # POST /comments or /comments.json
  def create
    #create comment with given and default values
    @article = Article.find(params[:article_id])
    @comment = @article.comments.new(comment_params) do |c|
      c.user = @current_user
    end
    @comment.votes_down = 0;
    @comment.votes_up = 0;

    #returns the comment in json format
    respond_to do |format|
      if @comment.save
        format.json { render json: @comment }
        format.html { redirect_to @article, notice: "Comment was successfully created." }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @comment.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /comments/1
  def update
    @article = Article.find(params[:article_id])
    @comment = @article.comments.find(params[:id])

    if check_owner()
      if @comment.update(comment_params)
        respond_to do |format|
          format.html { redirect_to @article, notice: "Comment was successfully updated." }
          format.json { render json: @comment }
        end
      else
        respond_to do |format|
          format.html { render :edit, status: :unprocessable_entity }
          format.json { render json: @comment.errors, status: :unprocessable_entity }
        end
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: "you are not the owner" + @current_user.id.to_s}
      end
    end
  end

  # DELETE /comments/1
  def destroy
    @article = Article.find(params[:article_id])
    @comment = @article.comments.find(params[:id])

    if check_owner()
      @comment.destroy
      respond_to do |format|
        format.html { redirect_to @article, notice: "Comment was successfully destroyed." }
        format.json { render json: {message: "Comment was successfully destroyed."} }
      end
    else
      respond_to do |format|
        format.html { redirect_to @article, notice: "You are not allowed to delete this comment." }
        format.json { render json: {message: "You are not allowed to delete this comment."} }
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

      existing_vote = @comment.vote_comments.find_by(user_id: current_user.id)
      if existing_vote
        if existing_vote.value != value
          existing_vote.update(value: value)
          # flash[:notice] = "Vote changed."
        else
          existing_vote.destroy
          # flash[:notice] = "Unvoted successfully."
        end
      else
        @vote = current_user.vote_comments.build(comment_id: @comment.id, value: value)
        if @vote.save
          # flash[:notice] = "Voted successfully."
        else
          current_user.vote_comments.destroy
          # flash[:notice] = "Error voting"
          # flash[:notice] = @vote.errors.full_messages
          # flash[:notice] = @vote
          # flash[:notice] = value
          render json: @vote.errors, status: :unprocessable_entity
          return
        end
      end
      @comment.votes_up = @comment.vote_comments.where(value: 'up').count
      @comment.votes_down = @comment.vote_comments.where(value: 'down').count
      @comment.save
      render json: @comment
      # redirect_back(fallback_location: @article)
    end

    #api key authentication (hardcoded)
    def authenticate_user!
      #hardcoded user login for testing
      @current_user = User.find_by(id: 1)

      unless @current_user
        respond_to do |format|
          format.html { redirect_to new_user_session_path, alert: 'You must be logged in to perform this action.' }
          format.json { render(json: {"error": "Not logged in AUTH"}, status: 401)}
        end
      end
    end

    # check if the user is the owner of the comment
    def check_owner
      @comment = Comment.find(params[:id])
      if @current_user == @comment.user
        return true
      else
        return false
      end
    end

end
