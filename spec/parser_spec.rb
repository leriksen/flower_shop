require 'spec_helper'

describe Parser::Default do
  let(:file) {
    StringIO.new <<-EOS
      10 R12
      15 L09
      13 T58
    EOS
  }

  subject {described_class.new file}

  context 'reading input' do
    before(:each) do
      file.rewind
    end

    it 'can iterate' do
      expect(subject).to respond_to(:each)

      list = []
      subject.each do |command, args|
        list << command
      end
      expect(list.length).to eql(3)
    end

    it 'can parse using default syntax' do
      expect(subject.first).to eql([10, 'R12'])
    end
  end
end
