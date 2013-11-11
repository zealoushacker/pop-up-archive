FactoryGirl.define do
  factory :task do
    association :owner, factory: :audio_file
  end

  factory :detect_derivatives_task, parent: :task, class: Tasks::DetectDerivativesTask do
  end

  factory :transcribe_task, parent: :task, class: Tasks::TranscribeTask do
  end

  factory :analyze_task, parent: :task, class: Tasks::AnalyzeTask do
  end

  factory :add_to_amara_task, parent: :task, class: Tasks::AddToAmaraTask do
  end
end