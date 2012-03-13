require "spec_helper"

describe Writing::Server do
  let(:root)     { stub }
  let(:options)  { stub }
  let(:instance) { stub(:root => root, :options => options) }

  subject { Writing::Server.new(instance) }

  it "assigns provided instance options" do
    subject.options.should == options
  end

  it "assigns provided instance root" do
    subject.root.should == root
  end
end

describe Writing::Server, "#start" do
  let(:root)     { stub }
  let(:server)   { stub(:start => true) }
  let(:thread)   { stub(:join => true) }
  let(:options)  { { "server" => 4001, "verbose" => false } }
  let(:instance) { stub(:root => root, :options => options) }

  subject { Writing::Server.new(instance) }

  before do
    Thread.stubs(:new).returns(thread)
    Thin::Logging.stubs(:silent=)
    Thin::Server.stubs(:new).returns(server)
    subject.stubs(:run => true, :use => true)
  end

  it "creates a new thread" do
    subject.start
    Thread.should have_received(:new)
  end

  it "sets the server logging to silent when not verbose" do
    subject.start
    Thin::Logging.should have_received(:silent=).with(true)
  end

  it "sets the server logging to silent when verbose" do
    subject.options["verbose"] = true
    subject.start
    Thin::Logging.should have_received(:silent=).with(false)
  end

  it "creates a server" do
    subject.start
    Thin::Server.should have_received(:new).with("0.0.0.0", options["server"])
  end

  it "does not use or run until server yields" do
    subject.start
    subject.should have_received(:use).never
    subject.should have_received(:run).never
  end

  it "uses Rack::CommonLogger when verbose" do
    Thin::Server.stubs(:new).yields.returns(server)
    subject.options["verbose"] = true
    subject.start
    subject.should have_received(:use).with(Rack::CommonLogger)
  end

  it "does not use Rack::CommonLogger when not verbose" do
    Thin::Server.stubs(:new).yields.returns(server)
    subject.start
    subject.should have_received(:use).with(Rack::CommonLogger).never
  end

  it "uses Rack::Deflater" do
    Thin::Server.stubs(:new).yields.returns(server)
    subject.start
    subject.should have_received(:use).with(Rack::Deflater)
  end

  it "uses Rack::Static" do
    Thin::Server.stubs(:new).yields.returns(server)
    subject.start
    subject.should have_received(:use).with(Rack::Static, :root => root, :index => "index.html")
  end

  it "runs the Rack application" do
    Thin::Server.stubs(:new).yields.returns(server)
    subject.start
    subject.should have_received(:run)
  end

  it "starts the server in the thread" do
    subject.start
    server.should have_received(:start).never
    Thread.stubs(:new).yields.returns(thread)
    subject.start
    server.should have_received(:start)
  end
end
