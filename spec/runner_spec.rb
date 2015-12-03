require 'spec_helper'

describe Runner do
  # just the class - we will test the construction first
  subject {described_class}

  context 'ctor' do
    context 'order file parameter' do
      context 'when missing' do
        it 'raises error' do
          expect{described_class.new nil, nil}.to raise_error(Runner::NoOrderFileError)
        end
      end

      context 'raises error when ' do
        before(:each) do
          expect(File).to receive(:exist?).and_return(true)
        end

        it 'unreadable' do
          expect(File).to receive(:readable?).and_return(false)
          expect{described_class.new('unreadable', nil)}.to raise_error(Runner::UnreadableOrderFileError)
        end

        it 'not a file' do
          expect(File).to receive(:readable?).and_return(true)
          expect(File).to receive(:file?    ).and_return(false)
          expect{described_class.new('not_a_file', nil)}.to raise_error(Runner::UnreadableOrderFileError)
        end
      end
    end

    context 'control file parameter' do
      # mark all order_file processing as successful
      before(:each) do
        allow(File).to receive(:exist?   ).with('order_file').and_return(true)
        allow(File).to receive(:readable?).with('order_file').and_return(true)
        allow(File).to receive(:file?    ).with('order_file').and_return(true)
      end

      context 'when missing' do
        it 'raises error' do
          expect{described_class.new 'order_file', nil}.to raise_error(Runner::NoControlFileError)
        end
      end

      context 'raises error when ' do
        before(:each) do
          expect(File).to receive(:exist?).with('control_file').and_return(true)
        end

        it 'unreadable' do
          expect(File).to receive(:readable?).with('control_file').and_return(false)
          expect{described_class.new('order_file', 'control_file')}.to raise_error(Runner::UnreadableControlFileError)
        end

        it 'not a file' do
          expect(File).to receive(:readable?).with('control_file').and_return(true)
          expect(File).to receive(:file?    ).with('control_file').and_return(false)
          expect{described_class.new('order_file', 'control_file')}.to raise_error(Runner::UnreadableControlFileError)
        end
      end
    end
  
    context 'with readable param files' do
      before(:each) do
        expect(File).to receive(:exist?).and_return(true).twice
        expect(File).to receive(:readable?).and_return(true).twice
        expect(File).to receive(:file?).and_return(true).twice
      end

      it "raises if bad yaml" do
        expect(Controller).to receive(:new).and_raise(Controller::BadControlFileError)
        expect{subject.new('order_file', 'corrupt_control_file')}.to raise_error(Runner::UnreadableControlFileError)
      end

      it "creates required resources" do
        controller = double('controller')
        resource = double('resource')
        expect(Controller).to receive(:new).and_return(controller)

        # controller will be asked these questions -these are the resources
        # that will have new called on them 
        %i(parser formatter pricer).each do |kind|
          expect(controller).to receive(kind).and_return(resource)
        end

        # and these - these are the data locations for the different
        # resources, or the way to lex the order file.
        %i(formatter_data pricer_data syntax).each do |kind|
          expect(controller).to receive(kind).and_return(resource)
        end

        # we arent testing the parser enumerable here, so the file open just has to return a value
        # that responds to .each, like all enumerables
        allow(File).to receive(:open).and_return([])
        expect(resource).to receive(:new).and_return(resource).thrice

        expect{subject.new('order_file', 'control_file')}.to_not raise_error
      end
    end
  end

  context ".run" do
    subject {described_class.new('order_file', 'control_file')}

    it 'can parse an order and calculate price' do
      expect(true).to be_truthy
    end
  end
end