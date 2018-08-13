require 'spec_helper'

describe 'Audit logs', type: :integration do
  with_reset_sandbox_before_each

  it 'writes audit logs', focus: true do
    deploy_from_scratch(
      manifest_hash: Bosh::Spec::NewDeployments.simple_manifest_with_instance_groups,
      cloud_config_hash: Bosh::Spec::NewDeployments.simple_cloud_config,
    )

    # expect('sandbox_path'). to eq(current_sandbox.sandbox_path('logs'))
    expect(File).to exist(File.join(current_sandbox.logs_path, 'audit.log'))
    expect(File).to exist(File.join(current_sandbox.logs_path, 'audit_worker_0.log'))
    expect(File).to exist(File.join(current_sandbox.logs_path, 'audit_worker_1.log'))
    expect(File).to exist(File.join(current_sandbox.logs_path, 'audit_worker_2.log'))
  end

  it 'contain request logs' do
    audit_log = File.open(File.join(current_sandbox.logs_path, 'audit.log')).read
    # expect(audit_log).to match(/.*CEF.*\/info.*/)
    expect(audit_log).to match(/.*DirectorAudit.*deadbeef.*/)
  end
end
