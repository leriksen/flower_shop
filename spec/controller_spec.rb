require 'spec_helper'

describe Controller do
  # just class - we will test constructor first
  subject { described_class }

  context 'ctor' do
    it { is_expected.to respond_to(:new) }

    context 'with invalid yaml' do
      it 'raises error' do
        expect(YAML).to receive(:load_file).and_raise(YAML::SyntaxError)
        expect{subject.new('not_yaml')}.to raise_error(Controller::BadControlFileError)
      end
    end

    context 'with valid yaml, but undeclared strategy' do
      let(:yaml) {
        {
          "undeclared" => {
            "strategy" => "default",
            "data"     => "config/pricing.yaml"
          }
        }
      }

      before(:each) do
        expect(YAML).to receive(:load_file).and_return(yaml)
      end
      
      it 'raises with informative message' do
        expect{subject.new('yaml_file')}.to raise_error(Controller::BadControlFileError, 'could not find a file with a definition of Undeclared::Default')
      end
    end

    context 'with valid yaml' do
      # now in a position to test constructed class
      subject { described_class.new('yaml_file')}

      let(:yaml) {
        {
          "pricer" => {
            "strategy" => "default",
            "data"     => "config/pricing.yaml"
          }
        }
      }

      before(:each) do
        expect(YAML).to receive(:load_file).and_return(yaml)
      end

      it 'can build the required resources' do
        expect(subject).to respond_to(:pricer)
        expect(subject).to respond_to(:pricer_data)
      end

      it 'has resources that respond correctly' do
        expect(subject.pricer).to eql(Pricer::Default)
        expect(subject.pricer_data).to eql('config/pricing.yaml')
      end

      context 'with parser and syntax' do
        let(:yaml) {
          {
            "parser" => {
              "strategy" => "default",
              "syntax"   => "default"
            }
          }
        }

        it 'can build the required resources' do
          expect(subject).to respond_to(:parser)
          expect(subject).to respond_to(:syntax)
        end

        it 'has resources that respond correctly' do
          expect(subject.parser).to eql(Parser::Default)
          expect(subject.syntax).to eql(Syntax::Default)
        end

        
      end
    end
  end
end