# encoding: utf-8
require_relative '../../bootstrap/spec'
require 'corvid/generators/action_extentions'
require 'thor'

describe Corvid::Generator::ActionExtentions do

  class MockGen < Thor
    include Thor::Actions
    include Corvid::Generator::ActionExtentions
    desc '',''; def add_line; add_line_to_file 'file', 'this is the text' end

    no_tasks{
      def omg; "123" end
      def evil; 666 end
    }
  end

  UNSAFE_GEN_METHODS= %w[
    template
    chmod
    create_file
    copy_file
    insert_into_file
    run
    run_bundle_at_exit
  ].map(&:to_sym)
  def safe_gen
    g= quiet_generator(MockGen)
    UNSAFE_GEN_METHODS.each{|m| g.stub m }
    g
  end

  #---------------------------------------------------------------------------------------------------------------------

  describe "#add_line_to_file" do
    run_each_in_empty_dir

    def run!; run_generator MockGen, 'add_line', false end

    it("creates the file when the file doesn't exist"){
      run!
      'file'.should exist_as_file
      File.read('file').chomp.should == 'this is the text'
    }

    context "the file already contains the line of text" do
      def test(content)
        File.write 'file', content
        run!
        File.read('file').should == content
      end
      it("does nothing when line is at start of file"){ test "this is the text\nthat's great" }
      it("does nothing when line is in middle of file"){ test "hehe\nthis is the text\nthat's great" }
      it("does nothing when line is at end of file without CR"){ test "hehe\nthis is the text" }
      it("does nothing when line is at end of file with CR"){ test "hehe\nthis is the text\n" }
    end

    context "when file exists and doesn't contain the line yet" do
      def test(content, append)
        File.write 'file', content
        run!
        File.read('file').should == content + append
      end
      it("adds the line of text and maintain the CR at EOF"){ test "hehe\nthat's great\n", "this is the text\n" }
      it("adds the line of text and maintain a lack of CR at EOF"){ test "hehe\nthat's great", "\nthis is the text" }
    end
  end

  #---------------------------------------------------------------------------------------------------------------------

  describe '#add_dependencies_to_gemfile' do
    run_each_in_empty_dir
    before(:each){ $expect_bundle= nil }

    def test(gemfile_before, gemfile_after)
      File.write 'Gemfile', gemfile_before
      g= quiet_generator MockGen
      case $expect_bundle
        when nil   then g.stub :run_bundle_at_exit
        when false then g.should_not_receive :run_bundle_at_exit
        else            g.should_receive :run_bundle_at_exit
      end
      yield g
      'Gemfile'.should be_file_with_contents(gemfile_after).when_normalised_with(&:chomp)
    end

    def test1(gemfile_before, gemfile_after, *params)
      test(gemfile_before, gemfile_after) {|g| g.add_dependency_to_gemfile *params }
    end
    def test2(gemfile_before, gemfile_after, *params)
      test(gemfile_before, gemfile_after) {|g| g.add_dependencies_to_gemfile *params }
    end

    context "when dependency is new" do
      it("adds it to gemfile"){
        g= %[source :rubygems\ngroup :ci do\n  gem 'ci_reporter', require: false\nend]
        test1 g, %[#{g}\ngem "yard"], "yard"
        test2 g, %[#{g}\ngem "yard"], "yard"
      }

      it("adds it to gemfile with version"){
        g= %[source :rubygems\ngroup :ci do\n  gem 'ci_reporter', require: false\nend]
        test1 g, %[#{g}\ngem "yard", "= 2.0"], "yard", "= 2.0"
        test2 g, %[#{g}\ngem "yard", "= 2.0"], ["yard", "= 2.0"]
      }

      it("adds it to gemfile with options"){
        g= %[source :rubygems\ngroup :ci do\n  gem 'ci_reporter', require: false\nend]
        test1 g, %[#{g}\ngem "yard", platforms: :mri, path: "/tmp"], "yard", {platforms: :mri, path: "/tmp"}
        test2 g, %[#{g}\ngem "yard", platforms: :mri, path: "/tmp"], ["yard", {platforms: :mri, path: "/tmp"}]
      }

      it("adds multiple to gemfile"){
        g= %[source :rubygems\ngroup :ci do\n  gem 'ci_reporter', require: false\nend]
        test2 g, %[#{g}\ngem "yard"\ngem "golly-utils"], "yard", "golly-utils"
      }

      it("adds multiple to gemfile with params"){
        g= %[source :rubygems\ngroup :ci do\n  gem 'ci_reporter', require: false\nend]
        test2 g, %[#{g}\ngem "yard", platforms: :mri\ngem "abc", ">= 0.3", platforms: :jruby],
          ['yard', {platforms: :mri}], ['abc', '>= 0.3', {platforms: :jruby}]
      }

      it("adds when declared but commented out"){
        g= %[# gem "yard"]
        test1 g, %[#{g}\ngem "yard"], "yard"
      }
    end

    context "when dependency already declared" do
      it("do nothing when exact match found"){
        $expect_bundle= false
        g= %[source :rubygems\ngroup :ci do\n  gem 'ci_reporter', require: false\nend\ngem 'yard']
        test1 g, g, "yard"
        test1 g, g, "ci_reporter", require: false
        test2 g, g, "yard", ["ci_reporter", require: false]
      }

      it("do nothing when declared with different params"){
        # I think another method like set_dependency_option() would be more appropriate
        $expect_bundle= false
        g= %[source :rubygems\ngroup :ci do\n  gem 'ci_reporter', require: false\nend\ngem 'yard', '>=2']
        test1 g, g, "ci_reporter", require: true
        test1 g, g, "ci_reporter", '>=4', require: true
        test1 g, g, "yard", '>=3'
        test1 g, g, "yard", require: false
      }

      it("do nothing when declared one same line as other declaration"){
        $expect_bundle= false
        g= %[gem "abc"; gem "yard"; gem "def"]
        test1 g, g, "yard"
      }
    end

    context "running bundle" do
      it("calls run_bundle_at_exit() by default"){
        $expect_bundle= true
        g= %[source :rubygems\ngroup :ci do\n  gem 'ci_reporter', require: false\nend]
        test1 g, %[#{g}\ngem "yard"], "yard"
        test2 g, %[#{g}\ngem "yard"], "yard"
      }

      it("calls run_bundle_at_exit() if requested"){
        $expect_bundle= true
        g= %[source :rubygems\ngroup :ci do\n  gem 'ci_reporter', require: false\nend]
        test1 g, %[#{g}\ngem "yard"], "yard", run_bundle_at_exit: true
        test2 g, %[#{g}\ngem "yard"], "yard", run_bundle_at_exit: true
      }

      it("skips run_bundle_at_exit() if requested"){
        $expect_bundle= false
        g= %[source :rubygems\ngroup :ci do\n  gem 'ci_reporter', require: false\nend]
        test1 g, %[#{g}\ngem "yard"], "yard", run_bundle_at_exit: false
        test2 g, %[#{g}\ngem "yard"], "yard", run_bundle_at_exit: false
      }
    end

    it("fails when Gemfile doesn't exist"){
      expect{
        quiet_generator(MockGen).add_dependency_to_gemfile "yard"
      }.to raise_error /Gemfile/
    }
  end

  #---------------------------------------------------------------------------------------------------------------------

  describe '#template2' do
    let(:g) { safe_gen }

    it("removes .tt from end of filename"){
      g.should_receive(:template).once.with('hehe.rb.tt','hehe.rb')
      g.template2 'hehe.rb.tt'
    }

    it("doesn't remove .tt from middle of filename"){
      g.should_receive(:template).once.with('hehe.tt.rb','hehe.tt.rb')
      g.template2 'hehe.tt.rb'
    }

    it("substitutes tags in filename"){
      g.should_receive(:template).once.with('%omg%/%evil%-%evil%.rb','123/666-666.rb')
      g.template2 '%omg%/%evil%-%evil%.rb'
    }

    it("calls chmod when perms provided"){
      g.should_receive(:template).once.with('hehe.rb','hehe.rb').ordered
      g.should_receive(:chmod).once.with('hehe.rb',0123).ordered
      g.template2 'hehe.rb', perms: 0123
    }
  end

  #---------------------------------------------------------------------------------------------------------------------

  describe '#add_executable_to_gemspec' do
#    run_each_in_empty_dir
    let(:g) { safe_gen }

    def gemspec(executable_line=nil, at_end=nil)
      if at_end.is_a? Array
        first= true
        at_end= at_end.map{|l| first ? (first=false; l) : "          #{l}" }.join "\n"
      end
      l= <<-EOB
        Gem::Specification.new do |ggem|
          ggem.date        = Time.new.strftime '%Y-%m-%d'
          #ggem.summary     = %q{Write a gem summary}
          ggem.authors       = ["That Guy"]

          ggem.files         = File.exists?('.git') ? `git ls-files`.split($\) : \
                              Dir['**/*'].reject{|f| !File.file? f or %r!^(?:target|resources/latest)/! === f}.sort
          ggem.require_paths = %w[lib]
          ggem.bindir        = 'bin'
          ---> #{executable_line}
          ggem.test_files    = gem.files.grep(/^test\//)

          ggem.add_runtime_dependency 'corvid'
          ---> #{at_end}
        end
      EOB
      l.gsub(/\n\s*?--->\s*?(?=\n)/, '') # Remove lines that contain nothing but --->
       .gsub('---> ', '')                # Remove ---> from non-empty lines
    end

    def exes(executables)
      executables ? "ggem.executables   = #{executables}" : ''
    end

    def add_exe(exe)
      "ggem.executables << #{exe.inspect} unless ggem.executables.include? #{exe.inspect}"
    end

    def mock_gemspec_content(filename, content)
      File.stub read: nil
      File.stub(:read).with(filename).and_return(content)
    end

    def test_string(before, expected, *args)
      filename= 'whatever.gemspec'
      mock_gemspec_content filename, before
#      g.should_receive(:create_file).once.with(filename, expected)
      g.instance_eval "def cf; @cf end; def create_file(*args) @cf<< args end; @cf= []"
      g.should_not_receive :say
      g.should_not_receive :say_status

      r= g.add_executable_to_gemspec filename, *args
      r.should == true

      files_updated_by_create_file= (g.cf || []).map{|e| e[0]}
      files_updated_by_create_file.should == [filename]
      g.cf[0][1].should == expected
    end

    def rem_blank_lines(line)
      line.gsub(/\n\s*?\n/,"\n")
    end

    context "when gemspec contains a %w array" do
      it ("adds one"){
        test_string gemspec(exes '%w||'), gemspec(exes '%w|sweet|'), 'sweet'
        test_string gemspec(exes '%w,,'), gemspec(exes '%w,sweet,'), 'sweet'
        test_string gemspec(exes '%w[]'), gemspec(exes '%w[sweet]'), 'sweet'
        test_string gemspec(exes '%w()'), gemspec(exes '%w(sweet)'), 'sweet'
        test_string gemspec(exes '%w{}'), gemspec(exes '%w{sweet}'), 'sweet'
      }

      it("adds multiple executables"){
        test_string gemspec(exes '%w[]'), gemspec(exes '%w[sweet bru]'), 'sweet','bru'
        test_string gemspec(exes '%w[cool]'), gemspec(exes '%w[cool sweet bru]'), 'sweet','bru'
      }

      it ("preserves existing elements"){
        test_string gemspec(exes '%w[really]'), gemspec(exes '%w[really sweet]'), 'sweet'
        test_string gemspec(exes '%w[rea ly]'), gemspec(exes '%w[rea ly sweet]'), 'sweet'
      }

      it ("preserves comments"){
        test_string gemspec(exes '%w[really] # what?'), gemspec(exes '%w[really sweet] # what?'), 'sweet'
      }

      it ("preserves suffixs"){
        test_string gemspec(exes '%w[really].sort.uniq'), gemspec(exes '%w[really sweet].sort.uniq'), 'sweet'
      }

      it ("handles multiple lines"){
        test_string gemspec(exes "%w[\n    c1\n    c2\n  ]"), gemspec(exes "%w[\n    c1\n    c2\n    sweet\n  ]"), 'sweet'
        test_string gemspec(exes "%w[\n    c1\n    c2\n  ]"), gemspec(exes "%w[\n    c1\n    c2\n    sweet\n    zzz\n  ]"), 'sweet','zzz'
      }

      it("adds as normal when proceeded by commented-out executables line"){
        comm= exes('%w[old]').sub('ggem', '# ggem') + "\n"
        test_string gemspec(comm + exes('%w[really]')), gemspec(comm + exes('%w[really sweet]')), 'sweet'
      }
    end

    context "when gemspec contains a plain array" do
      it ("adds one"){
        test_string gemspec(exes '[]'), gemspec(exes '["sweet"]'), 'sweet'
      }

      it("adds multiple executables"){
        test_string gemspec(exes '[]'), gemspec(exes '["sweet", "bru"]'), 'sweet','bru'
      }

      it ("preserves existing elements"){
        test_string gemspec(exes '["really"]'), gemspec(exes '["really", "sweet"]'), 'sweet'
        test_string gemspec(exes '["rea", "ly"]'), gemspec(exes '["rea", "ly", "sweet"]'), 'sweet'
        test_string gemspec(exes '[$really]'), gemspec(exes '[$really, "sweet"]'), 'sweet'
      }

      it ("preserves comments"){
        test_string gemspec(exes '["really"] # what?'), gemspec(exes '["really", "sweet"] # what?'), 'sweet'
      }

      it ("preserves suffixs"){
        test_string gemspec(exes '["really"].sort.uniq'), gemspec(exes '["really", "sweet"].sort.uniq'), 'sweet'
      }

      it("adds as normal when proceeded by commented-out executables line"){
        comm= exes('%w[old]').sub('ggem', '# ggem') + "\n"
        test_string gemspec(comm + exes('["really"]')), gemspec(comm + exes('["really", "sweet"]')), 'sweet'
      }
    end

    context "when gemspec doesn't define and executables" do
      it("adds a line (when gemspec contains blank lines)"){
        test_string gemspec(), gemspec(nil,'ggem.executables = ["sweet"]'), 'sweet'
      }

      it("adds a line (when gemspec doesn't contain blank lines)"){
        test_string rem_blank_lines(gemspec), rem_blank_lines(gemspec nil,'ggem.executables = ["sweet"]'), 'sweet'
      }

      it("ignores commented-out, old line and adds new line"){
        comment= exes('%w[old]').sub 'ggem', '# ggem'
        test_string gemspec(comment), gemspec(comment,'ggem.executables = ["sweet"]'), 'sweet'
      }
    end

    context "when gemspec contains some other definition" do
      it("appends one to the end"){
        ex_line= exes 'Dir["bin/*.sh"]'
        new_line= add_exe('sweet')
        test_string gemspec(ex_line), gemspec(ex_line, new_line), 'sweet'
      }

      it("appends multiple to the end"){
        ex_line= exes 'Dir["bin/*.sh"]'
        new_lines= [add_exe('sweet'), add_exe('bru')]
        test_string gemspec(ex_line), gemspec(ex_line, new_lines), 'sweet', 'bru'
      }
    end

    it("warns the user when it doesn't know how to update the gemspec"){
      mock_gemspec_content 'gs', 'what'
      g.should_not_receive :create_file
      g.should_receive(:say_status).once.with(anything(), /gs/, :red)
      r= g.add_executable_to_gemspec 'gs', 'my_exe'
      r.should == false
    }

    it("fails when the specified file doesn't exist"){
      expect{
        g.add_executable_to_gemspec 'what_file_is_this', 'z'
      }.to raise_error /what_file_is_this/
    }

    it("fails when non-strings are passed in as executable names"){
      mock_gemspec_content 'gs', ''
      expect{ g.add_executable_to_gemspec 'what_file_is_this', 3 }.to raise_error /Invalid name/
      expect{ g.add_executable_to_gemspec 'what_file_is_this', :hehe }.to raise_error /Invalid name/
      expect{ g.add_executable_to_gemspec 'what_file_is_this', {b:2} }.to raise_error /Invalid name/
    }
  end
end
