module Bosh::Clouds
  class ExternalCpiResponseWrapper
    def initialize(cpi, cpi_api_version)
      @cpi = cpi
      @cpi_api_version = cpi_api_version
      @cpi.request_cpi_api_version = @cpi_api_version

      check_cpi_api_support
    end

    def current_vm_id(*arguments); invoke_cpi_method(__method__.to_s, *arguments); end
    def create_stemcell(*arguments); invoke_cpi_method(__method__.to_s, *arguments); end
    def delete_stemcell(*arguments); invoke_cpi_method(__method__.to_s, *arguments); end
    def delete_vm(*arguments); invoke_cpi_method(__method__.to_s, *arguments); end
    def has_vm(*arguments); invoke_cpi_method(__method__.to_s, *arguments); end
    def reboot_vm(*arguments); invoke_cpi_method(__method__.to_s, *arguments); end
    def set_vm_metadata(*arguments); invoke_cpi_method(__method__.to_s, *arguments); end
    def set_disk_metadata(*arguments); invoke_cpi_method(__method__.to_s, *arguments); end
    def create_disk(*arguments); invoke_cpi_method(__method__.to_s, *arguments); end
    def has_disk(*arguments); invoke_cpi_method(__method__.to_s, *arguments); end
    def delete_disk(*arguments); invoke_cpi_method(__method__.to_s, *arguments); end
    def attach_disk(*arguments); invoke_cpi_method(__method__.to_s, *arguments); end
    def detach_disk(*arguments); invoke_cpi_method(__method__.to_s, *arguments); end
    def snapshot_disk(*arguments); invoke_cpi_method(__method__.to_s, *arguments); end
    def delete_snapshot(*arguments); invoke_cpi_method(__method__.to_s, *arguments); end
    def resize_disk(*arguments); invoke_cpi_method(__method__.to_s, *arguments); end
    def get_disks(*arguments); invoke_cpi_method(__method__.to_s, *arguments); end
    def ping(*arguments); invoke_cpi_method(__method__.to_s, *arguments); end
    def calculate_vm_cloud_properties(*arguments); invoke_cpi_method(__method__.to_s, *arguments); end
    def info; invoke_cpi_method(__method__.to_s); end

    def invoke_cpi_method(method, *arguments)
      @cpi.public_send(method, *arguments)
    end

    def create_vm(*args)
      cpi_response = @cpi.create_vm(*args)

      response = []
      case @cpi_api_version
      when 2
        response = cpi_response
      when 1
        response << cpi_response
      end

      response
    end

    private

    def check_cpi_api_support
      raise Bosh::Clouds::NotSupported, "CPI API version #{@cpi_api_version} is not supported." unless @cpi_api_version <= Bosh::Director::CloudFactory::MAX_SUPPORTED_CPI_VERSION
    end
  end
end
