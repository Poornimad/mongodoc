require 'mongo_doc'

class Address
  include MongoDoc::Document

  key :street
  key :city
  key :state
  key :zip_code
  key :phone_number
end

class Contact
  include MongoDoc::Document

  key :name
  key :interests
  has_many :addresses

  scope :in_state, lambda {|state| where('addresses.state' => state)}
end

Contact.collection.drop

contact = Contact.new(:name => 'Hashrocket', :interests => ['ruby', 'rails', 'agile'])
contact.addresses << Address.new(:street => '320 1st Street North, #712', :city => 'Jacksonville Beach', :state => 'FL', :zip_code => '32250', :phone_number => '877 885 8846')
contact.save
puts Contact.find_one(contact.to_param).addresses.first.street

hashrocket = Contact.in_state('FL').find {|contact| contact.name == 'Hashrocket'}

hashrocket_address = hashrocket.addresses.first
hashrocket_address.update_attributes(:street => '320 First Street North, #712')

puts Contact.where(:name => 'Hashrocket').first.addresses.first.street

# Criteria behave like new AR3 AREL queries
hr = Contact.where(:name => 'Hashrocket')
hr_in = hr.where('addresses.state' => 'IN')
puts hr.count
puts hr_in.count
