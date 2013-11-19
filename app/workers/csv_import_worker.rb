# encoding: utf-8

require 'utils'

class CsvImportWorker
  include Sidekiq::Worker

  sidekiq_options :retry => false, :backtrace => true

  def perform(import_id)
    import = nil
    ActiveRecord::Base.connection_pool.with_connection do
      import = CsvImport.find(import_id)
      CsvImport.transaction do
        import.process!
      end
      true
    end
  rescue Exception => e
    ActiveRecord::Base.connection_pool.with_connection do
      import.error!(e) if import rescue nil 
    end
    raise e
  end
end
