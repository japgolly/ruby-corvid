require_relative 'spec'

module IntegrationTestDecoration
  SEP1= "\e[0;40;34m#{'_'*120}\e[0m"
  SEP2= "\e[0;40;34m#{'-'*120}\e[0m"
  SEP3= "\e[0;40;34m#{'='*120}\e[0m"
  def self.included spec
    spec.class_eval <<-EOB
      before(:all) { puts ::#{self}::SEP1 }
      before(:each){ puts ::#{self}::SEP2 }
      after(:all)  { puts ::#{self}::SEP3 }
    EOB
  end
end

