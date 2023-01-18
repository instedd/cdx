module SamplesReportsHelper
  def get_rates(samples, signal)
    confusion_matrix = confusion_matrix(samples, signal)

    if confusion_matrix[:actual_positive] > 0 && confusion_matrix[:actual_negative] > 0 
      tpr=confusion_matrix[:true_positive].to_f/confusion_matrix[:actual_positive].to_f
      fpr =confusion_matrix[:false_positive].to_f/confusion_matrix[:actual_negative].to_f
      [fpr, tpr]
    else
      [0,0]
    end
  end

  # Returns a hash with the points of the Reveiver Operating Characteristic curve.
  # This curve is used to evaluate the performance of a binary classifier, it moves
  # the threshold of the classifier from 0 to 1 and calculates the true positive rate
  # and the false positive rate for each threshold.
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

  # Returns the area under the curve of the Receiver Operating Characteristic curve.
  # A perfect classifier would have an AUC of 1: True Positive Rate = 1 and False Positive Rate = 0
  # no matter the threshold. A random classifier would have an AUC of 0.5.
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
