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

describe Syntax::Default do
  subject {described_class}

  let(:exception_klass) {"#{described_class}::BadOrderFormatError".constantize}

  context '#process' do
    it 'throws if line is too few fields for syntax' do
      expect{subject.process('field1')}.to raise_error(exception_klass)
    end

    it 'throws if line is too many fields for syntax' do
      expect{subject.process('field1 field2 field3')}.to raise_error(exception_klass)
    end

    it 'throws if amount field isnt an integer' do
      expect{subject.process('field1 field2')}.to raise_error(exception_klass)
    end

    it 'throws if item field isnt correct format for syntax' do
      expect{subject.process('10 field2')}.to raise_error(exception_klass)
    end
  end
end