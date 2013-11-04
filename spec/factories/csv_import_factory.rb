FactoryGirl.define do
  factory :csv_import do
    file { Upload.file('example.csv', 'text/csv') }
    user 

    factory :csv_import_audio do
      file { Upload.file('example_audio.csv', 'text/csv') }
    end
  
    factory :csv_import_with_bad_file do
      file { Upload.file('example.png', 'image/png')}
    end

    factory :csv_import_with_no_file do
      file nil
    end
    
  end
end