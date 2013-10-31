require 'digest/sha1'

namespace :search do
  desc 're-index all items'
  task index: [:environment] do
    Item.create_elasticsearch_index
    import_all_items(Item.index)
  end

  desc 'stage a reindex of all items'
  task stage: [:environment] do
    Tire.index('items_ip').delete
    Tire.index(items_index_name) do
      add_alias 'items_ip'
      create mappings: Item.tire.mapping_to_hash,
      import_all_items self
      remove_alias 'items_ip'
      Tire.index('items_st') do
        remove_alias 'items_st'
        delete
      end
      add_alias 'items_st'
      puts "finshed generating staging index #{name}"
    end
  end

  desc 'commit the staged index to be the new index'
  task :commit do
    Tire.index('items').remove_alias('items')
    Tire.index 'items_st' do
      add_alias 'items'
      remove_alias 'items_st'
    end
    puts "promoted staging to items"
  end


  def items_index_name
    "items-rebuild-#{Digest::SHA1.hexdigest(Time.now.to_s)[0,8]}"
  end

  def set_up_progress
    print '|' + ' ' * 100 + '|' + '     '
    $stdout.flush
  end

  def progress(amount)
    print "\b" * 107
    print '|' + '#' * amount + ' ' * (100 - amount) + '| '
    print ' ' if amount < 10
    print ' ' if amount < 100
    print amount
    print '%'
    $stdout.flush
  end

  def import_all_items(index)
    count = Item.count
    done = 0
    set_up_progress
    ActiveRecord::Base.logger = Logger.new('/dev/null')
    Item.includes(:collection, :hosts, :creators, :interviewers, :interviewees, :producers, :geolocation, :contributors, :confirmed_entities, :low_scoring_entities, :middle_scoring_entities, :high_scoring_entities).includes(audio_files: :transcripts).find_in_batches batch_size: 10 do |items|
      index.import items
      done += items.size
      progress done * 100 / count
    end
    puts
  end
end
