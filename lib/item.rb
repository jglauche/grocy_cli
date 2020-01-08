module Item
  class Item
    attr_accessor :id, :barcode, :name, :quantity, :best_before, :price, :open, :location_id, :best_before_days, :qu_id_purchase, :qu_id_stock, :qu_factor, :product_group_id

    def initialize(barcode, name="", quantity=1)
      @id = nil
      @barcode = barcode
      @name = name
      @quantity = quantity
    end

    def to_product
      {
        location_id: @location_id,
        default_best_before_days: @best_before_days || 0,
        barcode: @barcode,
        name: @name,
        qu_id_purchase: @qu_id_purchase,
        qu_id_stock: @qu_id_stock,
        qu_factor_purchase_to_stock: @qu_factor,
        product_group_id: @product_group_id,
      }
    end

    def to_stock
      {
        location_id: @location_id,
        new_amount: @quantity,
        best_before_date: @best_before,
        price: @price || 0,
      }
    end

    def to_open
      {
        amount: @open
      }
    end


    # these things should be moved in cli
    def query_quantity
      puts "Quantity? Enter to keep unchanged at #{@quantity}"
      r = gets.strip
      if r != "" && r.to_i != 0
        @quantity = r.to_i
      end
    end

    def query_best_before
      puts "Best before date? (yyyy-mm-dd or dd-mm-(yyyy)) (leave empty for never)"
      case gets.strip.scan(/\d+/).map{|l| l.to_i}
      in [2000.. => a, b, c]
        @best_before = "#{a}-#{b}-#{c}"
      in [a, b, 2000.. => c]
        @best_before = "#{c}-#{b}-#{a}"
      in [a,b]
        @best_before = "#{Time.now.year}-#{b}-#{a}"
      else
        @best_before = "2999-12-31"
      end

      y,m,d = @best_before.split("-")
      m = "0#{m}" if m.size == 1
      d = "0#{d}" if d.size == 1
      @best_before = "#{y}-#{m}-#{d}"
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
