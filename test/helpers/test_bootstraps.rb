module TestBootstraps

  def test_bootstraps(all, unit, spec)
    test_bootstrap BOOTSTRAP_ALL,  all,  true,  false, false unless all.nil?
    test_bootstrap BOOTSTRAP_UNIT, unit, false, true,  false unless unit.nil?
    test_bootstrap BOOTSTRAP_SPEC, spec, false, false, true  unless spec.nil?
  end

  def test_bootstrap(file, expected, all, unit, spec)
    if expected
      file.should exist_as_a_file
      c= File.read(file)
      c.send all  ? :should : :should_not, include('corvid/builtin/test/bootstrap/all')
      c.send unit ? :should : :should_not, include('unit')
      c.send spec ? :should : :should_not, include('spec')
    else
      file.should_not exist_as_a_file
    end
  end

end
