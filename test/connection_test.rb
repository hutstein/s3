require 'test_helper'

class ConnectionTest < Test::Unit::TestCase
  def setup
    @connection = S3::Connection.new(
      :access_key_id =>  "12345678901234567890",
      :secret_access_key =>  "qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDF"
    )
    @http_request = Net::HTTP.new("")
    @response_ok = Net::HTTPOK.new("1.1", "200", "OK")
    @response_not_found = Net::HTTPNotFound.new("1.1", "404", "Not Found")
    @connection.stubs(:http).returns(@http_request)

    @http_request.stubs(:start).returns(@response_ok)
  end

  test "handle response not modify response when ok" do
    assert_nothing_raised do
      response = @connection.request(
        :get,
        :host => "s3.amazonaws.com",
        :path => "/"
      )
      assert_equal @response_ok, response
    end
  end

  test "handle response throws exception when error" do
    response_body = <<-EOFakeBody
    <?xml version=\"1.0\" encoding=\"UTF-8\"?>
    <Error>
      <Code>NoSuchBucket</Code>
      <Message>The specified bucket does not exist</Message>
    </Error>
    EOFakeBody

    @http_request.stubs(:start).returns(@response_not_found)
    @response_not_found.stubs(:body).returns(response_body)

    assert_raise S3::Error::NoSuchBucket do
      response = @connection.request(
        :get,
        :host => "data.example.com.s3.amazonaws.com",
        :path => "/"
      )
    end
  end

  test "handle response throws standard exception when error" do
    @http_request.stubs(:start).returns(@response_not_found)
    @response_not_found.stubs(:body)
    assert_raise S3::Error::ResponseError do
      response = @connection.request(
        :get,
        :host => "data.example.com.s3.amazonaws.com",
        :path => "/"
      )
    end

    @response_not_found.stubs(:body).returns("")
    assert_raise S3::Error::ResponseError do
      response = @connection.request(
        :get,
        :host => "data.example.com.s3.amazonaws.com",
        :path => "/"
      )
    end
  end

  test "parse params empty" do
    expected = ""
    actual = S3::Connection.parse_params({})
    assert_equal expected, actual
  end

  test "parse params only interesting params" do
    expected = ""
    actual = S3::Connection.parse_params(:param1 => "1", :maxkeys => "2")
    assert_equal expected, actual
  end

  test "parse params remove underscore" do
    expected = "max-keys=100"
    actual = S3::Connection.parse_params(:max_keys => 100)
    assert_equal expected, actual
  end

  test "parse params with and without values" do
    expected = "max-keys=100&prefix"
    actual = S3::Connection.parse_params(:max_keys => 100, :prefix => nil)
    assert_equal expected, actual
  end

  test "headers empty" do
    expected = {}
    actual = S3::Connection.parse_headers({})
    assert_equal expected, actual
  end

  test "parse only interesting headers" do
    expected = {}
    actual = S3::Connection.parse_headers(
      :accept => "text/*, text/html, text/html;level=1, */*",
      :accept_charset => "iso-8859-2, unicode-1-1;q=0.8"
    )
    assert_equal expected, actual
  end

  test "parse headers remove underscore" do
    expected = {
      "content-type" => nil,
      "x-amz-acl" => nil,
      "if-modified-since" => nil,
      "if-unmodified-since" => nil,
      "if-match" => nil,
      "if-none-match" => nil,
      "content-disposition" => nil,
      "content-encoding" => nil
    }
    actual = S3::Connection.parse_headers(
      :content_type => nil,
      :x_amz_acl => nil,
      :if_modified_since => nil,
      :if_unmodified_since => nil,
      :if_match => nil,
      :if_none_match => nil,
      :content_disposition => nil,
      :content_encoding => nil
    )
    assert_equal expected, actual
  end

  test "parse headers with values" do
    expected = {
      "content-type" => "text/html",
      "x-amz-acl" => "public-read",
      "if-modified-since" => "today",
      "if-unmodified-since" => "tomorrow",
      "if-match" => "1234",
      "if-none-match" => "1243",
      "content-disposition" => "inline",
      "content-encoding" => "gzip"
    }
    actual = S3::Connection.parse_headers(
      :content_type => "text/html",
      :x_amz_acl => "public-read",
      :if_modified_since => "today",
      :if_unmodified_since => "tomorrow",
      :if_match => "1234",
      :if_none_match => "1243",
      :content_disposition => "inline",
      :content_encoding => "gzip"
    )
    assert_equal expected, actual
  end

  test "parse headers with range" do
    expected = {
      "range" => "bytes=0-100"
    }
    actual = S3::Connection.parse_headers(
      :range => 0..100
    )
    assert_equal expected, actual
  end
end
