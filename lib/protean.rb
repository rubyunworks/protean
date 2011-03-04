
class Prototype

  class << self
    alias _new new
  end

  # New prototype object.
  def self.new(&block)
    cls = Class.new(Prototype)
    obj = cls._new

    obj.instance_eval(&block)

    h = {}
    iv = obj.instance_variables
    iv.each { |k| h[k[1..-1].to_sym] = obj.instance_eval{ instance_variable_get(k) } }

    h.each do |k,v|
      case v
      when Proc
        cls.class_eval do
          define_method(k, &v)
          #attr_reader k
        end
      else
        cls.class_eval do
          attr_accessor k
        end
      end
    end

    obj
  end

  def fn(&blk)
    proc(&blk)
  end

  def new(o=nil)
    c = clone
    c.prototype = self
    c
    #return o.clone if o  # TODO
    #return clone
  end

  #def meta
  # (class << self; self; end)
  #end

  attr_accessor :prototype

  def traits
    @traits ||= []
  end

  # TODO: use new?
  def trait(obj)
    trait = obj.new
    trait.traits << self
    traits << trait
  end

  def method_missing(s, *a, &b)
    if trait = traits_list.find{ |t| t.respond_to?(s) }
    p [trait, s]
      trait.send(s,*a,&b)
    else
      super
    end
  end

  def traits_list
    if prototype
      traits + prototype.traits_list
    else
      traits
    end
  end

end


module Kernel

  def prototype(&block)
    Prototype.new(&block)
  end

  #private

  # Synonymous with #clone, this is an interesting
  # method in that it promotes prototype-based Ruby.
  # Now Classes aren't the only things that respond to #new.
  #
  #   "ABC".new  => "ABC"
  #
  def new(o=nil)
    return o.clone if o
    return clone
  end

end

