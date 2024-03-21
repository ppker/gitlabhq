# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ResourceAccessTokens::CreateService, feature_category: :system_access do
  subject { described_class.new(user, resource, params).execute }

  let_it_be(:organization) { create(:organization) }
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :private, organization: organization) }
  let_it_be(:group) { create(:group, :private, organization: organization) }
  let_it_be(:params) { {} }
  let_it_be(:max_pat_access_token_lifetime) do
    PersonalAccessToken::MAX_PERSONAL_ACCESS_TOKEN_LIFETIME_IN_DAYS.days.from_now.to_date.freeze
  end

  before do
    stub_config_setting(host: 'example.com')
  end

  describe '#execute' do
    shared_examples 'token creation fails' do
      let_it_be(:resource) { create(:project, organization: organization) }

      it 'does not add the project bot as a member' do
        expect { subject }.not_to change { resource.members.count }
      end

      it 'immediately destroys the bot user if one was created', :sidekiq_inline do
        expect { subject }.not_to change { User.bots.count }
      end
    end

    shared_examples 'correct error message' do
      it 'returns correct error message' do
        expect(subject.error?).to be true
        expect(subject.errors).to include(error_message)
      end
    end

    shared_examples 'allows creation of bot with valid params' do
      it { expect { subject }.to change { User.count }.by(1) }

      it 'creates resource bot user' do
        response = subject

        access_token = response.payload[:access_token]

        expect(access_token.user.reload.user_type).to eq("project_bot")
        expect(access_token.user.created_by_id).to eq(user.id)
        expect(access_token.user.namespace.organization.id).to eq(resource.organization.id)
      end

      context 'email confirmation status' do
        shared_examples_for 'creates a user that has their email confirmed' do
          it 'creates a user that has their email confirmed' do
            response = subject
            access_token = response.payload[:access_token]

            expect(access_token.user.reload.confirmed?).to eq(true)
          end
        end

        context 'when created by an admin' do
          let(:user) { create(:admin) }

          context 'when admin mode is enabled', :enable_admin_mode do
            it_behaves_like 'creates a user that has their email confirmed'
          end

          context 'when admin mode is disabled' do
            it 'returns error' do
              response = subject

              expect(response.error?).to be true
            end
          end
        end

        context 'when created by a non-admin' do
          it_behaves_like 'creates a user that has their email confirmed'
        end
      end

      context 'bot name' do
        context 'when no name is passed' do
          it 'uses default name' do
            response = subject
            access_token = response.payload[:access_token]

            expect(access_token.user.name).to eq("#{resource.name.to_s.humanize} bot")
          end
        end

        context 'when user provides name' do
          let_it_be(:params) { { name: 'Random bot' } }

          it 'overrides the default name value' do
            response = subject
            access_token = response.payload[:access_token]

            expect(access_token.user.name).to eq(params[:name])
          end
        end
      end

      context 'bot username and email' do
        include_examples 'username and email pair is generated by Gitlab::Utils::UsernameAndEmailGenerator' do
          subject do
            response = described_class.new(user, resource, params).execute
            response.payload[:access_token].user
          end

          let(:username_prefix) do
            "#{resource.class.name.downcase}_#{resource.id}_bot"
          end

          let(:email_domain) do
            "noreply.#{Gitlab.config.gitlab.host}"
          end
        end
      end

      context 'access level' do
        context 'when user does not specify an access level' do
          it 'adds the bot user as a maintainer in the resource' do
            response = subject
            access_token = response.payload[:access_token]
            bot_user = access_token.user

            expect(resource.members.maintainers.map(&:user_id)).to include(bot_user.id)
          end
        end

        shared_examples 'bot with access level' do
          it 'adds the bot user with the specified access level in the resource' do
            response = subject
            access_token = response.payload[:access_token]
            bot_user = access_token.user

            expect(resource.members.developers.map(&:user_id)).to include(bot_user.id)
          end
        end

        context 'when user specifies an access level' do
          let_it_be(:params) { { access_level: Gitlab::Access::DEVELOPER } }

          it_behaves_like 'bot with access level'
        end

        context 'with DEVELOPER access_level, in string format' do
          let_it_be(:params) { { access_level: Gitlab::Access::DEVELOPER.to_s } }

          it_behaves_like 'bot with access level'
        end

        context 'when user is external' do
          before do
            user.update!(external: true)
          end

          it 'creates resource bot user with external status' do
            expect(subject.payload[:access_token].user.external).to eq true
          end
        end
      end

      context 'personal access token' do
        it { expect { subject }.to change { PersonalAccessToken.count }.by(1) }

        context 'when user does not provide scope' do
          it 'has default scopes' do
            response = subject
            access_token = response.payload[:access_token]

            expect(access_token.scopes).to eq(Gitlab::Auth.resource_bot_scopes)
          end
        end

        context 'when user provides scope explicitly' do
          let_it_be(:params) { { scopes: Gitlab::Auth::REPOSITORY_SCOPES } }

          it 'overrides the default scope value' do
            response = subject
            access_token = response.payload[:access_token]

            expect(access_token.scopes).to eq(Gitlab::Auth::REPOSITORY_SCOPES)
          end
        end

        context 'expires_at' do
          context 'when no expiration value is passed' do
            it 'defaults to PersonalAccessToken::MAX_PERSONAL_ACCESS_TOKEN_LIFETIME_IN_DAYS' do
              freeze_time do
                response = subject
                access_token = response.payload[:access_token]

                expect(access_token.expires_at).to eq(
                  max_pat_access_token_lifetime.to_date
                )
              end
            end

            it 'project bot membership expires when PAT expires' do
              response = subject
              access_token = response.payload[:access_token]
              project_bot = access_token.user

              expect(resource.members.find_by(user_id: project_bot.id).expires_at).to eq(
                max_pat_access_token_lifetime.to_date
              )
            end
          end

          context 'when user provides expiration value' do
            let_it_be(:params) { { expires_at: Date.today + 1.month } }

            it 'overrides the default expiration value' do
              response = subject
              access_token = response.payload[:access_token]

              expect(access_token.expires_at).to eq(params[:expires_at])
            end

            context 'expiry of the project bot member' do
              it 'sets the project bot to expire on the same day as the token' do
                response = subject
                access_token = response.payload[:access_token]
                project_bot = access_token.user

                expect(resource.members.find_by(user_id: project_bot.id).expires_at).to eq(access_token.expires_at)
              end
            end
          end

          context 'when invalid scope is passed' do
            let(:error_message) { 'Scopes can only contain available scopes' }
            let_it_be(:params) { { scopes: [:invalid_scope] } }

            it_behaves_like 'token creation fails'
            it_behaves_like 'correct error message'
          end
        end

        context "when access provisioning fails" do
          let_it_be(:bot_user) { create(:user, :project_bot) }

          let(:unpersisted_member) { build(:project_member, source: resource, user: bot_user) }
          let(:error_message) { 'Could not provision maintainer access to the access token. ERROR: error message' }

          before do
            allow_next_instance_of(ResourceAccessTokens::CreateService) do |service|
              allow(service).to receive(:create_user).and_return(bot_user)
              allow(service).to receive(:create_membership).and_return(unpersisted_member)
            end

            allow(unpersisted_member).to receive_message_chain(:errors, :full_messages, :to_sentence)
              .and_return('error message')
          end

          context 'with MAINTAINER access_level, in integer format' do
            let_it_be(:params) { { access_level: Gitlab::Access::MAINTAINER } }

            it_behaves_like 'token creation fails'
            it_behaves_like 'correct error message'
          end

          context 'with MAINTAINER access_level, in string format' do
            let_it_be(:params) { { access_level: Gitlab::Access::MAINTAINER.to_s } }

            it_behaves_like 'token creation fails'
            it_behaves_like 'correct error message'
          end
        end
      end

      it 'logs the event' do
        allow(Gitlab::AppLogger).to receive(:info)

        response = subject

        expect(Gitlab::AppLogger).to have_received(:info).with(/PROJECT ACCESS TOKEN CREATION: created_by: #{user.username}, project_id: #{resource.id}, token_user: #{response.payload[:access_token].user.name}, token_id: \d+/)
      end
    end

    shared_examples 'when user does not have permission to create a resource bot' do
      let(:error_message) { "User does not have permission to create #{resource_type} access token" }

      it_behaves_like 'token creation fails'
      it_behaves_like 'correct error message'
    end

    context 'when resource is a project' do
      let_it_be(:resource_type) { 'project' }
      let_it_be(:resource) { project }

      it_behaves_like 'when user does not have permission to create a resource bot'

      context 'user with valid permission' do
        before_all do
          resource.add_maintainer(user)
        end

        it_behaves_like 'allows creation of bot with valid params'

        context 'when user specifies an access level of OWNER for the bot' do
          let_it_be(:params) { { access_level: Gitlab::Access::OWNER } }

          context 'when the executor is a MAINTAINER' do
            let(:error_message) { 'Could not provision owner access to project access token' }

            context 'with OWNER access_level, in integer format' do
              it_behaves_like 'token creation fails'
              it_behaves_like 'correct error message'
            end

            context 'with OWNER access_level, in string format' do
              let(:error_message) { 'Could not provision owner access to project access token' }
              let_it_be(:params) { { access_level: Gitlab::Access::OWNER.to_s } }

              it_behaves_like 'token creation fails'
              it_behaves_like 'correct error message'
            end
          end

          context 'when the executor is an OWNER' do
            let_it_be(:user) { project.first_owner }

            it 'adds the bot user with the specified access level in the resource' do
              response = subject

              access_token = response.payload[:access_token]
              bot_user = access_token.user

              expect(resource.members.owners.map(&:user_id)).to include(bot_user.id)
            end
          end
        end
      end
    end

    context 'when resource is a group' do
      let_it_be(:resource_type) { 'group' }
      let_it_be(:resource) { group }

      it_behaves_like 'when user does not have permission to create a resource bot'

      context 'user with valid permission' do
        before_all do
          resource.add_owner(user)
        end

        it_behaves_like 'allows creation of bot with valid params'

        context 'when user specifies an access level of OWNER for the bot' do
          let_it_be(:params) { { access_level: Gitlab::Access::OWNER } }

          it 'adds the bot user with the specified access level in the resource' do
            response = subject
            access_token = response.payload[:access_token]
            bot_user = access_token.user

            expect(resource.members.owners.map(&:user_id)).to include(bot_user.id)
          end
        end
      end
    end

    context 'when resource organization is not set', :enable_admin_mode do
      let_it_be(:resource) { create(:project, :private, organization: nil) }
      let_it_be(:default_organization) { Organizations::Organization.default_organization }
      let(:user) { create(:admin) }

      it 'uses database default' do
        response = subject

        access_token = response.payload[:access_token]
        expect(access_token.user.namespace.organization).to eq(
          default_organization
        )
      end
    end
  end
end
