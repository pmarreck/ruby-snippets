
class Array
  def insert_every!(skip, str, from=0, to=self.length)
    insert_every!(skip, str, from+skip, to) if from < to
    insert(from,str) unless from==0 || from==to
    self
  end
end

p %w[ 1 2 3 4 5 6 7 8 9 10 11 12 ].insert_every!(3, ',')
