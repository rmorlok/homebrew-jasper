class Openfst < Formula
  homepage "http://www.openfst.org/"
  url "https://github.com/rmorlok/Phonetisaurus/archive/v0.1.tar.gz"
  sha256 "6593edb401d047d942365437be012d974990609b6eb89814d1c6422a4161771e"

  needs :cxx11

  def install
    ENV.cxx11
    system 'cd src'
    system "./configure", "--prefix=#{prefix}"
    system "make", "install"
  end
end