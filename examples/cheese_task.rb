require 'wee'

class CheeseTask < Wee::Task
  def go
    begin choose_cheese end until confirm_cheese
    inform_cheese
  end

  def choose_cheese
    @cheese = nil
    while @cheese.nil?
      @cheese = choose_from %w(Greyerzer Tilsiter Sbrinz), "What's your favorite Cheese?"
    end
  end

  def confirm_cheese
    confirm "Is #{@cheese} your favorite cheese?"
  end

  def inform_cheese
    inform "Your favorite is #{@cheese}."
  end
end

Wee.run(CheeseTask) if __FILE__ == $0
