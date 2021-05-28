require 'rails_helper'

describe Idv::CancellationsController do
  describe 'before_actions' do
    it 'includes before_actions from IdvSession' do
      expect(subject).to have_actions(:before, :redirect_if_sp_context_needed)
    end
  end

  describe '#new' do
    it 'tracks the event in analytics when referer is nil' do
      stub_sign_in
      stub_analytics
      properties = { request_came_from: 'no referer', step: nil }

      expect(@analytics).to receive(:track_event).with(Analytics::IDV_CANCELLATION, properties)

      get :new
    end

    it 'tracks the event in analytics when referer is present' do
      stub_sign_in
      stub_analytics
      request.env['HTTP_REFERER'] = 'http://example.com/'
      properties = { request_came_from: 'users/sessions#new', step: nil }

      expect(@analytics).to receive(:track_event).with(Analytics::IDV_CANCELLATION, properties)

      get :new
    end

    it 'tracks the event in analytics when step param is present' do
      stub_sign_in
      stub_analytics
      properties = { request_came_from: 'no referer', step: 'first' }

      expect(@analytics).to receive(:track_event).with(Analytics::IDV_CANCELLATION, properties)

      get :new, params: { step: 'first' }
    end

    context 'when no session' do
      it 'redirects to root' do
        get :new

        expect(response).to redirect_to(root_url)
      end
    end

    context 'when hybrid session' do
      before do
        session[:doc_capture_user_id] = create(:user).id
      end

      it 'renders template' do
        get :new

        expect(response).to render_template(:new)
      end
    end

    context 'when regular session' do
      before do
        stub_sign_in
      end

      it 'renders template' do
        get :new

        expect(response).to render_template(:new)
      end
    end
  end

  describe '#destroy' do
    it 'tracks an analytics event' do
      stub_sign_in
      stub_analytics

      expect(@analytics).to receive(:track_event).with(
        Analytics::IDV_CANCELLATION_CONFIRMED,
        step: 'first',
      )

      delete :destroy, params: { step: 'first' }
    end

    context 'when no session' do
      it 'redirects to root' do
        delete :destroy

        expect(response).to redirect_to(root_url)
      end
    end

    context 'when hybrid session' do
      let(:user) { create(:user) }
      let(:document_capture_session) { user.document_capture_sessions.create! }
      before do
        session[:doc_capture_user_id] = user.id
        session[:document_capture_session_uuid] = document_capture_session.uuid
      end

      it 'cancels document capture' do
        delete :destroy

        expect(document_capture_session.reload.cancelled_at).to be_present
      end

      it 'renders template' do
        delete :destroy

        expect(response).to render_template(:destroy)
      end
    end

    context 'when regular session' do
      before do
        stub_sign_in
      end

      it 'destroys session' do
        expect(subject.user_session).to receive(:delete).with('idv/doc_auth')

        delete :destroy
      end

      it 'renders template' do
        delete :destroy

        expect(response).to render_template(:destroy)
      end
    end
  end
end
