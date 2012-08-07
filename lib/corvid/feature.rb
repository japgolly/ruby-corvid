require 'golly-utils/callbacks'                                                                                          
                                                                                                                         
module Corvid                                                                                                            
  class Feature
    include GollyUtils::Callbacks                                                                                        
                                                                                                                         
    define_callbacks :rake_tasks                                                                                         
                                                                                                                         
  end                                                                                                                    

  class FeatureManager

    # @param [String] name
    # @return [nil,Feature]
    def feature(name)
      # load feature manifests
      # require
      # determine class name like in plugin manager
    end

    # @return [Hash<String,nil|String>]
    def manifest
      @manifest ||= (
        Plugin.new.feature_manifest
      )
    end
  end

  class Plugin
    def feature_manifest
      {
        'corvid'    => nil,
        'test_unit' => nil,
        'test_spec' => nil,
        'plugin'    => 'corvid/features/plugin',
      }
    end
  end
end                                                                                                                      

