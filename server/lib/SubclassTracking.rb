#derived from http://ola-bini.blogspot.com/2007/07/objectspace-to-have-or-not-to-have.html
module SubclassTracking
def self.extended(klazz)
  (class <<klazz; self; end).send :attr_accessor,  :subclasses
  (class <<klazz; self; end).send :define_method, :inherited do |clzz|
    klazz.subclasses << clzz
    super
  end
  klazz.subclasses = []
  end
end
