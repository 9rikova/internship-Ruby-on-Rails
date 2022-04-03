require 'csv'

# Class for loading virtual machines
class VmLoader
  ID = 0
  CPU = 1
  RAM = 2
  HDD_TYPE = 3
  HDD_CAPACITY = 4

  def self.load(vm_hash)
    CSV.foreach('csv/vms.csv', converters: :integer) do |row|
      vm_hash[row[ID]] = VirtualMachine.new(row[ID], row[CPU], row[RAM],
                                            row[HDD_TYPE], row[HDD_CAPACITY])
    end
  end
end

class VolumeLoader
  ID = 0
  HDD_TYPE = 1
  HDD_CAPACITY = 2

  def self.load(vm_hash)
    CSV.foreach('csv/volumes.csv', converters: :integer) do |row|
      vm_hash[row[ID]].extra_hdd << Volume.new(row[HDD_TYPE], row[HDD_CAPACITY])
    end
  end
end

class Volume
  attr_accessor :hdd_type, :hdd_capacity
  def initialize(hdd_type, hdd_capacity)
    @hdd_type = hdd_type
    @hdd_capacity = hdd_capacity
  end
end

class VirtualMachine
  attr_accessor :id, :cpu, :ram, :hdd_type, :hdd_capacity, :extra_hdd
  def initialize(id, cpu, ram, hdd_type, hdd_capacity)
    @id = id
    @cpu = cpu
    @ram = ram
    @hdd_type = hdd_type
    @hdd_capacity = hdd_capacity
    @extra_hdd = []
  end

  def self.load
    vm_hash = {}
    VmLoader.load(vm_hash)
    VolumeLoader.load(vm_hash)
    vm_hash
  end

  def price
    res = 0
    @extra_hdd.each { |hdd| res += hdd.hdd_capacity * PriceLoader.find(hdd.hdd_type) }
    res += @cpu * PriceLoader.find('cpu') + @ram * PriceLoader.find('ram') \
        + @hdd_capacity * PriceLoader.find(@hdd_type)
    res
  end
end

### КЛАССЫ ДЛЯ ЦЕН ###

class PriceLoader
  TYPE = 0
  PRICE = 1

  def self.find(type)
    CSV.foreach('csv/prices.csv') do |row|
      return row[PRICE].to_i if row[TYPE] == type
    end
  end
end

### ОТЧЁТЫ ###

class Report
  def initialize
    @vms = VirtualMachine.load
  end

  def sorted_by_price(n, flag)
    prc = price
    id = if flag
           prc.max_by(n) { |_, v| v }.to_h.keys
         else
           prc.min_by(n) { |_, v| v }.to_h.keys
         end
    @vms.values_at(*id)
  end

  def biggest(n, type)
    case type
    when 'cpu'
      @vms.values.max_by(n, &:cpu)
    when 'ram'
      @vms.values.max_by(n, &:ram)
    when 'capacity'
      @vms.values.max_by(n, &:hdd_capacity)
    else
      'Wrong type'
    end
  end

  def most_hdd_number(n, hdd_type)
    if hdd_type
      @vms.values.max_by(n) do |vm|
        vm.extra_hdd.count { |hdd| hdd.hdd_type == hdd_type }
      end
    else
      @vms.values.max_by(n) { |vm| vm.extra_hdd.size }
    end
  end

  def most_extra_volume(n, hdd_type)
    if hdd_type
      vlm = extra_volume(hdd_type).max_by(n) { |_, v| v }.to_h.keys
      @vms.values_at(*vlm)
    else
      @vms.values.max_by(n) { |vm| vm.extra_hdd.sum(&:hdd_capacity) }
    end
  end

  private

  def price
    price = {}
    @vms.each_value { |vm| price[vm.id] = vm.price }
    price
  end

  def extra_volume(type)
    volume = {}
    @vms.each_value do |vm|
      sum = 0
      vm.extra_hdd.each { |hdd| sum += hdd.hdd_capacity if hdd.hdd_type == type }
      volume[vm.id] = sum
    end
    volume
  end
end

class ReportPresenter
  def initialize
    @report = Report.new
  end

  def ascending
    catalog(@report.sorted_by_price(n, false))
  end

  def descending
    catalog(@report.sorted_by_price(n, true))
  end

  def biggest
    catalog(@report.biggest(n, type))
  rescue NoMethodError
    puts 'no such type, try again'
    retry
  end

  def most_hdd_number
    if type?
      catalog(@report.most_hdd_number(n, type))
    else
      catalog(@report.most_hdd_number(n, false))
    end
  end

  def most_extra_volume
    if type?
      catalog(@report.most_extra_volume(n, type))
    else
      catalog(@report.most_extra_volume(n, false))
    end
  end

  def all_reports(m = 10, hdd_type = false)
    catalog(@report.sorted_by_price(m, true))
    catalog(@report.sorted_by_price(m, false))
    catalog(@report.biggest(m, 'cpu'))
    catalog(@report.biggest(m, 'ram'))
    catalog(@report.biggest(m, 'capacity'))
    catalog(@report.most_hdd_number(m, hdd_type))
    catalog(@report.most_extra_volume(m, hdd_type))
  end

  def choice
    options = {
      1 => method(:descending),
      2 => method(:ascending),
      3 => method(:biggest),
      4 => method(:most_hdd_number),
      5 => method(:most_extra_volume)
    }
    loop do
      menu
      print '> '
      ans = gets.chomp
      case ans
      when '0'
        return 0
      when '1'..'5'
        options[ans.to_i].call
      else
        puts 'Wrong input'
      end
    end
  end

  private

  def catalog(lst)
    head
    lst.each do |vm|
      print "#{vm.id.to_s.ljust(3)} #{vm.cpu.to_s.ljust(4)}\
#{vm.ram.to_s.ljust(4)} #{vm.hdd_type.ljust(6)} \
#{vm.hdd_capacity.to_s.ljust(5)} |"
      vm.extra_hdd.each { |hdd| print " #{hdd.hdd_type} - #{hdd.hdd_capacity} " }
      puts
    end
    gap
  end

  def menu
    puts "  Select an option:
           1 - n most expencive VM
           2 - n cheapist VM
           3 - n biggest VM
           4 - n VM with the most extra hdd number
           5 - n VM with the most extra volume
           0 - Exit"
  end

  def gap
    puts '-' * 60
  end

  def names
    puts 'id  cpu ram   hdd  capacity  extra hdd'
  end

  def head
    gap
    names
    gap
  end

  def n
    print 'Enter number: '
    gets.to_i
  end

  def type
    print 'Enter type: '
    gets.chomp
  end

  def type?
    loop do
      print 'Want to choose a type? (y/n): '
      answer = gets.chomp
      if answer == 'y'
        return true
      elsif answer == 'n'
        return false
      else
        puts 'Wrong input'
      end
    end
  end
end

program = ReportPresenter.new

if ARGV[0] == '-a'
  program.all_reports
else
  program.choice
end
