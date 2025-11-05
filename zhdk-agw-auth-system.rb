require 'active_support/all'
require 'cgi'
require 'jwt'
require 'optparse'
require 'ostruct'
require 'pathname'
require 'rest-client'
require 'sinatra/base'
require 'yaml'
require 'logger'

$logger = Logger.new(STDOUT)
$logger.level = Logger::Severity::INFO
$logger.formatter = proc do |severity, datetime, progname, msg|
  "#{datetime.strftime('%Y-%m-%d %H:%M:%S')} - #{severity}: #{msg}\n\n"
end

# require 'pry'
# require 'rerun'

################################################################################
### options and config #########################################################
################################################################################

options = OpenStruct.new
# options.config_file = Pathname.new("dev/config.yml")
OptionParser.new do |opts|
  opts.banner = "Usage: zhdk-agw-auth-system.rb [options]"

  opts.on("-c", "--config-file [PATH]", String, "Configuration file") do |cf|
    options.config_file = Pathname.new cf
  end
end.parse!

$config = {
  my_port: 3333
}.with_indifferent_access.deep_merge(
  YAML.load_file(options.config_file).with_indifferent_access
).tap do |c|
  c[:my_private_key] = OpenSSL::PKey.read(c[:my_private_key])
  c[:my_public_key] = OpenSSL::PKey.read(c[:my_public_key])
  c[:madek_public_key] = OpenSSL::PKey.read(c[:madek_public_key])
end

$logger.info($config)

################################################################################
### the web app ################################################################
################################################################################

class AuthenticatorApp <  Sinatra::Base

  set :environment, :production

  set :logging, true

  set :logger, $logger

  # set :host_authorization, { permitted_hosts: [] }


  get '/zhdk-agw/status' do
    'OK'
  end

  get '/zhdk-agw/info' do
    return "Switch to development mode for detailed info" if ENV['RACK_ENV'] != 'development'
    content_type :html
      <<-HTML.strip_heredoc
        <html>
        <head>
          <title>Environment Variables</title>
          <style>
          table { border-collapse: collapse; width: 100%; }
          th, td { border: 1px solid black; padding: 8px; text-align: left; }
          th { background-color: #f2f2f2; }
          </style>
        </head>
        <body>
          <h1>Environment Variables</h1>
          <table>
          <tr>
            <th>Key</th>
            <th>Value</th>
          </tr>
          #{ENV.map { |k, v| "<tr><td>#{CGI.escapeHTML(k)}</td><td>#{CGI.escapeHTML(v)}</td></tr>" }.join("\n            ")}
          </table>
          <h2>Request Info</h2>
          <pre>#{CGI.escapeHTML(request.env.map { |k, v| "#{k}: #{v}" }.join("\n"))}</pre>
        </body>
        </html>
      HTML
  end


  ### error handling and error messages ########################################

  def expired_message sign_in_request_token
    sign_in_request = JWT.decode sign_in_request_token,
      $config[:madek_public_key], false, { algorithm: 'ES256' }

    $logger.warn "Expired token: #{sign_in_request}"
    $logger.warn "Request env: #{request.env}"

    <<-HTML.strip_heredoc
        <html>
          <head></head>
          <body>
            <h1>Error: Token Expired </h1>
            <p> Please <a href="#{sign_in_request[0]['server_base_url']}"> try again. </a></p>
          </body>
        </html>
    HTML
  end

  def generic_error_message e
    $logger.error "#{e} #{e.backtrace}"
    <<-HTML.strip_heredoc
        <html>
          <head></head>
          <body>
            <h1> Unspecified Error in madek-AGW Authentication Service </h1>
            <p> Please try again. </p>
            <p> Contact your madek administrator if this problem occurs again. </p>
          </body>
        </html>
    HTML
  end


  ### sign-in ##################################################################


  get '/zhdk-agw/sign-in' do

    begin

      sign_in_request_token = params[:token]
      sign_in_request = JWT.decode sign_in_request_token,
        $config[:madek_public_key], true, { algorithm: 'ES256' }
      agw_username = sign_in_request.first["email-or-login"].presence

      $logger.info({sign_in_request: sign_in_request})

      token = JWT.encode({
        sign_in_request_token: sign_in_request_token
        # and more if we ever need it
      }, $config[:my_private_key], 'ES256')

      url = $config[:agw_base_url] + $config[:agw_app_id] \
        + (agw_username ? "&vusername=#{CGI::escape(agw_username)}" : "") \
        + '&url_postlogin=' \
        + CGI::escape("#{$config[:my_external_base_url]}/zhdk-agw/callback?" \
                      "token=#{token}" \
                      "&agw_session_id=%s")

      redirect url

    rescue JWT::ExpiredSignature => e
      expired_message sign_in_request_token
    rescue StandardError => e
      generic_error_message e
    end

  end



  ### callback ##################################################################

  get '/zhdk-agw/callback' do

    begin

      token_data = JWT.decode(params[:token],
                              $config[:my_public_key], true, { algorithm: 'ES256'}) \
        .first.with_indifferent_access

      sign_in_request_token = token_data[:sign_in_request_token]

      sign_in_request = JWT.decode sign_in_request_token,
        $config[:madek_public_key], true, { algorithm: 'ES256' }

      sign_in_request = sign_in_request.first

      $logger.debug sign_in_request: sign_in_request

      agw_session_id = params[:agw_session_id]

      url = $config[:agw_base_url] + $config[:agw_app_id] \
        + "/response" \
        + "&agw_sess_id=#{agw_session_id}" \
        + "&app_ident=#{$config[:agw_app_secret]}"

      resp = RestClient.get(url)

      $logger.debug({BODY: resp.body})

      person = Hash.from_xml(resp.body).with_indifferent_access[:authresponse][:person]

      $logger.debug({PERSON: person})

      groups = person[:memberof][:group].map{|group|
        $logger.debug({group: group}) && group
      }.map{|g| g.gsub('zhdk/', '')
      }.map{|g| {institutional_name: g}
      }.each{|g| $logger.debug(g)}

      groups << {id: 'efbfca9f-4191-5d27-8c94-618be5a125f5', type: 'AuthenticationGroup'}

      token_payload = {
        sign_in_request_token: sign_in_request_token,
        'email-or-login': (person[:email].presence || person[:local_username].presence),
        'account': {
          'email': person[:email],
          'first_name': person[:firstname],
          'id': person[:id],
          'last_name': person[:lastname],
          'login': person[:local_username],
          'groups': groups,},
        success: true }

      $logger.debug({TOKEN_PAYLOAD: token_payload})

      token = JWT.encode(token_payload, $config[:my_private_key], 'ES256')

      url = sign_in_request['sign-in-url'] + "?token=#{token}"

      redirect url

    rescue JWT::ExpiredSignature => e
      expired_message sign_in_request_token
    rescue StandardError => e
      generic_error_message e
    end

  end

end



################################################################################
### start up ###################################################################
################################################################################

AuthenticatorApp.port = $config[:my_port]
AuthenticatorApp.bind = 'localhost'

AuthenticatorApp.run!