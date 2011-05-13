require 'rlp/model'

module Rlp
  class StaticDatabase < Rod::Database
  end
  # This class is a base class for 'static' models, i.e.
  # model which rarely change (such as categories, their values, etc.).
  # This is a temporary class, and will be removed, if Rod library
  # implements #4 -- append of the database.
  class StaticModel < Model
    database_class StaticDatabase
  end
end
