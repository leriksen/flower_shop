require 'spec_helper'

describe Formatter::Default do
  # just class, test constructor first
  subject { described_class }

  context 'ctor' do
    it 'can detect if drain is an string representation of IO object' do
      drain = 'STDOUT'

      expect(drain).to receive(:constantize).and_return(STDOUT)
      subject.new drain
    end

    it 'can detect that drain is an IO object directly' do
      expect(STDOUT).to receive(:respond_to?).with(:puts).and_call_original
      subject.new STDOUT
    end

    it 'can detect if drain is not IO object' do
      drain = 'file_name'
      expect(drain).to receive(:constantize).and_raise(NameError)
      expect(File).to receive(:open).with(drain, 770).and_return(true)
      subject.new drain
    end
  end

  context '.format' do
    let(:drain) {StringIO.new}
    subject { described_class.new(drain) }

    it "records the order in the correct format" do
      subject.format('type', 10, 1000, [[1, 10, 1000]])
      expect(drain.string).to eql("10 type $10.00\n       1 x 10 $10.00\n")
    end
  end
end