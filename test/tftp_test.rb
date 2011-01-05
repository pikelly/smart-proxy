require 'test_helper'

class TftpTest < Test::Unit::TestCase

  def setup
    @tftp = Proxy::TFTP
  end

  def test_should_have_a_logger
    assert_respond_to @tftp, :logger
  end

  def test_should_create_tftp_link
    puts @tftp.send :path
  end

end
