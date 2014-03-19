require 'formula'

class Libpng < Formula
  homepage 'http://www.libpng.org/pub/png/libpng.html'
  url 'http://downloads.sourceforge.net/sourceforge/libpng/libpng-1.6.10.tar.xz'
  sha1 'adb44c93795446eaa4170bf9305b6f771eb368bc'

  option :universal

  def patches
    [ "http://downloads.sourceforge.net/sourceforge/libpng-apng/libpng-1.6.10-apng.patch.gz"]
  end

  def install
    ENV.universal_binary if build.universal?
    system "./configure", "--disable-dependency-tracking",
                          "--prefix=#{prefix}"
    system "make install"
  end
end
