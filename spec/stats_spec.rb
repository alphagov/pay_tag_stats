require 'stats'

RSpec.describe Stats do
  it "works" do
    Stats.for('/Users/davidheath/gds/pay-connector').each {|s| puts s}
  end
end