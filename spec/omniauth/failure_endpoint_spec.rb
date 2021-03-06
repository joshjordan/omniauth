require 'helper'

describe OmniAuth::FailureEndpoint do
  subject{ OmniAuth::FailureEndpoint }

  context "raise-out environment" do
    before do
      @default, OmniAuth.config.failure_raise_out_environments = OmniAuth.config.failure_raise_out_environments, ['test']
    end

    it "raises out the error" do
      expect do
        subject.call('omniauth.error' => StandardError.new("Blah"))
      end.to raise_error(StandardError, "Blah")
    end

    it "raises out an OmniAuth::Error if no omniauth.error is set" do
      expect{ subject.call('omniauth.error.type' => 'example') }.to raise_error(OmniAuth::Error, "example")
    end

    after do
      OmniAuth.config.failure_raise_out_environments = @default
    end
  end

  context "non-raise-out environment" do
    let(:env){ {'omniauth.error.type' => 'invalid_request',
                'omniauth.error.strategy' => ExampleStrategy.new({}) } }

    it "is a redirect" do
      status, _, _ = *subject.call(env)
      expect(status).to eq(302)
    end

    it "includes the SCRIPT_NAME" do
      _, head, _ = *subject.call(env.merge('SCRIPT_NAME' => '/random'))
      expect(head['Location']).to eq('/random/auth/failure?message=invalid_request&strategy=test')
    end

    it "respects the configured path prefix" do
      OmniAuth.config.stub(:path_prefix => '/boo')
      _, head, _ = *subject.call(env)
      expect(head["Location"]).to eq('/boo/failure?message=invalid_request&strategy=test')
    end

    it "includes the origin (escaped) if one is provided" do
      env.merge! 'omniauth.origin' => '/origin-example'
      _, head, _ = *subject.call(env)
      expect(head['Location']).to be_include('&origin=%2Forigin-example')
    end

    it 'escapes the message key' do
      _, head = *subject.call(env.merge('omniauth.error.type' => 'Connection refused!'))
      expect(head['Location']).to be_include('message=Connection+refused%21')
    end
  end
end
