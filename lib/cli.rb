require './lib/item'
module Cli
  include Item

  # Helper class
  class InvalidKeyException < StandardError
  end

  def init
    CLI::UI::StdoutRouter.enable
  end

  def clear_screen
    puts "\e[H\e[2J"
  end


  def setup_location
    clear_screen
    CLI::UI::Frame.open('Locations') do
      @location_id, @location_name = CLI::UI::Prompt.ask('Choose a storage location') do |handler|
        @grocy.locations.each do |l|
          handler.option(l['name']) { [l['id'], l['name']] }
        end
      end
    end
  end

  def main_screen
    clear_screen
    CLI::UI::Frame.open('Inventory list') do
      CLI::UI::Prompt.ask('Select') do |handler|
        inventory.each do |id, item|
          handler.option("#{item.format_line}") { [id, item] }
        end
      end
    end
  end

  # needs to be refactored
  def inventory_screen
    clear_screen
    puts "Inventory mode | #{@location_name} | #{@product_type} "
    puts ""
    puts ""
    @items.each do |i|
      puts "#{i.quantity}\t#{i.barcode}\t#{i.name}\t#{i.best_before}\t#{i.price}\t#{i.open_string}"
    end
    puts ""
    puts "Scan barcode (b for edit last best before, c for commit, l for locations, p for price, o open amount, r for remove last row, q for quantity of last, q! for quit)"
    case input = gets.strip
    when ""
    when "b"
      @items.last.query_best_before unless @items.size == 0
    when "c"
      @items.each do |i|
        commit(i)
      end
      @items = []
    when "l"
      setup_location
    when "m"
      @items.last.query_price unless @items.size == 0
    when "o"
      @items.last.toggle_open unless @items.size == 0
    when "r"
      @items.pop
    when "q"
      @items.last.query_quantity unless @items.size == 0
    when "q!"
      exit
    else
      check(input)
    end
  end

  def check(barcode)
    @items.each do |i|
      if i.barcode == barcode
        i.quantity += 1
        return
      end
    end
    if p = @grocy.product_by_barcode(barcode)
      item = Item.new(barcode, p["product"]["name"])
      item.id = p["product"]["id"]
      item.quantity = p["stock_amount"]

      @items << item
      return
    end

    res = RestClient.get "https://de.openfoodfacts.org/api/v0/product/#{barcode}", {"User-Agent": @off_user_agent}
    if res.code != 200
      puts "Error: #{res.code} #{res.inspect}"
      return
    end

    rep = JSON.parse(res.body)
    if rep["status"] == 0
      puts "Barcode not found. Name for the product?"
      name = gets.strip
    else
      name = rep["product"]["product_name"]
    end

    item = Item.new(barcode, name)
    item.query_best_before
    @items << item
  end

  def commit(item)
    item.location_id = @location_id
    item.qu_id_purchase = 3
    item.qu_id_stock = 3
    item.qu_factor_purchase_to_stock = 1

    item = @grocy.insert_product(item)

    @grocy.update_stock(item)

    if item.open && item.open.to_i > 0
      @grocy.open_product(item)
    end

  end



end
