class CommentsController < ApplicationController
  skip_before_action :verify_authenticity_token
  # selecciona el comentari i l'article
  before_action :set_comment, only: %i[ show update destroy vote_up vote_down remove_vote_up remove_vote_down]

  #comprova que l'usuari estigui loggejat
  before_action :authenticate_user!, only: %i[ create update destroy vote_up vote_down remove_vote_up remove_vote_down]

  #comprova que l'usuari sigui el propietari del comentari
  before_action :check_owner, only: %i[ update destroy ]

  # GET /comments
  def index
    #agafa tots els comentaris pare de l'article
    begin
      @article = Article.find(params[:article_id])
    rescue ActiveRecord::RecordNotFound => e
      render json: { error: e.message }, status: :not_found
      return
    end
    @comments = @article.comments.where(parent_id: nil)

    #ordenacio per default es votes_up
    order = params[:order]
    case order
    when 'oldest'
      @comments = @comments.order(created_at: :asc)
    when 'newest'
      @comments = @comments.order(created_at: :desc)
    when nil
      @comments = @comments.order(votes_up: :desc)
    else
      render json: { error: "Invalid order parameter" }, status: :bad_request
      return
    end

    # mostra tots els comentaris i els seus fills si en tenen (as_json modificat en comment.rb)
    render json: @comments.as_json
  end

  # GET /comments/1
  def show
    # nomes mostra un comentari i els seus fills
    render :json => @comment.as_json(include: :replies)
  end

  # POST /comments
  def create
    begin
      # busca el article amb l'id donat
      @article = Article.find(params[:article_id])

      # crea comentari amb valors donats i per defecte
      @comment = @article.comments.new(comment_params) do |c|
        c.user = @user
        c.votes_down = 0;
        c.votes_up = 0;
      end
    rescue ActionController::ParameterMissing
      render json: {error: "You didn't provide all the required fields"}, status: :bad_request
      return
    rescue ActiveRecord::RecordNotFound => e
      render json: { error: e.message }, status: :not_found
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

  # DELETE /comments/1/vote_up
def remove_vote_up
  remove_vote('up')
end

# DELETE /comments/1/vote_down
def remove_vote_down
  remove_vote('down')
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

    # def vote(value)
    #   existing_vote = @comment.vote_comments.find_by(user_id: @user.id)
    #   if existing_vote
    #     if existing_vote.value != value
    #       # canvia valor del vot si es diferent
    #       existing_vote.update(value: value)
    #     else
    #       # elimina vot si es el mateix
    #       existing_vote.destroy
    #     end
    #   else
    #     @vote = @user.vote_comments.build(comment_id: @comment.id, value: value)
    #     unless @vote.save
    #       # crea vot si no existeix
    #       # retorna error si no es pot crear
    #       @user.vote_comments.destroy
    #       render json: @vote.errors, status: :unprocessable_entity
    #       return
    #     end
    #   end

    #   # actualitza els vots del comentari
    #   @comment.votes_up = @comment.vote_comments.where(value: 'up').count
    #   @comment.votes_down = @comment.vote_comments.where(value: 'down').count
    #   @comment.save

    #   # retorna el comentari actualitzat
    #   render json: @comment
    # end

    def vote(value)
      existing_vote = @comment.vote_comments.find_by(user_id: @user.id)
    
      if existing_vote
        # Update the value of the vote if it's different
        existing_vote.update(value: value) if existing_vote.value != value
      else
        # Create a new vote if it doesn't exist
        @vote = @user.vote_comments.build(comment_id: @comment.id, value: value)
        unless @vote.save
          render json: @vote.errors, status: :unprocessable_entity
          return
        end
      end

      @comment.votes_up = @comment.vote_comments.where(value: 'up').count
      @comment.votes_down = @comment.vote_comments.where(value: 'down').count
      @comment.save
      render json: @comment
    end
    
    def remove_vote(value)
      existing_vote = @comment.vote_comments.find_by(user_id: @user.id)
    
      if existing_vote
        # Update the value of the vote if it's different
        existing_vote.destroy if existing_vote.value == value
      end

      @comment.votes_up = @comment.vote_comments.where(value: 'up').count
      @comment.votes_down = @comment.vote_comments.where(value: 'down').count
      @comment.save
      render json: @comment
    end

    def authenticate_user!
      if current_user.nil?
        if request.headers['Accept'].present? && !request.headers['Authorization'].present?
          render(json: { "error": "Missing api key" }, status: 401)
          return
        end
        if request.headers['Authorization']
          @user = User.find_by(api_key: request.headers['Authorization'])
          unless @user
            render(json: { "error": "No user with this apikey" }, status: 401)
            return
          end
        else
          render(json: { "error": "Missing api key" }, status: 401)
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
