require 'rails_helper'

describe UserEventCreator do
  let(:user_agent) { 'A computer on the internet' }
  let(:ip_address) { '4.4.4.4' }
  let(:existing_device_cookie) { 'existing_device_cookie' }
  let(:request) do
    request = double

    allow(request).to receive(:remote_ip).and_return(ip_address)
    allow(request).to receive(:user_agent).and_return(user_agent)

    cookie_jar = { device: existing_device_cookie }.with_indifferent_access
    allow(cookie_jar).to receive(:permanent).and_return({})
    allow(request).to receive(:cookie_jar).and_return(cookie_jar)
    request
  end
  let(:user) { create(:user) }
  let(:device) { create(:device, user: user, cookie_uuid: existing_device_cookie) }
  let(:event_type) { 'account_created' }

  subject { UserEventCreator.new(request: request, current_user: user) }

  before do
    # Memoize user and device before specs run
    user
    device
  end

  describe '#create_user_event' do
    context 'when a device exists for the user' do
      it 'updates the device and creates an event' do
        event = subject.create_user_event(event_type, user)

        expect(event.event_type).to eq(event_type)
        expect(event.ip).to eq(ip_address)
        expect(event.device).to eq(device.reload)
        expect(device.last_ip).to eq(ip_address)
        expect(device.last_used_at).to be_within(1).of(Time.zone.now)
      end
    end

    context 'when a device exists that is not associated with the user' do
      let(:device) { create(:device, cookie_uuid: existing_device_cookie) }

      it 'creates a device and creates an event' do
        expect(UserAlerts::AlertUserAboutNewDevice).to_not receive(:call)

        event = subject.create_user_event(event_type, user)

        expect(event.event_type).to eq(event_type)
        expect(event.ip).to eq(ip_address)
        expect(event.device.id).to_not eq(device.reload.id)
        expect(event.device.last_ip).to eq(ip_address)
        expect(event.device.last_used_at).to be_within(1).of(Time.zone.now)
      end

      it 'alerts the user if they have other devices' do
        allow(UserAlerts::AlertUserAboutNewDevice).to receive(:call)
        create(:device, user: user)

        event = subject.create_user_event(event_type, user)

        expect(event).to be_a(Event)
        expect(UserAlerts::AlertUserAboutNewDevice).to have_received(:call).
          with(user, user.events.first.device, instance_of(String))
      end
    end

    context 'when no device exists' do
      let(:device) { nil }

      it 'creates a device and creates an event' do
        expect(UserAlerts::AlertUserAboutNewDevice).to_not receive(:call)

        event = subject.create_user_event(event_type, user)

        expect(event.event_type).to eq(event_type)
        expect(event.ip).to eq(ip_address)
        expect(event.device.last_ip).to eq(ip_address)
        expect(event.device.last_used_at).to be_within(1).of(Time.zone.now)
      end

      it 'alerts the user if they have other devices' do
        allow(UserAlerts::AlertUserAboutNewDevice).to receive(:call)
        create(:device, user: user)

        event = subject.create_user_event(event_type, user)

        expect(event).to be_a(Event)
        expect(UserAlerts::AlertUserAboutNewDevice).to have_received(:call).
          with(user, user.events.first.device, instance_of(String))
      end
    end
  end

  describe '#create_user_event_with_disavowal' do
    it 'creates a device with a disavowal' do
      event = subject.create_user_event_with_disavowal(event_type, user)

      expect(event.disavowal_token).to_not be_nil
      expect(event.disavowal_token_fingerprint).to_not be_nil
    end
  end

  describe '#create_out_of_band_user_event' do
    let(:request) { nil }
    let(:event_type) { :password_invalidated }

    it 'creates an event without a device and without an IP address' do
      event = subject.create_out_of_band_user_event(event_type)

      expect(event.event_type).to eq(event_type.to_s)
      expect(event.ip).to be_blank
      expect(event.device).to be_blank
    end
  end
end
