class CommentsController < ApplicationController
  before_action :set_comment, only: %i[ show update destroy vote_up vote_down ]

  #comprova que l'usuari estigui loggejat
  before_action :authenticate_user!, only: %i[ create update destroy vote_up vote_down]

  # GET /comments
  def index
    #agafa tots els comentaris de l'article
    @article = Article.find(params[:article_id])
    @comments = @article.comments

    #ordenacio per default es votes_up
    order = params[:order]
    case order
    when 'oldest'
      @comments = @comments.order(created_at: :asc)
    when 'newest'
      @comments = @comments.order(created_at: :desc)
    else
      @comments = @comments.order(votes_up: :desc)
    end

    # mostra tots els comentaris i els seus fills si en tenen
    render json: @comments.as_json(include: :replies)
  end

  # GET /comments/1
  def show
    # nomes mostra un comentari i els seus fills
    render :json => @comment.as_json(include: :replies)
  end

  # POST /comments
  def create
    # crea comentari amb valors donats i per defecte
    @article = Article.find(params[:article_id])
    @comment = @article.comments.new(comment_params) do |c|
      c.user = @current_user
      c.votes_down = 0;
      c.votes_up = 0;
    end
    
    # retorna el comentari creat
    if @comment.save
      render json: @comment
    else
      render json: @comment.errors, status: :unprocessable_entity
    end
  end

  # PATCH /comments/1
  def update
    @article = Article.find(params[:article_id])
    @comment = @article.comments.find(params[:id])

    # comprova si l'usuari es el propietari del comentari
    if check_owner()
      # retorna el comentari actualitzat
      if @comment.update(comment_params)
        render json: @comment
      else
        render json: @comment.errors, status: :unprocessable_entity
      end
    else
      # retorna error si l'usuari no es el propietari
      format.json { render json: "you are not the owner" }
    end
  end

  # DELETE /comments/1
  def destroy
    @article = Article.find(params[:article_id])
    @comment = @article.comments.find(params[:id])

    if check_owner()
      # retorna missatge de comentari eliminat
      @comment.destroy
      render json: {message: "Comment was successfully destroyed."}
    else
      # retorna error si l'usuari no es el propietari
      render json: {message: "You are not allowed to delete this comment."}
    end
  end

  # POST /comments/1/vote_up
  def vote_up
    vote('up')
  end

  # POST /comments/1/vote_down
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
          # canvia valor del vot si es diferent
          existing_vote.update(value: value)
        else
          # elimina vot si es el mateix
          existing_vote.destroy
        end
      else
        @vote = current_user.vote_comments.build(comment_id: @comment.id, value: value)
        unless @vote.save
          # crea vot si no existeix
          # retorna error si no es pot crear
          current_user.vote_comments.destroy
          render json: @vote.errors, status: :unprocessable_entity
          return
        end
      end

      # actualitza els vots del comentari
      @comment.votes_up = @comment.vote_comments.where(value: 'up').count
      @comment.votes_down = @comment.vote_comments.where(value: 'down').count
      @comment.save

      # retorna el comentari actualitzat
      render json: @comment
    end

    #api key authentication (hardcoded)
    def authenticate_user!
      #hardcoded user login for testing
      @current_user = User.find_by(id: 1)

      unless @current_user
        render(json: {"error": "Not logged in AUTH"}, status: 401)
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
