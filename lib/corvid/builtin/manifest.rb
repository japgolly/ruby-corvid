module Corvid
  module Builtin
    class Manifest

      def feature_manifest
        {
          'corvid'    => nil,
          'test_unit' => nil,
          'test_spec' => nil,
          'plugin'    => ['corvid/builtin/plugin_feature','Corvid::Builtin::PluginFeature']
        }
      end

    end
  end
end
