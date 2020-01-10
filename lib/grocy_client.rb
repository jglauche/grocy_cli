module GrocyClient

  class GrocyClient
    def initialize(path, key)
      setup_grocy(path)

      @key = key
    end

    def setup_grocy(path)
      if !path.include?('api')
        @uri = [path.split("/"), "api"].join("/")
      else
        @uri = path
      end
    end

    def headers
      {"GROCY-API-KEY": @key}
    end

    def to_json(&block)
      res = block.yield
      return if res == nil
      case res.code
      when 200
        JSON.parse(res.body)
      when 204
        true
      else
        res
      end
    end

    def get(path)
      to_json { get!(path) }
    end

    def post(path, data)
      to_json { post!(path, data) }
    end

    def put(path, data)
      to_json { put!(path, data) }
    end


    def get!(path)
      RestClient.get [@uri, path].join("/"), headers
    end

    def post!(path, data)
      RestClient.post [@uri, path].join("/"), data, headers
    end

    def put!(path, data)
      RestClient.put [@uri, path].join("/"), data, headers
    end

    def products
      get("objects/products")
    end

    def stock
      get("stock")
    end

    def locations
      get("objects/locations")
    rescue RestClient::BadRequest
      return false
    end

    def product_by_barcode(barcode)
      get("stock/products/by-barcode/#{barcode}")
    rescue RestClient::BadRequest
      return false
    end

    def insert_product(item)
      return if item.nil? or item.barcode.to_s == ""
      res = product_by_barcode(item.barcode)
      if res
        item.id = res["product"]["id"]
        return item
      end
      insert_product!(item)
    end

    def insert_product!(item)
      res = post("objects/products", item.to_product)
      if res
        item.id = res["created_object_id"]
        return item
      end
    end

    def stock_path(item, action=nil)
      ["stock/products/#{item.id}", action].compact.join("/") if item.id
      # ["stock/products/by-barcode/#{item.barcode}", action].compact.join("/")
    end

    def update_stock(item)
      # we need to get the stock before posting it as the api does not spport updating to the same amount...
      stock = get(stock_path(item, 'entries'))
      if stock.map{|l| l["amount"].to_i}.sum != item.quantity
        post(stock_path(item, 'inventory'), item.to_stock)
      end
    end

    def open_product(item)
      post(stock_path(item, 'open'), item.to_open)
    end

  end
end
