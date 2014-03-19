require 'formula'

class Physfshg < Formula
  homepage 'http://icculus.org/physfs/'
  url 'https://dl.dropboxusercontent.com/sh/p6a8y2mzg4b7vvx/3ukeB0ah3L/physfs-hg.tar.gz'
  sha1 '9cb115d6fb3f8a67a182bc4bc2f4411b5b0fd8bb'

  depends_on 'cmake' => :build

  def install
    mkdir 'macbuild' do
      system "cmake", "..",
                      "-DPHYSFS_BUILD_WX_TEST=FALSE",
                      "-DPHYSFS_BUILD_TEST=TRUE",
                      *std_cmake_args
      system "make"
      system "make install"
    end
  end
end
