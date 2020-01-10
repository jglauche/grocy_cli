module Item
  class Item
    ProductKeys = %w(id barcode name description location_id qu_id_purchase qu_id_stock qu_factor_purchase_to_stock min_stock_amount default_best_before_days product_group_id default_best_before_days_after_open allow_partial_units_in_stock enable_tare_weight_handling tare_weight not_check_stock_fulfillment_for_recipes)

    StockKeys = %w(amount amount_aggregated amount_opened amount_opened_aggregated best_before_date is_aggregated_amount location_id price)
    StockKeysInt = %w(amount amount_aggregated amount_opened amount_opened_aggregated location_id")

    # TODO: check why stock api does not include location_id, price


    attr_accessor(*ProductKeys)
    attr_accessor(*StockKeys)

    attr_accessor :changed


    def initialize
      @changed = false
    end

    def self.from_product(p)
      i = Item.new
      ProductKeys.each do |key|
        i.send("#{key}=", p[key])
      end
      i
    end

    def update_stock(s)
      StockKeys.each do |key|
        if StockKeysInt.include?(key)
          self.send("#{key}=", s[key].to_i)
        else
          self.send("#{key}=", s[key])
        end
      end
    end

    def to_product
      p = {}
      ProductKeys.each do |key|
        p[key] = self.send(key) if self.send(key) != nil
      end
      return p
    end

    def to_stock
      {
        location_id: @location_id,
        new_amount: @amount,
        best_before_date: @best_before_date,
        price: @price || 0,
      }
    end

    def to_open
      {
        amount: @amount_opened
      }
    end

    def line_arr
      res = [name, amount]
      if amount_opened.to_i > 0
        res << "(#{amount_opened} open)"
      else
        res << ""
      end
      res << best_before_date
      res << price
      res
    end

    def change_amount(diff)
      @amount += diff
      @changed = true
    end

    # these things should be moved in cli
    def query_quantity
      puts "Quantity? Enter to keep unchanged at #{@amount}"
      r = gets.strip
      if r != "" && r.to_i != 0
        @amount = r.to_i
      end
    end

    def query_best_before
      puts "Best before date? (yyyy-mm-dd or dd-mm-(yyyy)) (leave empty for never)"
      case gets.strip.scan(/\d+/).map{|l| l.to_i}
      in [2000.. => a, b, c]
        @best_before_date = "#{a}-#{b}-#{c}"
      in [a, b, 2000.. => c]
        @best_before_date = "#{c}-#{b}-#{a}"
      in [a,b]
        @best_before_date = "#{Time.now.year}-#{b}-#{a}"
      else
        @best_before_date = "2999-12-31"
      end

      y,m,d = @best_before_date.split("-")
      m = "0#{m}" if m.size == 1
      d = "0#{d}" if d.size == 1
      @best_before_date = "#{y}-#{m}-#{d}"
    end

    def query_misc
      puts "one packet has how many items?"
      r = gets.strip
      if r != ""
        @qu_factor_purchase_to_stock = r.to_i
      end

      puts "How many days does it last after opening?"
      r = gets.strip
      if r != ""
        @default_best_before_days_after_open = r.to_i
      end

      puts "How many to keep in stock?"
      r = gets.strip
      if r != ""
        @min_stock_amount = r.to_i
      end
    end

    def query_price
      puts "Price?"
      r = gets.strip
      if r != "" && r.to_f != 0.0
        @price = r
      end
    end

    def toggle_open
      if @open.to_i > 0
        @open = 0
      else
        @open = 1
      end
    end

    def open_string
      if @open.to_i > 0
        "Open"
      end
    end
  end

end
