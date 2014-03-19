require 'formula'

class Mongodb < Formula
  homepage 'http://www.mongodb.org/'
  url 'http://downloads.mongodb.org/src/mongodb-src-r2.4.9.tar.gz'
  sha1 '3aa495cf32769a09ee9532827391892d96337d6b'

  bottle do
    revision 2
    sha1 "5447af6e8f6a2870306e03d318351f1d8efecb1f" => :mavericks
    sha1 "8b40016996e9dd42bbef3657d3a3c9357bd5d5ea" => :mountain_lion
    sha1 "e9686685cf1fdbd65109ea8e9979169f0ce728b6" => :lion
  end

  stable do
    # When 2.6 is released this conditional can be removed.
    if MacOS.version < :mavericks
      option "with-boost", "Compile using installed boost, not the version shipped with mongodb"
      depends_on "boost" => :optional
    end
  end

  devel do
    url 'http://downloads.mongodb.org/src/mongodb-src-r2.5.5.tar.gz'
    sha1 '4827f3da107174a3cbb1f5b969c7f597ca09b4f8'

    option "with-boost", "Compile using installed boost, not the version shipped with mongodb"
    depends_on "boost" => :optional
  end

  head do
    url 'https://github.com/mongodb/mongo.git'

    option "with-boost", "Compile using installed boost, not the version shipped with mongodb"
    depends_on "boost" => :optional
  end

  def patches
    if build.stable?
      [
        # Fix Clang v8 build failure from build warnings and -Werror
        'https://github.com/mongodb/mongo/commit/be4bc7.patch'
      ]
    end
  end

  depends_on 'scons' => :build
  depends_on 'openssl' => :optional

  def install
    args = ["--prefix=#{prefix}", "-j#{ENV.make_jobs}"]

    cxx = ENV.cxx
    if ENV.compiler == :clang && MacOS.version >= :mavericks
      if build.stable?
        # When 2.6 is released this cxx hack can be removed
        # ENV.append "CXXFLAGS", "-stdlib=libstdc++" does not work with scons
        # so use this hack of appending the flag to the --cxx parameter of the sconscript.
        # mongodb 2.4 can't build with libc++, but defaults to it on Mavericks
        cxx += " -stdlib=libstdc++"
      else
        # build devel and HEAD version on Mavericks with libc++
        # Use --osx-version-min=10.9 such that the compiler defaults to libc++.
        # Upstream issue discussing the default flags:
        # https://jira.mongodb.org/browse/SERVER-12682
        args << "--osx-version-min=10.9"
      end
    end

    args << '--64' if MacOS.prefer_64_bit?
    args << "--cc=#{ENV.cc}"
    args << "--cxx=#{cxx}"

    # --full installs development headers and client library, not just binaries
    args << "--full"
    args << "--use-system-boost" if build.with? "boost"

    if build.with? 'openssl'
      args << '--ssl'
      args << "--extrapath=#{Formula["openssl"].opt_prefix}"
    end

    scons 'install', *args

    (buildpath+"mongod.conf").write mongodb_conf
    etc.install "mongod.conf"

    (var+'mongodb').mkpath
    (var+'log/mongodb').mkpath
  end

  def mongodb_conf; <<-EOS.undent
    # Store data in #{var}/mongodb instead of the default /data/db
    dbpath = #{var}/mongodb

    # Append logs to #{var}/log/mongodb/mongo.log
    logpath = #{var}/log/mongodb/mongo.log
    logappend = true

    # Only accept local connections
    bind_ip = 127.0.0.1
    EOS
  end

  plist_options :manual => "mongod --config #{HOMEBREW_PREFIX}/etc/mongod.conf"

  def plist; <<-EOS.undent
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>Label</key>
      <string>#{plist_name}</string>
      <key>ProgramArguments</key>
      <array>
        <string>#{opt_bin}/mongod</string>
        <string>--config</string>
        <string>#{etc}/mongod.conf</string>
      </array>
      <key>RunAtLoad</key>
      <true/>
      <key>KeepAlive</key>
      <false/>
      <key>WorkingDirectory</key>
      <string>#{HOMEBREW_PREFIX}</string>
      <key>StandardErrorPath</key>
      <string>#{var}/log/mongodb/output.log</string>
      <key>StandardOutPath</key>
      <string>#{var}/log/mongodb/output.log</string>
      <key>HardResourceLimits</key>
      <dict>
        <key>NumberOfFiles</key>
        <integer>1024</integer>
      </dict>
      <key>SoftResourceLimits</key>
      <dict>
        <key>NumberOfFiles</key>
        <integer>1024</integer>
      </dict>
    </dict>
    </plist>
    EOS
  end

  test do
    system "#{bin}/mongod", '--sysinfo'
  end
end
