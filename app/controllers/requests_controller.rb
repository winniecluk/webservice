class RequestsController < ApplicationController
  before_action :set_request, only: [:show, :edit, :update, :destroy]

  require "rubygems"
  require "json"
  require "base64"
  require "net/http"
  require "time"
  require "digest"
  require "openssl"
  require "base64"

  # GET /requests
  # GET /requests.json
  def index
    @requests = Request.all

    respond_to do |format|
        format.json { render :json => @requests}
    end
  end

  def receive
      @access_id = ""
      @secret_key = ""
      @app_identifier = ""
      @recipient_id = ""
      @boundary = "741e90d31eff"
      uri = URI.parse "https://kipuapi.kipuworks.com/api/patients"

      resp = request.body.read
      respHeaders = request.headers
      puts 'these are the headers'
      puts respHeaders

      # puts(resp.class)
      jsonResp = JSON.parse(resp)
      # puts jsonResp["document"]["attachment_attributes"][0]["attachment"]
      base64str = jsonResp["document"]["attachment_attributes"][0]["attachment"]
      puts jsonResp["document"]["data"]["first_name"]

      post_body = ""
        post_body << "--#{@boundary}\r\n"
        # boundaries are prefixed with --
        post_body << "Content-Disposition: form-data; name=\"document[data][first_name]\"\r\n"
        post_body << "\r\n"
        post_body << jsonResp["document"]["data"]["first_name"]
        post_body << "\r\n"

        post_body << "--#{@boundary}\r\n"
        # boundary's prefixed with --
        post_body << "Content-Disposition: form-data; name=\"document[data][last_name]\"\r\n"
        post_body << "\r\n"
        post_body << jsonResp["document"]["data"]["last_name"]
        post_body << "\r\n"

        post_body << "--#{@boundary}\r\n"
        # boundary's prefixed with --
        post_body << "Content-Disposition: form-data; name=\"document[data][dob]\"\r\n"
        post_body << "\r\n"
        post_body << jsonResp["document"]["data"]["dob"]
        post_body << "\r\n"

        attr_arr = ["insurances_attributes", "patient_contacts_attributes"]

        attr_arr.each do |attr|
            if nil != jsonResp["document"]["data"][attr] && jsonResp["document"]["data"][attr].length > 0
                i_a = jsonResp["document"]["data"][attr]
                puts "this is i_a"
                puts i_a.class
                i_a.each do |at|
                    counter = 0
                    at.each do |key, value|
                        post_body << "--#{@boundary}\r\n"
                        post_body << "Content-Disposition: form-data; name=\"document[data][#{attr}][#{counter}][#{key}]\"\r\n"
                        puts "Content-Disposition: form-data; name=\"document[data][#{attr}][#{counter}][#{key}]\"\r\n"
                        post_body << "\r\n"
                        post_body << value
                        post_body << "\r\n"
                    end
                    counter +=1
                end
            end
        end





        # post_body << "--#{@boundary}\r\n"
        # post_body << "Content-Disposition: form-data; name=\"document[data][insurances_attributes][0][insurance_company]\"\r\n"
        # post_body << "\r\n"
        # post_body << "Sample Insurance Company"
        # post_body << "\r\n"
        #
        # post_body << "--#{@boundary}\r\n"
        # post_body << "Content-Disposition: form-data; name=\"document[data][insurances_attributes][0][subscriber_first_name]\"\r\n"
        # post_body << "\r\n"
        # post_body << "John"
        # post_body << "\r\n"

        # post_body << "--#{@boundary}\r\n"
        # post_body << "Content-Disposition: form-data; name=\"document[data][patient_contacts_attributes][0][full_name]\"\r\n"
        # post_body << "\r\n"
        # post_body << "Jane Emergency Smith"
        # post_body << "\r\n"
        #
        # post_body << "--#{@boundary}\r\n"
        # post_body << "Content-Disposition: form-data; name=\"document[data][patient_contacts_attributes][0][phone]\"\r\n"
        # post_body << "\r\n"
        # post_body << "(555) 555-5555"
        # post_body << "\r\n"

        post_body << "--#{@boundary}\r\n"
        post_body << "Content-Disposition: form-data; name=\"document[recipient_id]\"\r\n"
        post_body << "\r\n"
        post_body << @recipient_id # sending to ourselves
        post_body << "\r\n"

        post_body << "--#{@boundary}\r\n"
        post_body << "Content-Disposition: form-data; name=\"document[app_id]\"\r\n"
        post_body << "\r\n"
        post_body << @access_id # sending to ourselves
        post_body << "\r\n"

        # post_body << "--#{@boundary}\r\n"
        # post_body << "Content-Disposition: form-data; name=\"app_id\"\r\n"
        # post_body << "\r\n"
        # post_body << @access_id
        # post_body << "\r\n"

        post_body << "--#{@boundary}\r\n"
        post_body << "Content-Disposition: form-data; name=\"document[sending_app_name]\"\r\n"
        post_body << "\r\n"
        post_body << @app_identifier
        post_body << "\r\n"

        if nil != jsonResp["document"]["attachment_attributes"] && jsonResp["document"]["attachment_attributes"].length > 0
            attach_attr = jsonResp["document"]["attachment_attributes"]
            ctr = 0
            attach_attr.each do |attach|
                post_body << "--#{@boundary}\r\n"
                post_body << "Content-Disposition: form-data; name=\"document[attachments_attributes][0][attachment]\"; filename=\"#{attach["filename"]}\"\r\n"
                post_body << "Content-type: application/pdf \r\n"
                post_body << "\r\n"
                post_body << Base64.decode64(attach["attachment"])
                post_body << "\r\n--#{@boundary}--\r\n" # the last boundary is prefixed and suffixed with --
                ctr += 1
            end
        end
        # post_body << "--#{@boundary}\r\n"
        # post_body << "Content-Disposition: form-data; name=\"document[attachments_attributes][0][attachment]\"; filename=\"document.pdf\"\r\n"
        # post_body << "Content-type: application/pdf \r\n"
        # post_body << "\r\n"
        # post_body << File.read(file)
        # post_body << "\r\n--#{@boundary}--\r\n" # the last boundary is prefixed and suffixed with --
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        request = Net::HTTP::Post.new(uri.request_uri)
        request.body = post_body
        request["Content-Type"] = "multipart/form-data, boundary=#{@boundary}"
        request["Accept"] = "application/vnd.kipusystems+json; version=1"
        request["Date"] = Time.now.httpdate
        request["Content-MD5"] = Digest::MD5.base64digest request.body

        puts "md5: #{request["content-md5"]}"

        canonical_string = [ request["Content-Type"], request["Content-MD5"], uri.request_uri, request["Date"]
        ].join ","

        puts "\r\n"
        puts "this is the canonical string:" + canonical_string

        digest = OpenSSL::Digest.new "sha1"
        signed = OpenSSL::HMAC.digest digest, @secret_key, canonical_string
        encoded_sig = Base64.strict_encode64 signed

        request["Authorization"] = "APIAuth #{@access_id}:#{encoded_sig}"
        response = http.request request

        puts "this is the request"
        puts post_body
        puts "\r\n"
        puts "auth header: #{request["Authorization"]}"
        puts "this is the response from Kipu"
        puts response.body

      # attachStr = Base64.decode64(base64str)
      # puts(request.body.read)
  end

  # GET /requests/1
  # GET /requests/1.json
  def show
  end

  # GET /requests/new
  def new
    @request = Request.new
  end

  # GET /requests/1/edit
  def edit
  end

  # POST /requests
  # POST /requests.json
  def create
    @request = Request.new(request_params)

    respond_to do |format|
      if @request.save
        format.html { redirect_to @request, notice: 'Request was successfully created.' }
        format.json { render :show, status: :created, location: @request }
      else
        format.html { render :new }
        format.json { render json: @request.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /requests/1
  # PATCH/PUT /requests/1.json
  def update
    respond_to do |format|
      if @request.update(request_params)
        format.html { redirect_to @request, notice: 'Request was successfully updated.' }
        format.json { render :show, status: :ok, location: @request }
      else
        format.html { render :edit }
        format.json { render json: @request.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /requests/1
  # DELETE /requests/1.json
  def destroy
    @request.destroy
    respond_to do |format|
      format.html { redirect_to requests_url, notice: 'Request was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_request
      @request = Request.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def request_params
      params.require(:request).permit(:num)
    end
end
