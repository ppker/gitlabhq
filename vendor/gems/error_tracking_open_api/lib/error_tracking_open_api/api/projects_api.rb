=begin
#Error Trackig REST API

#This schema describes the API endpoints for the error tracking feature

The version of the OpenAPI document: 0.0.1

Generated by: https://openapi-generator.tech
OpenAPI Generator version: 6.0.0

=end

require 'cgi'

module ErrorTrackingOpenAPI
  class ProjectsApi
    attr_accessor :api_client

    def initialize(api_client = ApiClient.default)
      @api_client = api_client
    end
    # Deletes all project related data. Mostly for testing purposes and later for production to clean updeleted projects.
    # @param id [Integer] ID of the project
    # @param [Hash] opts the optional parameters
    # @return [nil]
    def delete_project(id, opts = {})
      delete_project_with_http_info(id, opts)
      nil
    end

    # Deletes all project related data. Mostly for testing purposes and later for production to clean updeleted projects.
    # @param id [Integer] ID of the project
    # @param [Hash] opts the optional parameters
    # @return [Array<(nil, Integer, Hash)>] nil, response status code and response headers
    def delete_project_with_http_info(id, opts = {})
      if @api_client.config.debugging
        @api_client.config.logger.debug 'Calling API: ProjectsApi.delete_project ...'
      end
      # verify the required parameter 'id' is set
      if @api_client.config.client_side_validation && id.nil?
        fail ArgumentError, "Missing the required parameter 'id' when calling ProjectsApi.delete_project"
      end
      # resource path
      local_var_path = '/projects/{id}'.sub('{' + 'id' + '}', CGI.escape(id.to_s))

      # query parameters
      query_params = opts[:query_params] || {}

      # header parameters
      header_params = opts[:header_params] || {}

      # form parameters
      form_params = opts[:form_params] || {}

      # http body (model)
      post_body = opts[:debug_body]

      # return_type
      return_type = opts[:debug_return_type]

      # auth_names
      auth_names = opts[:debug_auth_names] || []

      new_options = opts.merge(
        :operation => :"ProjectsApi.delete_project",
        :header_params => header_params,
        :query_params => query_params,
        :form_params => form_params,
        :body => post_body,
        :auth_names => auth_names,
        :return_type => return_type
      )

      data, status_code, headers = @api_client.call_api(:DELETE, local_var_path, new_options)
      if @api_client.config.debugging
        @api_client.config.logger.debug "API called: ProjectsApi#delete_project\nData: #{data.inspect}\nStatus code: #{status_code}\nHeaders: #{headers}"
      end
      return data, status_code, headers
    end
  end
end
