class CommentsController < ApplicationController
  # selecciona el comentari i l'article
  before_action :set_comment, only: %i[ show update destroy vote_up vote_down ]

  #comprova que l'usuari estigui loggejat
  before_action :authenticate_user!, only: %i[ create update destroy vote_up vote_down]

  #comprova que l'usuari sigui el propietari del comentari
  before_action :check_owner, only: %i[ update destroy ]

  # GET /comments
  def index
    #agafa tots els comentaris de l'article
    begin
      @article = Article.find(params[:article_id])
    rescue ActiveRecord::RecordNotFound => e
      render json: { error: e.message }, status: :not_found
      return
    end
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
    # busca el article amb l'id donat
    begin
      @article = Article.find(params[:article_id])
    rescue ActiveRecord::RecordNotFound => e
      render json: { error: e.message }, status: :not_found
      return
    end

    # crea comentari amb valors donats i per defecte
    begin
      @comment = @article.comments.new(comment_params) do |c|
        c.user = @user
        c.votes_down = 0;
        c.votes_up = 0;
      end
    rescue ActionController::ParameterMissing
      render json: {error: "You didn't provide all the required fields"}, status: :bad_request
      return
    end
    
    # retorna el comentari creat
    @comment.save
    render json: @comment
  end

  # PATCH /comments/1
  def update
    # actualitza el comentari amb els valors donats
    begin
      @comment.update(comment_params)
      render json: @comment
    rescue ActionController::ParameterMissing
      render json: {error: "You didn't provide all the required fields"}, status: :bad_request
      return
    end
  end

  # DELETE /comments/1
  def destroy
    # comprova si l'usuari es el propietari del comentari
    check_owner()

    # retorna missatge de comentari eliminat
    @comment.destroy
    render json: {message: "Comment was successfully destroyed."}
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
      begin
        @article = Article.find(params[:article_id])
        @comment = Comment.find(params[:id])
      rescue ActiveRecord::RecordNotFound => e
        render json: { error: e.message }, status: :not_found
        return
      end
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

    def authenticate_user!
      if current_user.nil?
        if request.headers['Accept'].present? && !request.headers['Authorization'].present?
          render(json: { "error": "Missing api key" }, status: 400)
          return
        end
        if request.headers['Authorization']
          @user = User.find_by(api_key: request.headers['Authorization'])
          unless @user
            render(json: { "error": "No user with this apikey" }, status: 401)
            return
          end
        else
          render(json: { "error": "Not logged in AUTH" }, status: 401)
          return
        end
      else
        @user = current_user
      end
    end

    # check if the user is the owner of the comment
    def check_owner
      @comment = Comment.find(params[:id])
      unless @user == @comment.user
        render(json: {"error": "You provided an invalid token"}, status: 403)
        return
      end
    end
end
