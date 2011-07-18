require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'yaml'

describe "EuCentralBank" do
  before(:each) do
    @bank = EuCentralBank.new
    @cache_path = File.expand_path(File.dirname(__FILE__) + '/exchange_rates.xml')
    @yml_cache_path = File.expand_path(File.dirname(__FILE__) + '/exchange_rates.yml')
    @tmp_cache_path = File.expand_path(File.dirname(__FILE__) + '/tmp/exchange_rates.xml')
    @exchange_rates = YAML.load_file(@yml_cache_path)
  end

  after(:each) do
    if File.exists? @tmp_cache_path
      File.delete @tmp_cache_path
    end
  end

  it "should save the xml file from ecb given a file path" do
    @bank.save_rates(@tmp_cache_path)
    File.exists?(@tmp_cache_path).should == true
  end

  it "should raise an error if an invalid path is given to save_rates" do
    lambda { @bank.save_rates(nil) }.should raise_exception
  end

  it "should update itself with exchange rates from ecb website" do
    stub(OpenURI::OpenRead).open(EuCentralBank::ECB_RATES_URL) {@cache_path}
    @bank.update_rates
    EuCentralBank::CURRENCIES.each do |currency|
      @bank.get_rate("EUR", currency).should > 0
    end
  end

  it "should update itself with exchange rates from cache" do
    @bank.update_rates(@cache_path)
    EuCentralBank::CURRENCIES.each do |currency|
      @bank.get_rate("EUR", currency).should > 0
    end
  end

  it "should return the correct exchange rates using exchange" do
    @bank.update_rates(@cache_path)
    EuCentralBank::CURRENCIES.each do |currency|
      @bank.exchange(100, "EUR", currency).cents.should == (@exchange_rates["currencies"][currency].to_f * 100).round
    end
  end

  it "should return the correct exchange rates using exchange_with" do
    @bank.update_rates(@cache_path)
    EuCentralBank::CURRENCIES.each do |currency|
      @bank.exchange_with(Money.new(100, "EUR"), currency).cents.should == (@exchange_rates["currencies"][currency].to_f * 100).round
    end
  end

  # in response to #4
  it "should exchange btc" do
    Money::Currency::TABLE[:btc] = {
      :priority        => 1,
      :iso_code        => "BTC",
      :name            => "Bitcoin",
      :symbol          => "BTC",
      :subunit         => "Cent",
      :subunit_to_unit => 100000000,
      :separator       => ".",
      :delimiter       => ","
    }
    @bank.add_rate("USD", "BTC", 1 / 13.7603)
    @bank.add_rate("BTC", "USD", 13.7603)
    @bank.exchange(100, "BTC", "USD").cents.should == 1376
  end
end
