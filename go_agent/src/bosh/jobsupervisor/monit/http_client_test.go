package monit_test

import (
	"encoding/base64"
	"errors"
	"fmt"
	"github.com/stretchr/testify/assert"
	"io"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"time"

	. "github.com/onsi/ginkgo"

	. "bosh/jobsupervisor/monit"
	"bosh/jobsupervisor/monit/http_fakes"
	boshlog "bosh/logger"
)

func init() {
	Describe("httpClient", func() {
		var (
			logger = boshlog.NewLogger(boshlog.LEVEL_NONE)
		)

		It("services in group returns services when found", func() {})

		It("services in group errors when not found", func() {})

		Describe("StartService", func() {
			It("start service", func() {
				var calledMonit bool

				handler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
					calledMonit = true
					assert.Equal(GinkgoT(), r.Method, "POST")
					assert.Equal(GinkgoT(), r.URL.Path, "/test-service")
					assert.Equal(GinkgoT(), r.PostFormValue("action"), "start")
					assert.Equal(GinkgoT(), r.Header.Get("Content-Type"), "application/x-www-form-urlencoded")

					expectedAuthEncoded := base64.URLEncoding.EncodeToString([]byte("fake-user:fake-pass"))
					assert.Equal(GinkgoT(), r.Header.Get("Authorization"), fmt.Sprintf("Basic %s", expectedAuthEncoded))
				})
				ts := httptest.NewServer(handler)
				defer ts.Close()

				client := NewHttpClient(ts.Listener.Addr().String(), "fake-user", "fake-pass", http.DefaultClient, 1*time.Millisecond, logger)

				err := client.StartService("test-service")
				assert.NoError(GinkgoT(), err)
				assert.True(GinkgoT(), calledMonit)
			})

			It("start service retries when non200 response", func() {
				fakeHttpClient := http_fakes.NewFakeHttpClient()
				fakeHttpClient.StatusCode = 500
				fakeHttpClient.SetMessage("fake error message")

				client := NewHttpClient("agent.example.com", "fake-user", "fake-pass", fakeHttpClient, 1*time.Millisecond, logger)

				err := client.StartService("test-service")
				assert.Equal(GinkgoT(), fakeHttpClient.CallCount, 20)
				assert.Error(GinkgoT(), err)
			})

			It("start service retries when connection refused", func() {
				fakeHttpClient := http_fakes.NewFakeHttpClient()
				fakeHttpClient.SetNilResponse()
				fakeHttpClient.Error = errors.New("some error")

				client := NewHttpClient("agent.example.com", "fake-user", "fake-pass", fakeHttpClient, 1*time.Millisecond, logger)

				err := client.StartService("test-service")
				assert.Equal(GinkgoT(), fakeHttpClient.CallCount, 20)
				assert.Error(GinkgoT(), err)
			})
		})

		Describe("StopService", func() {
			It("stop service", func() {
				var calledMonit bool

				handler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
					calledMonit = true
					assert.Equal(GinkgoT(), r.Method, "POST")
					assert.Equal(GinkgoT(), r.URL.Path, "/test-service")
					assert.Equal(GinkgoT(), r.PostFormValue("action"), "stop")
					assert.Equal(GinkgoT(), r.Header.Get("Content-Type"), "application/x-www-form-urlencoded")

					expectedAuthEncoded := base64.URLEncoding.EncodeToString([]byte("fake-user:fake-pass"))
					assert.Equal(GinkgoT(), r.Header.Get("Authorization"), fmt.Sprintf("Basic %s", expectedAuthEncoded))
				})
				ts := httptest.NewServer(handler)
				defer ts.Close()

				client := NewHttpClient(ts.Listener.Addr().String(), "fake-user", "fake-pass", http.DefaultClient, 1*time.Millisecond, logger)

				err := client.StopService("test-service")
				assert.NoError(GinkgoT(), err)
				assert.True(GinkgoT(), calledMonit)
			})

			It("stop service retries when non200 response", func() {
				fakeHttpClient := http_fakes.NewFakeHttpClient()
				fakeHttpClient.StatusCode = 500
				fakeHttpClient.SetMessage("fake error message")

				client := NewHttpClient("agent.example.com", "fake-user", "fake-pass", fakeHttpClient, 1*time.Millisecond, logger)

				err := client.StopService("test-service")
				assert.Equal(GinkgoT(), fakeHttpClient.CallCount, 20)
				assert.Error(GinkgoT(), err)
				assert.Contains(GinkgoT(), err.Error(), "fake error message")
			})

			It("stop service retries when connection refused", func() {
				fakeHttpClient := http_fakes.NewFakeHttpClient()
				fakeHttpClient.SetNilResponse()
				fakeHttpClient.Error = errors.New("some error")

				client := NewHttpClient("agent.example.com", "fake-user", "fake-pass", fakeHttpClient, 1*time.Millisecond, logger)

				err := client.StopService("test-service")
				assert.Equal(GinkgoT(), fakeHttpClient.CallCount, 20)
				assert.Error(GinkgoT(), err)
				assert.Contains(GinkgoT(), err.Error(), "some error")
			})
		})

		Describe("ServicesInGroup", func() {
			It("services in group", func() {
				monitStatusFilePath, _ := filepath.Abs("../../../../fixtures/monit_status.xml")
				assert.NotNil(GinkgoT(), monitStatusFilePath)

				file, err := os.Open(monitStatusFilePath)
				assert.NoError(GinkgoT(), err)
				defer file.Close()

				handler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
					io.Copy(w, file)
					assert.Equal(GinkgoT(), r.Method, "GET")
					assert.Equal(GinkgoT(), r.URL.Path, "/_status2")
					assert.Equal(GinkgoT(), r.URL.Query().Get("format"), "xml")
				})
				ts := httptest.NewServer(handler)
				defer ts.Close()

				client := NewHttpClient(ts.Listener.Addr().String(), "fake-user", "fake-pass", http.DefaultClient, 1*time.Millisecond, logger)

				services, err := client.ServicesInGroup("vcap")
				assert.NoError(GinkgoT(), err)
				assert.Equal(GinkgoT(), []string{"dummy"}, services)
			})
		})

		Describe("Status", func() {
			It("decode status", func() {
				monitStatusFilePath, _ := filepath.Abs("../../../../fixtures/monit_status.xml")
				assert.NotNil(GinkgoT(), monitStatusFilePath)

				file, err := os.Open(monitStatusFilePath)
				assert.NoError(GinkgoT(), err)
				defer file.Close()

				handler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
					io.Copy(w, file)
					assert.Equal(GinkgoT(), r.Method, "GET")
					assert.Equal(GinkgoT(), r.URL.Path, "/_status2")
					assert.Equal(GinkgoT(), r.URL.Query().Get("format"), "xml")
				})
				ts := httptest.NewServer(handler)
				defer ts.Close()

				client := NewHttpClient(ts.Listener.Addr().String(), "fake-user", "fake-pass", http.DefaultClient, 1*time.Millisecond, logger)

				status, err := client.Status()
				assert.NoError(GinkgoT(), err)
				dummyServices := status.ServicesInGroup("vcap")
				assert.Equal(GinkgoT(), 1, len(dummyServices))
			})

			It("status retries when non200 response", func() {
				fakeHttpClient := http_fakes.NewFakeHttpClient()
				fakeHttpClient.StatusCode = 500
				fakeHttpClient.SetMessage("fake error message")

				client := NewHttpClient("agent.example.com", "fake-user", "fake-pass", fakeHttpClient, 1*time.Millisecond, logger)

				_, err := client.Status()
				assert.Equal(GinkgoT(), fakeHttpClient.CallCount, 20)
				assert.Error(GinkgoT(), err)
				assert.Contains(GinkgoT(), err.Error(), "fake error message")
			})

			It("status retries when connection refused", func() {
				fakeHttpClient := http_fakes.NewFakeHttpClient()
				fakeHttpClient.SetNilResponse()
				fakeHttpClient.Error = errors.New("some error")

				client := NewHttpClient("agent.example.com", "fake-user", "fake-pass", fakeHttpClient, 1*time.Millisecond, logger)

				err := client.StartService("hello")
				assert.Equal(GinkgoT(), fakeHttpClient.CallCount, 20)
				assert.Error(GinkgoT(), err)
				assert.Contains(GinkgoT(), err.Error(), "some error")

				for _, req := range fakeHttpClient.RequestBodies {
					assert.Equal(GinkgoT(), req, "action=start")
				}
			})
		})
	})
}
