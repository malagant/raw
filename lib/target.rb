module RAW
  class Target
    attr_accessor :name, :dependencies, :block
    def initialize(name)
      @name = name
      @dependencies = [] 
    end
  end
end