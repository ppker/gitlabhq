# frozen_string_literal: true

module Groups
  module Settings
    class RepositoryController < Groups::ApplicationController
      layout 'group_settings'
      skip_cross_project_access_check :show
      before_action :authorize_create_deploy_token!, only: :create_deploy_token
      before_action :authorize_access!, only: :show
      before_action :define_deploy_token_variables, if: -> { can?(current_user, :create_deploy_token, @group) }

      before_action do
        push_frontend_ability(ability: :admin_group, resource: @group, user: current_user)
      end

      feature_category :continuous_delivery
      urgency :low

      def create_deploy_token
        result = Groups::DeployTokens::CreateService.new(@group, current_user, deploy_token_params).execute

        if result[:status] == :success
          @created_deploy_token = result[:deploy_token]
          respond_to do |format|
            format.json do
              # IMPORTANT: It's a security risk to expose the token value more than just once here!
              json = API::Entities::DeployTokenWithToken.represent(@created_deploy_token).as_json
              render json: json, status: result[:http_status]
            end
            format.html do
              flash.now[:notice] = s_('DeployTokens|Your new group deploy token has been created.')
              render :show
            end
          end
        else
          @new_deploy_token = result[:deploy_token]
          respond_to do |format|
            format.json { render json: { message: result[:message] }, status: result[:http_status] }
            format.html do
              flash.now[:alert] = result[:message]
              render :show
            end
          end
        end
      end

      private

      def authorize_access!
        authorize_admin_group!
      end

      def define_deploy_token_variables
        @deploy_tokens = @group.deploy_tokens.active

        @new_deploy_token = DeployToken.new
      end

      def deploy_token_params
        params.require(:deploy_token).permit(
          :name,
          :expires_at,
          :read_repository,
          :read_registry,
          :write_registry,
          :read_virtual_registry,
          :write_virtual_registry,
          :read_package_registry,
          :write_package_registry,
          :username
        )
      end
    end
  end
end

Groups::Settings::RepositoryController.prepend_mod
