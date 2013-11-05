attributes :id, :filename, :transcoded_at, :duration
attributes :urls => :url

node :transcript do |af|
  af.transcript_array
end

child tasks: 'tasks' do |c|
  extends 'api/v1/tasks/task'
end

if current_user
  node(:original, :if => lambda { |af| can?(:manage, af) }) do |af|
    af.url
  end
end