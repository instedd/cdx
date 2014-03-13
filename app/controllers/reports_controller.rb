class ReportsController < ApplicationController

  def create
    work_group = Facility.find(report_params[:facility_id]).work_group
    @report = work_group.report_provider.new(report_params)
    respond_to do |format|
      if @report.save
        work_group.subscribers.each do |subscriber|
          subscriber.enqueue_notification @report
        end
        format.json { render_json @report }
      else
        format.json { render status: :unprocessable_entity, content_type: 'text/json' }
      end
    end
  end

  private
    def report_params
      params.require(:report).permit(:facility_id, :result, :test_id, :patient_id)
    end
end
