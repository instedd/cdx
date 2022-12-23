module SamplesReportsHelper
  def get_rates(samples, signal)
    confusion_matrix = Hash.new{0}

    samples.each do |s|
      if s.measured_signal
        if s.concentration == 0 || s.distractor?
          confusion_matrix[:actual_negative] += 1
          if s.measured_signal > signal
            confusion_matrix[:false_positive] += 1
          end
        else
          confusion_matrix[:actual_positive] += 1
          if s.measured_signal > signal
            confusion_matrix[:true_positive] += 1
          end
        end
      end
    end

    if confusion_matrix[:actual_positive] > 0 && confusion_matrix[:actual_negative] > 0 
      tpr=confusion_matrix[:true_positive].to_f/confusion_matrix[:actual_positive].to_f
      fpr =confusion_matrix[:false_positive].to_f/confusion_matrix[:actual_negative].to_f
      [fpr, tpr]
    end
  end

  def roc_curve(samples_report)
    roc_curve = [[0,0]]

    measured_signals = []
    samples_report.samples.each do |s|
      if s.measured_signal
        measured_signals << s.measured_signal
      end
    end

    measured_signals.each do |ms|
      roc_curve << get_rates(samples_report.samples, ms)
    end
    roc_curve << [1,1]

    roc_curve = roc_curve.uniq.sort do |a, b|
      (a[0] <=> b[0]) == 0 ? a[1] <=> b[1] : a[0] <=> b[0]
    end
    roc_curve
  end

  def auc(roc_curve)
    auc = 0
    roc_curve.each_with_index do |point, i|
      if i > 0
        auc += (point[0] - roc_curve[i-1][0]) * (point[1] + roc_curve[i-1][1]) / 2
      end
    end
    auc.round(2)
  end

end
