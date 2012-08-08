module Corvid
  module Builtin
    class Manifest

      def feature_manifest
        {
          'corvid'    => ['corvid/builtin/corvid_feature'   ,'Corvid::Builtin::CorvidFeature'],
          'test_unit' => ['corvid/builtin/test_unit_feature','Corvid::Builtin::TestUnitFeature'],
          'test_spec' => ['corvid/builtin/test_spec_feature','Corvid::Builtin::TestSpecFeature'],
        }
      end

    end
  end
end
