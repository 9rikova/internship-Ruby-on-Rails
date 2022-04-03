require 'sinatra'
require 'csv'

set :bind, '0.0.0.0'
set :port, 5678

class Volume
  attr_accessor :hdd_type, :hdd_capacity
  def initialize(hdd_type, hdd_capacity)
    @hdd_type = hdd_type
    @hdd_capacity = hdd_capacity
  end
end

class VirtualMachine
  attr_accessor :cpu, :ram, :hdd_type, :hdd_capacity, :extra_hdd
  def initialize(cpu, ram, hdd_type, hdd_capacity)
    @cpu = cpu
    @ram = ram
    @hdd_type = hdd_type
    @hdd_capacity = hdd_capacity
    @extra_hdd = []
  end

  def add_extra_hdd(hdd_type, hdd_capacity)
    @extra_hdd << Volume.new(hdd_type, hdd_capacity)
  end

  def price
    res = 0
    @extra_hdd.each { |hdd| res += hdd.hdd_capacity * PriceLoader.find(hdd.hdd_type) }
    res += @cpu * PriceLoader.find('cpu') + @ram * PriceLoader.find('ram') \
        + @hdd_capacity * PriceLoader.find(@hdd_type)
    res
  end
end

class PriceLoader
  TYPE = 0
  PRICE = 1

  def self.find(type)
    CSV.foreach('csv/prices.csv') do |row|
      return row[PRICE].to_i if row[TYPE] == type
    end
  end
end

get '/price' do
  prm = %w[cpu ram hdd_type hdd_capacity]
  if prm.all?(&params.method(:key?))
    vm = VirtualMachine.new(params['cpu'].to_i, params['ram'].to_i, params['hdd_type'], params['hdd_capacity'].to_i)
    if params.key?('extra')
      i = 0
      loop do
        vm.add_extra_hdd(params['extra'][i], params['extra'][i+1].to_i)
        i += 2
        break if i == params['extra'].length
      end
    end
    vm.price.to_s
  else
    'Bad request'
  end
end
