require './lib/item'
module Cli
  include Item

  # Helper class
  class InvalidKeyException < StandardError
  end

  def init
    CLI::UI::StdoutRouter.enable
  end

  # TODO: This is rather horrible; would be better if I had a way to define fixed/flex columns
  def format_line(arr)
    x = TTY::Screen.width - 2
    small_items = 12
    first_item = x - 5 * small_items

    output = ""
    arr.each_with_index do |l, i|
      if i == 0
        output << l.to_s[0..first_item].ljust(first_item)
      else
        output << l.to_s[0..small_items].ljust(small_items)
      end
    end
    output
  end

  def clear_screen
    puts "\e[H\e[2J"
  end


  def setup_location
    clear_screen
    prompt = TTY::Prompt.new

    @location_id, @location_name = prompt.select('Choose a storage location', per_page: TTY::Screen.height-4) do |handler|
      @grocy.locations.each do |l|
        handler.choice name: l['name'], value: [l['id'], l['name']]
      end
    end
  end

  def main_screen
    clear_screen
    prompt = TTY::Prompt.new
    id, item = prompt.select('Inventory', per_page: TTY::Screen.height-4) do |handler|
      prompt.on(:keypress) do |event|
        id, item = handler.choices[handler.instance_variable_get("@active")-1].value
        case event.value
        when "-"
          item.change_amount(-1)
          # bleh, this cannot redraw now
        when "+"
          item.change_amount(1)
        when "?"
          binding.pry
        end
      end
      inventory.each do |id, item|
        handler.choice(name: format_line(item.line_arr), value: [id, item])
        #puts format_line(item.line_arr)
      end
    end
    puts id
    puts item
  end

  # needs to be refactored
  def inventory_screen
    setup_location if !@location_id || !@location_name
    clear_screen
    puts "Inventory mode | #{@location_name} | #{@product_type} "
    puts ""
    puts ""
    @items.each do |i|
      puts "#{i.amount}\t#{i.barcode}\t#{i.name}\t#{i.best_before_date}\t#{i.price}\t#{i.open_string}"
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
        i.amount += 1
        return
      end
    end
    if p = @grocy.product_by_barcode(barcode)
      item = Item.new
      item.barcode = barcode
      item.name = p["product"]["name"]
      item.id = p["product"]["id"]
      item.amount = p["stock_amount"].to_i
      if item.amount == 0
        item.amount = 1
      end
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

    item = Item.new
    item.barcode = barcode
    item.name = name
    item.amount = 1
    item.query_best_before
    item.query_misc
    @items << item
  end

  def commit(item)
    item.location_id = @location_id
    item.qu_id_purchase = 3
    item.qu_id_stock = 3

    item = @grocy.insert_product(item)

    @grocy.update_stock(item)

    if item.amount_opened && item.amount_opened.to_i > 0
      @grocy.open_product(item)
    end

  end



end
