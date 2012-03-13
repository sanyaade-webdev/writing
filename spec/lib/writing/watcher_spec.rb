require "spec_helper"

describe Writing::Watcher do
  let(:root)     { stub }
  let(:options)  { stub }
  let(:instance) { stub(:root => root, :options => options) }

  subject { Writing::Watcher.new(instance) }

  it "assigns provided instance" do
    subject.instance.should == instance
  end

  it "assigns provided instance options" do
    subject.options.should == options
  end

  it "assigns provided instance root" do
    subject.root.should == root
  end
end

describe Writing::Watcher, "#start" do
  let(:root)     { stub }
  let(:instance) { stub(:root => root, :options => stub) }

  subject { Writing::Watcher.new(instance) }

  before do
    Dir.stubs(:[] => files, :chdir => true)
    File.stubs(:directory?).with(file).returns(false)
    File.stubs(:directory?).with(directory).returns(true)
  end
end

describe Writing::Watcher, "#log" do
  let(:events)   { stub(:size => 2) }
  let(:instance) { stub(:root => stub, :options => stub) }

  subject { Writing::Watcher.new(instance) }

  before do
    subject.stubs(:print => true, :verbose? => false)
  end

  it "prints the current time formatted" do
    subject.log(events)
    subject.should have_received(:print).with("[#{Time.now.strftime("%Y-%m-%d %H:%M:%S")}] ")
  end

  it "prints the number of files changing" do
    subject.log(events)
    subject.should have_received(:print).with("2 files changed, regenerating...")
  end

  it "prints 'Done.' after yielding" do
    yielded = false
    subject.log(events) do
      yielded = true
      subject.should have_received(:print).with(" Done.\n").never
    end
    yielded.should be_true
    subject.should have_received(:print).with(" Done.\n")
  end

  it "does not print a newline when not verbose" do
    subject.log(events)
    subject.should have_received(:print).with("\n").never
  end

  it "prints a newline when verbose" do
    subject.stubs(:verbose? => true)
    subject.log(events)
    subject.should have_received(:print).with("\n")
  end

  it "does not print 'Done.' when verbose" do
    subject.stubs(:verbose? => true)
    subject.log(events)
    subject.should have_received(:print).with(" Done.\n").never
  end
end

describe Writing::Watcher, "#start" do
  let(:root)     { stub }
  let(:options)  { { "server" => 4001 } }
  let(:watcher)  { stub(:add_observer => true, :start => true) }
  let(:instance) { stub(:root => root, :options => options) }

  subject { Writing::Watcher.new(instance) }

  before do
    subject.stubs(:loop => true, :root => root, :sleep => true)
    DirectoryWatcher.stubs(:new => watcher)
  end

  it "creates a directory watcher" do
    subject.start
    DirectoryWatcher.should have_received(:new).with(root, :interval => 1, :glob => ["**/*", "**/**/*"])
  end

  it "adds the update method as an observer, using call as the function" do
    subject.start
    watcher.should have_received(:add_observer).with(subject.method(:update), :call)
  end

  it "starts the watcher" do
    subject.start
    watcher.should have_received(:start)
  end

  it "does not create a sleeping loop when the server is enabled" do
    subject.start
    subject.should have_received(:loop).never
    subject.should have_received(:sleep).never
  end

  it "creates a sleeping loop when the server is not enabled" do
    options.delete("server")

    subject.start
    subject.should have_received(:loop)
    subject.should have_received(:sleep).never

    subject.stubs(:loop).yields
    subject.start
    subject.should have_received(:sleep).with(1000)
  end
end

describe Writing::Watcher, "#update" do
  let(:events)   { stub(:empty? => false) }
  let(:instance) { stub(:root => stub, :options => stub, :update => true) }

  subject { Writing::Watcher.new(instance) }

  before do
    subject.stubs(:log)
  end

  it "logs the events" do
    subject.update(events, events)
    subject.should have_received(:log).with([events, events])
  end

  it "updates the instance" do
    subject.stubs(:log).yields
    subject.update(events, events)
    instance.should have_received(:update)
  end

  it "ignores the updating of the output file" do
    subject.update(stub(:path => "root/index.html"))
    subject.should have_received(:log).never
    instance.should have_received(:update).never
  end
end

describe Writing::Watcher, "#verbose?" do
  let(:options)  { { "verbose" => stub } }
  let(:instance) { stub(:root => stub, :options => options) }

  subject { Writing::Watcher.new(instance) }

  it "returns the verbose option" do
    subject.verbose?.should == options["verbose"]
  end
end
