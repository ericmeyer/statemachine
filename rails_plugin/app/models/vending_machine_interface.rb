class VendingMachineInterface
  
  attr_reader :amount_tendered, :statemachine, :accepting_money, :dispensed_item, :change
  attr_accessor :vending_machine
  
  def create_statemachine
    return Statemachine.build do
      startstate :standby
      superstate :accepting_money do
        on_entry :accept_money
        on_exit :refuse_money
        event :dollar, :collecting_money, :add_dollar 
        event :quarter, :collecting_money, :add_quarter
        event :dime, :collecting_money, :add_dime
        event :nickel, :collecting_money, :add_nickel
        state :standby do
          on_exit :clear_dispensers
          event :selection, :standby
        end
        state :collecting_money do
          on_entry :check_max_price
          event :reached_max_price, :max_price_tendered
          event :selection, :validating_purchase, :load_product
        end
        state :validating_purchase do
          on_entry :check_affordability
          event :accept_purchase, :standby, :make_sale
          event :refuse_purchase, :collecting_money
        end
      end
      state :max_price_tendered do
        event :selection, :standby, :load_and_make_sale
        event :dollar, :max_price_tendered
        event :quarter, :max_price_tendered
        event :dime, :max_price_tendered
        event :nickel, :max_price_tendered
      end
    end
  end
  
  def initialize
    @statemachine = create_statemachine
    @statemachine.context = self
    @amount_tendered = 0
    @accepting_money = true
  end
  
  def message
    if @amount_tendered <= 0
      return "Insert Money"
    elsif not @accepting_money
      return "Make Selection"
    else
      return sprintf("$%.2f", @amount_tendered/100.0)
    end
  end
  
  def affordable_items
    return @vending_machine.products.reject { |product| product.sold_out? or product.price > @amount_tendered }
  end

  def non_affordable_items
    return @vending_machine.products.reject { |product| product.sold_out? or product.price <= @amount_tendered }
  end
  
  def sold_out_items
    return @vending_machine.products.reject { |product| !product.sold_out? }
  end
  
  def add_dollar
    @amount_tendered = @amount_tendered + 100
  end

  def add_quarter
    @amount_tendered = @amount_tendered + 25
  end
  
  def add_dime
    @amount_tendered = @amount_tendered + 10
  end
  
  def add_nickel
    @amount_tendered = @amount_tendered + 5
  end
  
  def check_max_price
    if @amount_tendered >= @vending_machine.max_price
      @statemachine.process_event(:reached_max_price)
    end
  end
  
  def accept_money
    @accepting_money = true
  end
  
  def refuse_money
    @accepting_money = false
  end
  
  def load_product(id)
    @selected_product = Product.find(id)
  end
  
  def check_affordability
    if @amount_tendered >= @selected_product.price
      @statemachine.accept_purchase
    else
      @statemachine.refuse_purchase
    end
  end
  
  def make_sale
    @dispensed_item = @selected_product
    change_pennies = @amount_tendered - @selected_product.price
    @change = sprintf("$%.2f", change_pennies/100.0)
    @amount_tendered = 0
    @accepting_money = true
  end
  
  def clear_dispensers
    @dispensed_item = nil
    @change = nil
  end
  
  def load_and_make_sale(id)
    load_product(id)
    make_sale
  end  
end