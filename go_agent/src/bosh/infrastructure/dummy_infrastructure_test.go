package infrastructure_test

import (
	"encoding/json"
	"github.com/stretchr/testify/assert"
	"path/filepath"
	"time"

	. "github.com/onsi/ginkgo"

	. "bosh/infrastructure"
	boshdevicepathresolver "bosh/infrastructure/device_path_resolver"
	fakeplatform "bosh/platform/fakes"
	boshsettings "bosh/settings"
	boshdir "bosh/settings/directories"
	fakefs "bosh/system/fakes"
)

func init() {
	Describe("dummyInfrastructure", func() {
		It("get settings", func() {
			fs := fakefs.NewFakeFileSystem()
			dirProvider := boshdir.NewDirectoriesProvider("/var/vcap")
			platform := fakeplatform.NewFakePlatform()
			fakeDevicePathResolver := boshdevicepathresolver.NewFakeDevicePathResolver(1*time.Millisecond, platform.GetFs())

			settingsPath := filepath.Join(dirProvider.BoshDir(), "agent-env.json")

			expectedSettings := boshsettings.Settings{
				AgentId: "123-456-789",
				Blobstore: boshsettings.Blobstore{
					Type: boshsettings.BlobstoreTypeDummy,
				},
				Mbus: "nats://127.0.0.1:4222",
			}
			existingSettingsBytes, _ := json.Marshal(expectedSettings)
			fs.WriteFile(settingsPath, existingSettingsBytes)

			dummy := NewDummyInfrastructure(fs, dirProvider, platform, fakeDevicePathResolver)

			settings, err := dummy.GetSettings()
			assert.NoError(GinkgoT(), err)
			assert.Equal(GinkgoT(), settings, boshsettings.Settings{
				AgentId:   "123-456-789",
				Blobstore: boshsettings.Blobstore{Type: boshsettings.BlobstoreTypeDummy},
				Mbus:      "nats://127.0.0.1:4222",
			})
		})

		It("get settings errs when settings file does not exist", func() {
			fs := fakefs.NewFakeFileSystem()
			dirProvider := boshdir.NewDirectoriesProvider("/var/vcap")
			platform := fakeplatform.NewFakePlatform()
			fakeDevicePathResolver := boshdevicepathresolver.NewFakeDevicePathResolver(1*time.Millisecond, platform.GetFs())

			dummy := NewDummyInfrastructure(fs, dirProvider, platform, fakeDevicePathResolver)

			_, err := dummy.GetSettings()
			assert.Error(GinkgoT(), err)
			assert.Contains(GinkgoT(), err.Error(), "Read settings file")
		})
	})
}
