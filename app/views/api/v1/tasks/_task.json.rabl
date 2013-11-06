attributes :id, :status, :name
attribute :type_name => :type


node do |t|
  t.shared_attributes.inject({}) do |add, a|
    add[a] = t.send(a)
    add
  end
end