require 'spec_helper'

module Bosh::Director::DeploymentPlan
  describe VmType do
    subject(:vm_type) { VmType.new(valid_spec) }
    let(:max_size) { 2 }

    let(:valid_spec) do
      {
        'name' => 'small',
        'cloud_properties' => { 'foo' => 'bar' },
      }
    end

    let(:plan) { instance_double('Bosh::Director::DeploymentPlan::Planner') }

    describe 'creating' do
      it 'parses name, cloud properties' do
        expect(vm_type.name).to eq('small')
        expect(vm_type.cloud_properties).to eq({ 'foo' => 'bar' })
      end

      context 'when name is missing' do
        before { valid_spec.delete('name') }

        it 'raises an error' do
          expect { VmType.new(valid_spec) }.to raise_error(BD::ValidationMissingField)
        end
      end

      context 'when cloud_properties is missing' do
        before { valid_spec.delete('cloud_properties') }

        it 'defaults to empty hash' do
          expect(vm_type.cloud_properties).to eq({})
        end
      end

      context 'when cloud_properties is a placeholder' do
        before { valid_spec['cloud_properties'] = '((cloud_properties_placeholder))' }

        it 'does not error' do
          expect{
            subject
          }.to_not raise_error
        end
      end
    end

    it 'returns vm type spec as Hash' do
      expect(vm_type.spec).to eq({
        'name' => 'small',
        'cloud_properties' => { 'foo' => 'bar' },
      })
    end

  end
end