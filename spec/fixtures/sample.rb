class UndocumentedClass

  attr_writer :write_only
  attr_reader :read_me
  attr_accessor :read_write

  def undocumented_method(param1, param2=3)
    'The method is not documented!'
  end

  def undocumented_multiline_method(param1, param2 = 3, opts = {})
    'Not documented!'
    'Noot documented!'
    'Noooot documented!!!'
  end
end
