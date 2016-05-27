class Phonetisaurus < Formula
  homepage "http://www.openfst.org/"
  url "https://github.com/rmorlok/Phonetisaurus/archive/v0.1.tar.gz"
  sha256 "49975ed9eff8f8f325d6f599c73ef335ab8fd44aedc653e4b1ba06cdd0c646bd"

  needs :cxx11

  def install
    ENV.cxx11
    system 'cd src'
    system "./configure", "--prefix=#{prefix}"
    system "make", "install"
  end
end