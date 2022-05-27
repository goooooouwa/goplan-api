class Project < ApplicationRecord
  has_many :todos

  scope :name_contains, ->(name) { where('name LIKE ?', '%' + Todo.sanitize_sql_like(name) + '%') }

  def self.search(query)
    scopes = []
    scopes.push([:name_contains, query[:name]]) if query.try(:[], :name)

    if scopes.empty?
      all
    else
      send_chain(scopes)
    end
  end

  def self.send_chain(scopes)
    Array(scopes).inject(self) { |o, a| o.send(*a) }
  end
end
