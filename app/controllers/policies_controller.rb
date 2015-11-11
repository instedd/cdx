class PoliciesController < ApplicationController
  layout "application", only: [:index, :new]
  before_filter do
    head :forbidden unless can_delegate_permissions?
  end

  def index
    @policies = current_user.granted_policies.includes(:user).all
  end

  def new
    @policy = Policy.new
  end

  # POST /policies
  # POST /policies.json
  def create
    @policy = Policy.new(policy_params)

    begin
      definition = JSON.parse @policy.definition
      @policy.definition = definition
    rescue => ex
      @policy.errors.add :definition, ex.message
      has_definition_error = true
    end

    @policy.granter_id = current_user.id

    respond_to do |format|
      if @policy.errors.empty? && @policy.save
        format.html { redirect_to policies_path, notice: 'Policy was successfully created.' }
        format.json { render action: 'show', status: :created, policy: @policy }
      else
        if has_definition_error
          @policy.definition = params[:policy][:definition]
        else
          @policy.definition = JSON.pretty_generate(@policy.definition)
        end

        format.html { render action: 'new' }
        format.json { render json: @policy.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit
    @editing = true
    @policy = Policy.find params[:id]
    @policy.definition = JSON.pretty_generate(@policy.definition)
  end

  # PATCH/PUT /policies/1
  # PATCH/PUT /policies/1.json
  def update
    @policy = Policy.find params[:id]
    @policy.attributes = policy_params

    begin
      definition = JSON.parse @policy.definition
      @policy.definition = definition
    rescue => ex
      @policy.errors.add :definition, ex.message
      has_definition_error = true
    end

    respond_to do |format|
      if @policy.errors.empty? && @policy.save
        format.html { redirect_to policies_path, notice: 'Policy was successfully updated.' }
        format.json { head :no_content }
      else
        if has_definition_error
          @policy.definition = params[:policy][:definition]
        else
          @policy.definition = JSON.pretty_generate(@policy.definition)
        end
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
