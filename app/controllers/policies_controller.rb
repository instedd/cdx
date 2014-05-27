class PoliciesController < ApplicationController
  layout "application", only: [:index, :new]

  add_breadcrumb 'Policies', :policies_path

  def index
    @policies = current_user.granted_policies.all
  end

  def new
    @policy = Policy.new
  end

  # POST /policies
  # POST /policies.json
  def create
    @policy = Policy.new(policy_params)
    @policy.definition = JSON.parse @policy.definition
    @policy.granter_id = current_user.id

    respond_to do |format|
      if @policy.save
        format.html { redirect_to policies_path, notice: 'Policy was successfully created.' }
        format.json { render action: 'show', status: :created, policy: @policy }
      else
        format.html { render action: 'new' }
        format.json { render json: @policy.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit
    @policy = Policy.find params[:id]
  end

  # PATCH/PUT /policies/1
  # PATCH/PUT /policies/1.json
  def update
    @policy = Policy.find params[:id]

    respond_to do |format|
      @policy.attributes = policy_params
      @policy.definition = JSON.parse @policy.definition

      if @policy.save
        format.html { redirect_to policies_path, notice: 'Policy was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @policy.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /policies/1
  # DELETE /policies/1.json
  def destroy
    @policy = Policy.find params[:id]
    @policy.destroy
    respond_to do |format|
      format.html { redirect_to policies_path }
      format.json { head :no_content }
    end
  end

  private

  def policy_params
    params.require(:policy).permit(:name, :user_id, :definition, :delegable)
  end
end
