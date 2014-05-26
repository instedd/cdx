class PoliciesController < ApplicationController
  layout "application", only: [:index, :new]

  add_breadcrumb 'Policies', :policies_path

  expose(:policies) { current_user.granted_policies }
  expose(:policy, attributes: :policy_params)

  # POST /policies
  # POST /policies.json
  def create
    policy.granter_id = current_user.id

    respond_to do |format|
      if policy.save
        format.html { redirect_to policies_path, notice: 'Policy was successfully created.' }
        format.json { render action: 'show', status: :created, policy: policy }
      else
        format.html { render action: 'new' }
        format.json { render json: policy.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /policies/1
  # PATCH/PUT /policies/1.json
  def update
    respond_to do |format|
      if policy.update(policy_params)
        format.html { redirect_to policies_path, notice: 'Policy was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: policy.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /policies/1
  # DELETE /policies/1.json
  def destroy
    policy.destroy
    respond_to do |format|
      format.html { redirect_to policies_path }
      format.json { head :no_content }
    end
  end

  private

  def policy_params
    params.require(:policy).permit(:name, :user_id, :delegable)
  end
end
