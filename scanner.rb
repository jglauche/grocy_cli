#!/usr/bin/env ruby
require 'rest-client'
require 'json'
require 'yaml'
require 'cli/ui'
require './lib/cli'
require './lib/grocy'
require './lib/inventory'


class GrocyCli
  include Grocy
  include Cli
  include Inventory

  def initialize
    get_config
    main
  end

  def get_config
    @config = YAML.load_file("config.yml")

    @grocy = GrocyClient.new(@config["grocy"]["grocy_url"], @config["grocy"]["api_key"])

    @off_user_agent = @config["open_food_facts"]["user_agent"]

    @location_id = nil
    @location_name = nil
    @items = []
  end

  def main
    loop do
      setup_location || next if @location_id == nil
      main_screen
    end
  end

end

GrocyCli.new


