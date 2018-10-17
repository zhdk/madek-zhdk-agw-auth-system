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
$logger.level = Logger::WARN

# require 'pry'
# require 'rerun'

################################################################################
### options and config #########################################################
################################################################################
 
options = OpenStruct.new
options.config_file = Pathname.new("dev/config.yml")
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
  c[:leihs_public_key] = OpenSSL::PKey.read(c[:leihs_public_key])
end

 
################################################################################
### the web app ################################################################
################################################################################

class AuthenticatorApp <  Sinatra::Base

  set :environment, :production

  get '/zhdk-agw/status' do
    'OK'
  end


  ### error handling and error messages ########################################

  def expired_message sign_in_request_token
    sign_in_request = JWT.decode sign_in_request_token, 
      $config[:leihs_public_key], false, { algorithm: 'ES256' }

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
            <h1> Unspecified Error in leihs-AGW Authentication Service </h1>
            <p> Please try again. </p>
            <p> Contact your leihs administrator if this problem occurs again. </p>
          </body>
        </html>
    HTML
  end


  ### sign-in ##################################################################
  

  get '/zhdk-agw/sign-in' do

    begin 

      sign_in_request_token = params[:token]
      sign_in_request = JWT.decode sign_in_request_token, 
        $config[:leihs_public_key], true, { algorithm: 'ES256' }
      login = sign_in_request.first["login"].presence

      token = JWT.encode({
        sign_in_request_token: sign_in_request_token
        # and more if we ever need it
      }, $config[:my_private_key], 'ES256')

      url = $config[:agw_base_url] + $config[:agw_app_id] \
        + '&delogin=1' \
        + (login ? "&vusername=#{CGI::escape(login)}" : "") \
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
        $config[:leihs_public_key], true, { algorithm: 'ES256' }

      agw_session_id = params[:agw_session_id]

      url = $config[:agw_base_url] + $config[:agw_app_id] \
        + "/response" \
        + "&agw_sess_id=#{agw_session_id}" \
        + "&app_ident=#{$config[:agw_app_secret]}"

      resp = RestClient.get(url)

      person = Hash.from_xml(resp.body).with_indifferent_access[:authresponse][:person]

      token = JWT.encode({
        sign_in_request_token: sign_in_request_token,
        org_id: person[:id],
        success: true}, $config[:my_private_key], 'ES256')

      url = sign_in_request.first["server_base_url"] \
        + sign_in_request.first['path'] + "?token=#{token}"

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

AuthenticatorApp.run!
