require 'spec_helper'
require 'logger'
require 'bosh/director/core/templates/job_template_renderer'
require 'bosh/director/core/templates/source_erb'

module Bosh::Director::Core::Templates
  describe JobTemplateRenderer do
    describe '#render' do
      let(:monit_erb) do
        instance_double(
          'Bosh::Director::Core::Templates::SourceErb',
          render: 'monit file',
        )
      end

      let(:source_erb) do
        instance_double(
          'Bosh::Director::Core::Templates::SourceErb',
          src_name: 'fake-template-src-name',
          dest_name: 'fake-template-dest-name',
          render: 'test template',
        )
      end

      let(:spec) do
        {
          'index' => 1,
          'job' => {
            'name' => 'fake-job-name',
          },
        }
      end

      let(:release) { double('Bosh::Director::DeploymentPlan::ReleaseVersion', name: 'fake-release-name', version: '0.1') }
      let(:job_template_model) { double('Bosh::Director::Models::Template', provides: []) }
      let(:job_template) do
        double('Bosh::Director::DeploymentPlan::Job', name: 'fake-job-name', release: release, model: job_template_model)
      end
      let(:logger) { instance_double('Logger', debug: nil) }
      let(:dns_encoder) { double('some DNS encoder') }

      subject(:job_template_renderer) do
        JobTemplateRenderer.new(job_template, 'template-name', monit_erb, [source_erb], logger, dns_encoder)
      end

      context 'when templates do not contain local properties' do
        let(:context) { instance_double('Bosh::Template::EvaluationContext') }
        before do
          allow(Bosh::Template::EvaluationContext).to receive(:new).and_return(context)
        end

        it 'returns a collection of rendered templates' do
          rendered_templates = job_template_renderer.render(spec)

          expect(rendered_templates.monit).to eq('monit file')
          rendered_file_template = rendered_templates.templates.first
          expect(rendered_file_template.src_name).to eq('fake-template-src-name')
          expect(rendered_file_template.dest_name).to eq('fake-template-dest-name')
          expect(rendered_file_template.contents).to eq('test template')

          expect(monit_erb).to have_received(:render).with(context, logger)
          expect(source_erb).to have_received(:render).with(context, logger)
        end
      end

      context 'when template has local properties' do
        let(:spec) do
          {
            'index' => 1,
            'job' => {
              'name' => 'reg-job-name',
              'templates' =>
                      [{ 'name' => 'template-name',
                         'version' => '1bbe5ab00082797999e2101d730de64aeb601b6a',
                         'sha1' => '728399f9ef342532c6224bce4eb5331b5c38d595',
                         'blobstore_id' => '6c1eec85-3c08-4464-8b11-dc43acaa79f9' }],
            },
            'properties' => {
              'template-name' => {
                'inside' => 'insideValue',
                'smurfs' => { 'name' => 'snoopy' },
              },
            },
            'properties_need_filtering' => true,
            'release' => { 'name' => 'fake-release-name', 'version' => '0.1' },
          }
        end

        before do
          allow(Bosh::Template::EvaluationContext).to receive(:new)
        end

        it 'should adjust the spec passed to the evaluation context' do
          job_template_renderer.render(spec)
          expect(Bosh::Template::EvaluationContext).to have_received(:new).with(
            {
              'index' => 1,
              'job' => {
                'name' => 'reg-job-name',
                'templates' =>
                        [{ 'name' => 'template-name',
                           'version' => '1bbe5ab00082797999e2101d730de64aeb601b6a',
                           'sha1' => '728399f9ef342532c6224bce4eb5331b5c38d595',
                           'blobstore_id' => '6c1eec85-3c08-4464-8b11-dc43acaa79f9' }],
              },
              'properties' => { # note: loses 'template-name' from :spec
                'inside' => 'insideValue',
                'smurfs' => { 'name' => 'snoopy' },
              },
              'properties_need_filtering' => true,
              'release' => { 'name' => 'fake-release-name', 'version' => '0.1' },
            }, dns_encoder
          ).at_least(2).times
        end

        context 'rendering templates returns errors' do
          let(:job_template_renderer) do
            JobTemplateRenderer.new(job_template, 'template-name', monit_erb, [source_erb, source_erb], logger, dns_encoder)
          end

          before do
            allow(source_erb).to receive(:render).and_raise('Error filling something in the template')
          end

          it 'formats the error messages is a generic way' do
            expected_error_msg = <<~EXPECTED.strip
              - Unable to render templates for job 'fake-job-name'. Errors are:
                - Error filling something in the template
                - Error filling something in the template
            EXPECTED

            expect do
              job_template_renderer.render(spec)
            end.to(raise_error { |error| expect(error.message).to eq(expected_error_msg) })
          end
        end
      end

      context 'when spec has links' do
        let(:raw_spec) do
          {
            'index' => 1,
            'job' => {
              'name' => 'template-name',
            },
            'properties_need_filtering' => true,
            'links' => {
              'template-name' => {
                'db_link' =>
                    { 'properties' => { 'foo' => 'bar' }, 'instances' => [{ 'name' => 'mysql1' }, { 'name' => 'mysql' }] },
                'backup_db' =>
                    { 'properties' => { 'moop' => 'yar' }, 'instances' => [{ 'name' => 'postgres1' }, { 'name' => 'postgres' }] },
              },
            },
            'release' => { 'name' => 'fake-release-name', 'version' => '0.1' },
          }
        end

        let(:modified_spec) do
          {
            'index' => 1,
            'job' => {
              'name' => 'template-name',
            },
            'properties_need_filtering' => true,
            'links' => {
              'db_link' =>
              {
                'properties' => { 'foo' => 'bar' },
                'instances' => [{ 'name' => 'mysql1' }, { 'name' => 'mysql' }],
              },
              'backup_db' =>
                  {
                    'properties' => { 'moop' => 'yar' },
                    'instances' => [{ 'name' => 'postgres1' }, { 'name' => 'postgres' }],
                  },
            },
            'release' => { 'name' => 'fake-release-name', 'version' => '0.1' },
          }
        end

        before do
          allow(Bosh::Template::EvaluationContext).to receive(:new)
          allow(job_template_model).to receive(:provides).and_return([{
            'name' => 'LINKNAME',
            'type' => 'LINKTYPE',
          }])
          allow(dns_encoder).to receive(:id_for_group_tuple).and_return('group_id')
        end

        it 'should have EvaluationContext called with correct spec' do
          job_template_renderer.render(raw_spec)
          expect(Bosh::Template::EvaluationContext).to have_received(:new).with(modified_spec, dns_encoder).at_least(2).times
        end

        it 'appends a rendered template with link dns data' do
          rendered_files = job_template_renderer.render(raw_spec).templates
          expect(dns_encoder).to have_received(:id_for_group_tuple).with(
            'link',
            'LINKNAME-LINKTYPE',
            nil,
          )

          rendered_links_file = rendered_files.pop
          expect(rendered_links_file.src_name).to(eq('.bosh/links.json'))
          expect(rendered_links_file.dest_name).to(eq('.bosh/links.json'))

          expect(JSON.parse(rendered_links_file.contents)).to(eq([{
            'name' => 'LINKNAME',
            'type' => 'LINKTYPE',
            'group' => 'group_id',
          }]))
        end
      end
    end
  end
end
