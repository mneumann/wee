class Recipe
  prop_accessor :title, String
  prop_accessor :description, String
  prop_accessor :instructions, String, :ui => :textarea
end
