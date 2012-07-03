class LoadCsvIntoModel
  include 'csv'
  
  # first row of file should be fieldnames that correspond to model fields in db
  def load(csv, model)
    firstrow = true
    fields = []
    objhsh = nil
    field_separator = ',' # tabs are probably \t
    CSV::Reader.parse(File.open(csv, 'rb'), field_separator) do |row|
      if firstrow
        fields = row.dup # array of fieldnames
        firstrow = false
      else
        objhsh = {}
        row.each_with_index {|val,i| objhsh[fields[i]]=val }
        model.create objhsh
      end
    end
  end

end