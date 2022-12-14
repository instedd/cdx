module SamplesReportsHelper
  def confusion_matrix(samples_report)
    confusion_matrix = Hash.new{0}

    samples_report.samples.each do |s|
      if s.measured_signal
        confusion_matrix[:total] += 1
        if s.concentration == 0
          confusion_matrix[:actual_negative] += 1
          if s.measured_signal > 0
            confusion_matrix[:predicted_positive] += 1
            confusion_matrix[:false_positive] += 1
          else
            confusion_matrix[:predicted_negative] += 1
            confusion_matrix[:true_negative] += 1
          end
        else
          confusion_matrix[:actual_positive] += 1
          if s.measured_signal > 0
            confusion_matrix[:predicted_positive] += 1
            confusion_matrix[:true_positive] += 1
          else
            confusion_matrix[:predicted_negative] += 1
            confusion_matrix[:false_negative] += 1
          end
        end
      end
    end

    confusion_matrix
  end
end
