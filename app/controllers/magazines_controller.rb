class MagazinesController < ApplicationController
  before_action :set_magazine, only: %i[ show edit update destroy ]

  # GET /magazines or /magazines.json
  def index
    @magazines = Magazine.order(params[:sort])
    if params[:sort] == "threads"
      @magazines = Magazine.all.sort_by{|magazine| magazine.articles.size}
    elsif params[:sort] == "avg_ranking"
      @players = Player.all.sort_by{|player| player.avg_ranking}
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
