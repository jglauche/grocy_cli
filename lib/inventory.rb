module Inventory
  include Item

  def update?
    return true unless @inventory
    return true unless @db_changed
    return true if @db_changed != @grocy.last_changed

    false
  end

  def update_items!
    @db_changed = @grocy.last_changed
    @inventory = {}
    @products = {}
    @grocy.products.each do |p|
      @products[p["id"]] = Item.from_product(p)
    end
    @grocy.stock.each do |s|
      @products[s["product_id"]].update_stock(s)
      @inventory[s["product_id"]] = @products[s["product_id"]]
    end
  end

  def inventory
    update_items! if update?
    @inventory
  end


end
