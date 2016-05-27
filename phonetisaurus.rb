class Phonetisaurus < Formula
  homepage "https://github.com/AdolfVonKleist/Phonetisaurus"
  url "https://github.com/rmorlok/Phonetisaurus/archive/v0.1.tar.gz"
  sha256 "49975ed9eff8f8f325d6f599c73ef335ab8fd44aedc653e4b1ba06cdd0c646bd"

  depends_on "rmorlok/jasper/openfst"

  needs :cxx11

  def install
    ENV.cxx11

    Dir.chdir "src" do
      system "./configure", "--prefix=#{prefix}", "--exec-prefix=#{prefix}"
      system "make", "install"
    end
  end
end