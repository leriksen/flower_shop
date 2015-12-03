require 'spec_helper'

describe Pricer::Default do
  # just the class, we will test the constructor first
  subject { described_class }

  context 'ctor' do
    context 'with bad yaml file' do
      it 'raises error' do
        expect(YAML).to receive(:load_file).and_raise(YAML::SyntaxError)
        expect{subject.new('not_yaml')}.to raise_error(Pricer::Default::BadPricingFormatError)
      end
    end
  end

  context 'with valid yaml' do
    let(:yaml) {
      {
        'tulips' => {
          'bundles' => { 
            '3' => '500',
            '5' => '900',
            '9' => '1600'
            },
          'code' => 'T58'
        }
      }
    }

    subject { described_class.new('valid_yaml') }

    before(:each) do
      expect(YAML).to receive(:load_file).and_return(yaml)
    end
  

    it 'always calculated' do
      (8..100).each do |order|
        expect(subject.price('T58', order)).to respond_to(:first)
      end
    end 

    it 'detects unfillable order' do
      expect(subject.price('T58', 1)).to eql(-1)
      expect(subject.price('T58', 7)).to eql(-1)
    end
    it 'calculates correct price if exact bundle match' do
      expect(subject.price('T58', 9).first).to eql(1600)
    end
    it 'calculates correct price if lower bundle match' do
      expect(subject.price('T58',  5).first).to eql(900)
    end
    it 'calculates correct price if mixed bundle match' do
      # using degenerate case logic
      expect(subject.price('T58', 11).first).to eql(1900)
    end
    it 'calculates correct price if multisub bundles' do
      expect(subject.price('T58', 16).first).to eql(2800)
    end
    it 'calculates correct price if all bundle match' do
      expect(subject.price('T58', 17).first).to eql(3000)
    end
    it 'calculates correct price if with only sub-bundle matches' do
      expect(subject.price('T58', 13).first).to eql(2300)
    end

  end
end