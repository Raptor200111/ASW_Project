class MagazinesController < ApplicationController
  before_action :set_magazine, only: %i[ show edit update destroy subscribe unsubscribe]

  # GET /magazines or /magazines.json
  def index
    @mag = Magazine.all
    @mag.each do |magazine|
      magazine.nComms=0
    	magazine.articles.each do |article|
    		magazine.nComms += article.comments.count
    	end
    	magazine.save
    end

    @magazines = Magazine.order(params[:sort])
    if params[:sort] == "threads"
      @magazines = Magazine.all.sort_by{|magazine| magazine.articles.size }.reverse
    elsif params[:sort] == "comments"
      @magazines = Magazine.all.sort_by{|magazine| magazine.nComms}.reverse
    elsif params[:sort] == "subs"
      @magazines = Magazine.all.sort_by{|magazine| magazine.subscribers.size}.reverse
    end
  end

  # GET /magazines/1 or /magazines/1.json
  def show
    @magazine.nComms=0
  	@magazine.articles.each do |article|
  		@magazine.nComms += article.comments.count
  	end
  end

  # GET /magazines/new
  def new
    @magazine = Magazine.new
  end

  # GET /magazines/1/edit
  def edit
  end

  # POST /magazines or /magazines.json
  def create
    if request.headers['Accept'].present?
      if !User.exists?(token: request.Authorization['API key'])
        respond_to do |format|
          format.json { render(json: {"error": "Not logged in"}, status: 401)}
        end
      else
        @magazine = Magazine.new(request.body)
        respond_to do |format|
          if @magazine.save
            format.json { render :show, status: :created, location: @magazine }
          else
            format.json { render(json: {"error": "Missing parameter in body"}, status: 400)}
          end
        end
      end
    else
      if current_user.nil?
        respond_to do |format|
          format.html {redirect_to magazines_path, notice: 'You need to log in to subscribe.'}
          format.json {head :no_content }
        end
        return
      end
      @magazine = Magazine.new(magazine_params)

      respond_to do |format|
        if @magazine.save
          format.html { redirect_to magazine_url(@magazine), notice: "Magazine was successfully created." }
          format.json { render :show, status: :created, location: @magazine }
        else
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: @magazine.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  # PATCH/PUT /magazines/1 or /magazines/1.json
  def update
    respond_to do |format|
      if @magazine.update(magazine_params)
        format.html { redirect_to magazine_url(@magazine), notice: "Magazine was successfully updated." }
        format.json { render :show, status: :ok, location: @magazine }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @magazine.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /magazines/1 or /magazines/1.json
  def destroy
    @magazine.destroy

    respond_to do |format|
      format.html { redirect_to magazines_url, notice: "Magazine was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  # POST /magazines/1/subscribe
  def subscribe
    # comportament http
    if request.headers['Accept'].present?
      if !User.exists?(api_key: request.Authorization['API key'])
        respond_to do |format|
          format.json { render(json: {"error": "Not logged in"}, status: 401)}
        end
      else
        @user = User.find(api_key: request.Authorization['API key'])
        isSubs = @user.find_by(magazine: @magazine)
        begin
        if isSubs
          respond_to do |format|
            format.json { render(json: {"error": "Already subscribed"}, status: 204)}
          end
        else
          @user.subs << @magazine
          respond_to do |format|
            format.html {redirect_to magazines_path, notice: 'Subscribed successfully!'}
            format.json {head :no_content }
          end
        end
        end
      end
    else
    # comportament web
      if current_user.nil?
        respond_to do |format|
          format.html {redirect_to magazines_path, notice: 'You need to log in to subscribe.'}
          format.json {head :no_content }
        end
        return
      end
      isSubs = current_user.subscriptions.find_by(magazine: @magazine)
      begin
        if isSubs
          respond_to do |format|
            format.html {redirect_to magazines_path, notice: 'Already subscribed!'}
            format.json {head :no_content }
          end
        else
          current_user.subs << @magazine
          respond_to do |format|
            format.html {redirect_to magazines_path, notice: 'Subscribed successfully!'}
            format.json {head :no_content }
          end
        end
      end
    end
  end

  # POST /magazines/1/unsubcribe
  def unsubscribe
    if request.headers['Accept'].present?
      if !User.exists?(token: request.Authorization['API key'])
        respond_to do |format|
          format.json { render(json: {"error": "Not logged in"}, status: 401)}
        end
      else
        @user = User.find(token: request.Authorization['API key'])
        isSubs = @user.find_by(magazine: @magazine)
        begin
        if isSubs
          isSubs.destroy
          @user.subs.delete(@magazine)
          respond_to do |format|
            format.html {redirect_to magazines_path, notice: 'Unsubscibed successfully!'}
            format.json {head :no_content }
          end
        else
          respond_to do |format|
            format.json { render(json: {"error": "Already unsubscribed"}, status: 204)}
          end
        end
        end
      end
    else
      if current_user.nil?
        respond_to do |format|
          format.html {redirect_to magazines_path, notice: 'You need to log in to subscribe.'}
          format.json {head :no_content }
        end
        return
      end
      isSubs = current_user.subscriptions.find_by(magazine: @magazine)
      begin
        if isSubs
          isSubs.destroy
          current_user.subs.delete(@magazine)
          respond_to do |format|
            format.html {redirect_to magazines_path, notice: 'Unsubscibed successfully!'}
            format.json {head :no_content }
          end
        else
          respond_to do |format|
            format.html {redirect_to magazines_path, notice: 'Already unsubscribed!'}
            format.json {head :no_content }
          end
        end
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_magazine
      if !Magazine.exists?(params[:id])
        respond_to do |format|
          format.json { render(json: {"error": "Magazine with this id does not exist"}, status: 404)}
        end
      else
        @magazine = Magazine.find(params[:id])
      end
    end

    # Only allow a list of trusted parameters through.
    def magazine_params
      params.require(:magazine).permit(:name, :title, :url, :description, :rules)
    end
end

