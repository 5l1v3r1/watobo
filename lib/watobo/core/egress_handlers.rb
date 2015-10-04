# @private
module Watobo#:nodoc: all

  module EgressHandlers

    CONFIG_FILE = 'egress_config.yml'
    MAX_HISTORY = 5

    @handlers = {}
    @history = []
    @last = nil
    def self.list(&block)
      @handlers.each_key do |name|
        yield name if block_given?
      end
      @handlers.each_key.to_a
    end

    def self.add(file)
      load file
      update
      save_config
    end
    
    def self.last
      @last
    end
    
    def self.last=(name)
      @last = name
      save_config
    end

    def self.create(name)
#      puts "create egress-handler #{name}" 
      fkey = name.to_sym
      return nil unless @handlers.has_key? fkey
      @handlers[fkey].new()
    end

    def self.update
      constants.each do |name|
        next if name == :CONFIG_FILE
        next if name == :MAX_HISTORY
        h = class_eval(name.to_s)
        h_name = h.name.gsub(/.*::/, '').to_sym
        @handlers[h_name] = h
      end
    end

    def self.length
      @handlers.length
    end
    
    def self.reload
      @history.each do |file|
        load file
      end
    end

    def self.load(file)
      begin
        Kernel.load file
        @history << file
        @history.uniq!
        @history.shift if @history.length > MAX_HISTORY

      rescue SyntaxError => bang
        puts bang
        puts bang.backtrace
      end

    end

    def self.init
      @cfg_file = File.join Watobo.working_directory, 'conf', CONFIG_FILE
      load_config
    end

    def self.load_config
      cfg = Watobo::DataStore.load_project_settings(self.name.gsub(/^.*::/,''))
      return false if cfg.nil?
      @last = cfg[:last]
      @history = cfg[:history]
      reload
      update
    end

    def self.save_config
      cfg = { :last => @last,
        :history => @history
      }
      Watobo::DataStore.save_project_settings(self.name.gsub(/^.*::/,''), cfg)
  
    end

  end
end
