require 'rubygems'
require 'data_mapper'
require 'dm-migrations'

@selectors_hash = Hash.new
@scrapers_hash = Hash.new
@crawlers = []
@allowed_urls = []
@black_list = []
@max_depth = 0
@max_concurrency_level = 25
@requests_delay = 100
@requests_deviation = 300
@search_all_urls = true

class Table
    include DataMapper::Resource 

    property :id, Serial

    def initialize name, selectors
        @name = name
        Table.storage_names[:default] = @name
        selectors.keys.each do |key|
            Table.property key, key.class 
        end
    end
end

class Scraper
    attr_accessor :selectors

    def initialize selectors, table
        @selectors = selectors.values
        @table = table
    end
end

class Crawler
    def initialize scrapers, urls, max_depth, 
                   allowed_urls, black_list, 
                   max_concurrency_level, requests_delay,
                   requests_deviation, search_all_urls
        @scrapers = scrapers
        @urls = urls
        @max_depth = max_depth
        @allowed_urls = allowed_urls
        @black_list = black_list
        @max_concurrency_level = max_concurrency_level
        @requests_delay = requests_delay
        @requests_deviation = requests_deviation
        @search_all_urls = search_all_urls
    end

    def run
        @scrapers.each do |scraper|
            scraper.selectors.each do |selector|
                puts selector
            end
        end
        
        puts @max_depth

        DataMapper::Logger.new($stdout, :debug)
        DataMapper.setup(:default, 'sqlite::memory:')
        DataMapper.setup(:default, 'sqlite:///' + Dir.pwd + '/base.db')
        DataMapper.auto_migrate!
    end
end

def crawl urls, &table_block
    @crawlers = []
    @allowed_urls = []
    @black_list = []
    @max_depth = 0
    @max_concurrency_level = 25
    @requests_delay = 100
    @requests_deviation = 300
    @scrapers_hash = Hash.new
    @search_all_urls = true
    table_block.call
    if urls.respond_to? :each
        urls.each do |an_url|
            _add_crawlers an_url, @max_depth, @allowed_urls, 
                                  @black_list, @max_concurrency_level,
                                  @requests_delay, @requests_deviation,
                                  @search_all_urls
        end
    else
        _add_crawlers urls, @max_depth, @allowed_urls, 
                            @black_list, @max_concurrency_level,
                            @requests_delay, @requests_deviation,
                            @search_all_urls
    end

    @crawlers.each do |crawler|
        crawler.run
    end
end

def _add_crawlers urls, max_depth,
                  allowed_urls, black_list, 
                  max_concurrency_level, requests_delay,
                  requests_deviation, search_all_urls
    @crawlers.push Crawler.new @scrapers_hash.values, urls, 
                               max_depth, allowed_urls,
                               black_list, max_concurrency_level,
                               requests_delay, requests_deviation,
                               search_all_urls
end

def max_depth depth=0
    @max_depth = depth
end

def max_concurrency_level level=25
    @max_concurrency_level = level
end

def requests_delay miliseconds=100
    @requests_delay = miliseconds
end

def requests_deviation miliseconds=300
    @requests_deviation = miliseconds
end

def allowed_urls url_list=[]
    @allowed_urls = url_list
end

def black_list url_list=[]
    @black_list = url_list
end

def search_all_urls a_boolean=true
    @search_all_urls = a_boolean
end

def table table_name, &fields_block
    @selectors_hash = Hash.new
    fields_block.call
    @scrapers_hash[table_name] = Scraper.new @selectors_hash, Table.new(table_name, @selectors_hash) 
end

def field field_name, &selector_block
    @selectors_hash[field_name] = selector_block.call
end

if __FILE__ == $0
    crawl "http://pypi.python.org/pypi/cilantro/0.9b4" do
        max_depth 2
        allowed_urls []
        black_list []
        max_concurrency_level 1000
        requests_delay 1000
        requests_deviation 1000
        search_all_urls

        #TODO
        #post_url "url" do
        #   param "nombre" do
        #       "value"
        #   end
        #   ...
        #end
        #login "login_url" do
        #   user "username"
        #   password "password"
        #   param "nombre" do
        #       "value"
        #   end
        #   ...
        #end

        table "MI_TABLA" do
            field "MI_CAMPO_0" do
                "/html/body/div[5]/div/div/div[3]/ul/li/span"
            end

            field "MI_CAMPO_1" do
                "/html/body/div[5]/div/div/div[3]/ul/li[3]/span"
            end

            field "MI_CAMPO_2" do
                "/html/body/div[5]/div/div/div[3]/ul/li[4]/span"
            end
        end
    end
end
