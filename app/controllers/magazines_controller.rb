class MagazinesController < ApplicationController
  before_action :set_magazine, only: %i[ show edit update destroy subscribe ]

  # GET /magazines or /magazines.json
  def index
    @magazines = Magazine.order(params[:sort])
    if params[:sort] == "threads"
      @magazines = Magazine.all.sort_by{|magazine| magazine.articles.size}
    elsif params[:sort] == "comments"
      @magazines = Magazine.all.sort_by{|magazine| magazine.nComms}
    elsif params[:sort] == "subs"
      @magazines = Magazine.all.sort_by{|magazine| magazine.users.size}
    end
  end

  # GET /magazines/1 or /magazines/1.json
  def show
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

  def subscribe
    if current_user.nil?
      respond_to do |format|
        format.html {redirect_to root_path, notice: 'You need to log in to subscribe.'}
        format.json {head :no_content }
      end
      return
    end
    isSubs = current_user.magazines.find_by(magazine: @magazine)
    begin
      if isSubs
        isSubs.destroy
        current_user.magazines.delete(@magazine)
        respond_to do |format|
          format.html {redirect_to magazines_path, notice: 'Unsubscibed successfully!'}
          format.json {head :no_content }
        end
      else
        current_user.magazines << @magazine
        respond_to do |format|
          format.html {redirect_to magazines_path, notice: 'Subscribed successfully!'}
          format.json {head :no_content }
        end
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_magazine
      @magazine = Magazine.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def magazine_params
      params.require(:magazine).permit(:name, :title, :url)
    end
end

