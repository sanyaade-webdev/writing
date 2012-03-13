require "spec_helper"

describe Writing do
  let(:options) { { :auto => true } }

  subject { Writing.new(options) }

  it "assigns provided options" do
    subject.options.should == options
  end
end

describe Writing, "#update" do
  let(:html)     { stub }
  let(:source)   { stub }
  let(:template) { stub(:result => source) }

  before do
    ERB.stubs(:new => template)
    File.stubs(:read => html)
    File.stubs(:write)
    subject.stubs(:source_for).with("js/application.js").returns("js")
    subject.stubs(:source_for).with("css/application.css").returns("css")
  end

  it "retrieves the source for the application JS" do
    subject.update
    subject.should have_received(:source_for).with("js/application.js")
  end

  it "retrieves the source for the application CSS" do
    subject.update
    subject.should have_received(:source_for).with("css/application.css")
  end

  it "reads the index.html.erb file" do
    subject.update
    File.should have_received(:read).with(subject.root.join("index.html.erb"))
  end

  it "creates an ERB instance with the index.html.erb file" do
    subject.update
    ERB.should have_received(:new).with(html)
  end

  it "compiles the template for the current binding" do
    subject.update
    template.should have_received(:result)#.with(subject.binding)
  end

  it "writes the compiled template to the index.html file" do
    subject.update
    File.should have_received(:write).with(subject.root.join("index.html"), source)
  end
end

describe Writing, "#root" do
  it "returns the current working directory as a pathname, by default" do
    subject = Writing.new
    subject.root.should be_a(Pathname)
    subject.root.to_s.should == Dir.pwd
  end

  it "returns the root directory defined in the options as a pathname, when provided" do
    subject = Writing.new("root" => "/var/www")
    subject.root.should be_a(Pathname)
    subject.root.to_s.should == "/var/www"
  end
end

describe Writing, "#source_for" do
  let(:asset)     { stub(:source => source) }
  let(:path)      { stub }
  let(:source)    { stub }
  let(:sprockets) { stub(:find_asset => asset) }

  before do
    subject.stubs(:sprockets => sprockets)
  end

  it "finds the asset for the specified path" do
    subject.source_for(path)
    sprockets.should have_received(:find_asset).with(path)
  end

  it "returns the source of the asset" do
    subject.source_for(path).should == source
  end
end

describe Writing, "#sprockets" do
  let(:options)          { { :compress => false } }
  let(:css_compressor)   { stub }
  let(:closure_compiler) { stub }
  let(:environment)      { stub(:append_path => true, :css_compressor= => true, :js_compressor= => true, :options => options) }

  before do
    Closure::Compiler.stubs(:new => closure_compiler)
    YUI::CssCompressor.stubs(:new => css_compressor)
    Sprockets::Environment.stubs(:new => environment)
  end

  it "creates a sprocket environment for the root directory" do
    subject.sprockets
    Sprockets::Environment.should have_received(:new).with(subject.root)
  end

  it "does not set the CSS or JS compressor, if compression is not enabled" do
    subject.sprockets
    environment.should have_received(:js_compressor=).never
    environment.should have_received(:css_compressor=).never
  end

  it "sets the JS compressor to Closure Compiler, if compression is enabled" do
    subject.options["compress"] = true
    subject.sprockets
    environment.should have_received(:js_compressor=).with(closure_compiler)
  end

  it "sets the CSS compressor to YUI, if compression is enabled" do
    subject.options["compress"] = true
    subject.sprockets
    environment.should have_received(:css_compressor=).with(css_compressor)
  end

  it "appends the public path" do
    subject.sprockets
    environment.should have_received(:append_path).with(subject.root.join("public"))
  end

  it "appends the public JS path" do
    subject.sprockets
    environment.should have_received(:append_path).with(subject.root.join("public", "js"))
  end

  it "appends the public JS vendor path" do
    subject.sprockets
    environment.should have_received(:append_path).with(subject.root.join("public", "js", "vendor"))
  end

  it "caches the environment instance" do
    subject.sprockets
    subject.sprockets
    Sprockets::Environment.should have_received(:new).once
  end

  it "returns the environment instance" do
    subject.sprockets.should == environment
    subject.sprockets.should == environment
  end
end

describe Writing, "#start" do
  let(:server)  { stub(:start => true) }
  let(:watcher) { stub(:start => true) }

  before do
    Writing::Server.stubs(:new).returns(server)
    Writing::Watcher.stubs(:new).returns(watcher)
  end

  it "creates and starts the server when enabled" do
    subject = Writing.new("server" => 4001)
    subject.start
    Writing::Server.should have_received(:new).with(subject)
  end

  it "does not create and start the server when not enabled" do
    subject = Writing.new
    subject.start
    Writing::Server.should have_received(:new).with(subject).never
  end

  it "creates and starts the watcher when enabled" do
    subject = Writing.new("auto" => true)
    subject.start
    Writing::Watcher.should have_received(:new).with(subject)
  end

  it "does not create and start the watcher when not enabled" do
    subject = Writing.new
    subject.start
    Writing::Watcher.should have_received(:new).with(subject).never
  end

  it "creates the watcher before the server" do
    subject  = Writing.new("auto" => true, "server" => 4001)
    sequence = sequence("start")

    Writing::Watcher.expects(:new).with(subject).in_sequence(sequence).returns(watcher)
    Writing::Server.expects(:new).with(subject).in_sequence(sequence).returns(server)

    subject.start
  end
end
