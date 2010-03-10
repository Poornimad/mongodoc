require 'mongo_doc/associations/proxy_base'
require 'mongo_doc/associations/collection_proxy'
require 'mongo_doc/associations/document_proxy'
require 'mongo_doc/associations/hash_proxy'

module MongoDoc
  module Attributes
    def self.included(klass)
      klass.class_eval do
        class_inheritable_array :_keys
        self._keys = []
        class_inheritable_array :_associations
        self._associations = []

        attr_accessor :_parent
        attr_accessor :_id

        extend ClassMethods
      end
    end

    def _root
      @_root
    end

    def _root=(root)
      @_root = root
      _associations.each do|a|
        association = send(a)
        association._root = root if association
      end
    end

    def _path_to_root(src, attrs)
      return attrs unless _parent
      _parent._path_to_root(self, attrs)
    end

    module ClassMethods
      def _attributes
        _keys + _associations
      end

      def key(*args)
        opts = args.extract_options!
        default = opts.delete(:default)
        args.each do |name|
          _keys << name unless _keys.include?(name)
          if default
            attr_writer name

            define_method("_default_#{name}", default.kind_of?(Proc) ? default : Proc.new { default })
            private "_default_#{name}"

            module_eval(<<-RUBY, __FILE__, __LINE__)
              def #{name}
                unless defined? @#{name}
                  @#{name} = _default_#{name}
                end
                class << self; attr_reader :#{name} end
                @#{name}
              end
            RUBY
          else
            attr_accessor name
          end
        end
      end

      def has_one(*args)
        options = args.extract_options!
        assoc_class = if class_name = options.delete(:class_name)
          self.class_from_name(class_name)
        end

        args.each do |name|
          _associations << name unless _associations.include?(name)

          attr_reader name

          define_method("#{name}=") do |value|
            association = instance_variable_get("@#{name}")
            unless association
              association = Associations::DocumentProxy.new(:root => _root || self, :parent => self, :assoc_name => name, :assoc_class => assoc_class || self.class.class_from_name(name))
              instance_variable_set("@#{name}", association)
            end
            association.document = value
          end

          validates_embedded name, :if => Proc.new { !send(name).nil? }
        end
      end

      def has_many(*args)
        options = args.extract_options!
        assoc_class = if class_name = options.delete(:class_name)
          self.class_from_name(class_name)
        end

        args.each do |name|
          _associations << name unless _associations.include?(name)

          define_method("#{name}") do
            association = instance_variable_get("@#{name}")
            unless association
              association = Associations::CollectionProxy.new(:root => _root || self, :parent => self, :assoc_name => name, :assoc_class => assoc_class || self.class.class_from_name(name))
              instance_variable_set("@#{name}", association)
            end
            association
          end

          validates_embedded name

          define_method("#{name}=") do |arrayish|
            proxy = send("#{name}")
            proxy.clear
            Array.wrap(arrayish).each do|item|
              proxy << item
            end
          end
        end
      end

      def has_hash(*args)
        options = args.extract_options!
        assoc_class = if class_name = options.delete(:class_name)
          self.class_from_name(class_name)
        end

        args.each do |name|
          _associations << name unless _associations.include?(name)

          define_method("#{name}") do
            association = instance_variable_get("@#{name}")
            unless association
              association = Associations::HashProxy.new(:root => _root || self, :parent => self, :assoc_name => name, :assoc_class => assoc_class || self.class.class_from_name(name))
              instance_variable_set("@#{name}", association)
            end
            association
          end

          validates_embedded name

          define_method("#{name}=") do |hash|
            send("#{name}").replace(hash)
          end
        end
      end

      def class_from_name(name)
        type_name_with_module(name.to_s.classify).constantize rescue nil
      end

      def type_name_with_module(type_name)
        (/^::/ =~ type_name) ? type_name : "#{parent}::#{type_name}"
      end
    end
  end
end
