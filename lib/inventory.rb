module Inventory
  include Item

  def update?
    return true unless @inventory
    return true unless @db_changed

    # todo check database for update

    false
  end

  def update_items!
    @inventory = {}
    @grocy.products.each do |p|
      @inventory[p["id"]] = Item.from_product(p)
    end
    @grocy.stock.each do |s|
      @inventory[s["product_id"]].update_stock(s)
    end
  end

  def inventory
    update_items! if update?
    @inventory
  end


end
