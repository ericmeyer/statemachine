require File.dirname(__FILE__) + '/../../spec_helper'

class Stub
  attr_reader :id
  
  def initialize(id)
    @id = id
  end
end

context "Event View" do

  setup do
    @display = mock("display")
    @display.stub!(:message).and_return("$123.45")
    @display.stub!(:affordable_items).and_return([Stub.new(1)])
    @display.stub!(:non_affordable_items).and_return([Stub.new(2)])
    @display.stub!(:sold_out_items).and_return([Stub.new(3)])
    @display.stub!(:dispensed_item).and_return(Product.new(:name => "Milk"))
    @display.stub!(:change).and_return("$0.25")
    
    @vending_machine = mock("vending machine")
    @vending_machine.stub!(:location).and_return("Downstairs")
    @vending_machine.stub!(:cash_str).and_return("$10.00")
    @vending_machine.stub!(:products).and_return([])
    
    assigns[:context] = @display
    assigns[:vending_machine] = @vending_machine
    
    render "/main/event"
  end
  
  specify "message" do
     response.should_have_rjs :replace_html, "quartz_screen", "$123.45"
  end
  
  specify "affordable items" do
    response.body.should_include "document.getElementById('product_1').className = 'affordable'"
  end

  specify "non affordable items" do
    response.body.should_include "document.getElementById('product_2').className = 'non_affordable'"
  end

  specify "sold_out" do
    response.should_have_rjs :replace_html, "product_3_price", "<span style=\"color: red;\">SOLD OUT</span>"
  end

  specify "dispenser" do
    response.should_have_rjs :replace_html, "dispenser", "<p>Milk</p>"
    response.should_have_rjs :show, "dispenser"
  end

  specify "change" do
    response.should_have_rjs :replace_html, "change_amount", "<p>$0.25</p>"
    response.should_have_rjs :show, "change_amount"
  end

  

end
