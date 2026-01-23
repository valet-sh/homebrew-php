class VshPhp84 < Formula
  desc "General-purpose scripting language"
  homepage "https://www.php.net/"
  # Should only be updated if the new version is announced on the homepage, https://www.php.net/
  url "https://www.php.net/distributions/php-8.4.17.tar.xz"
  mirror "https://fossies.org/linux/www/php-8.4.17.tar.xz"
  sha256 "28b234e347286158cae921d61283eb1169d89bc9d2e5f5976567260ff38b0bfa"
  license "PHP-3.01"
  # revision 1

  bottle do
    root_url "https://ghcr.io/v2/valet-sh/php"
    sha256 arm64_tahoe: "f16b4ec0a3bc02fda21e57c89e54c6c3669b759a33f13869327c0a03f1b511c4"
  end

  depends_on "pkgconf" => :build
  depends_on "apr"
  depends_on "apr-util"
  depends_on "argon2"
  depends_on "autoconf"
  depends_on "capstone"
  depends_on "curl"
  depends_on "freetds"
  depends_on "gd"
  depends_on "gmp"
  depends_on "icu4c@78"
  depends_on "imagemagick"
  depends_on "krb5"
  depends_on "libpq"
  depends_on "libsodium"
  depends_on "libzip"
  depends_on "net-snmp"
  depends_on "oniguruma"
  depends_on "openldap"
  depends_on "openssl@3"
  depends_on "pcre2"
  depends_on "sqlite"
  depends_on "tidy-html5"
  depends_on "unixodbc"
  depends_on "webp"

  uses_from_macos "xz" => :build
  uses_from_macos "bzip2"
  uses_from_macos "libedit"
  uses_from_macos "libffi"
  uses_from_macos "libxml2"
  uses_from_macos "libxslt"
  uses_from_macos "zlib"

  on_macos do
    depends_on "gcc" => :build # must never be a runtime dependency
    depends_on "gettext"
  end

  # https://github.com/Homebrew/homebrew-core/issues/235820
  # https://clang.llvm.org/docs/UsersManual.html#gcc-extensions-not-implemented-yet
  fails_with :clang do
    cause "Performs worse due to lack of general global register variables"
  end

  resource "xdebug_module" do
    url "https://github.com/xdebug/xdebug/archive/refs/tags/3.3.1.tar.gz"
    sha256 "76d0467154d7f2714a07f88c7c17658e24dd58fb919a9aa08ab4bc23dccce76d"
  end

  resource "imagick_module" do
    url "https://github.com/Imagick/imagick/archive/refs/tags/3.8.0.tar.gz"
    sha256 "a964e54a441392577f195d91da56e0b3cf30c32e6d60d0531a355b37bb1e1a59"
  end

  def install
    # GCC -Os performs worse than -O1 and significantly worse than -O2/-O3.
    # We lack a DSL to enable -O2 so just use -O3 which is similar.
    ENV.O3 if OS.mac?

    # buildconf required due to system library linking bug patch
    system "./buildconf", "--force"

    config_path = etc/name.to_s
    # Prevent system pear config from inhibiting pear install
    (config_path/"pear.conf").delete if (config_path/"pear.conf").exist?

    ENV["lt_cv_path_SED"] = "sed"

    # Identify build provider in php -v output and phpinfo()
    ENV["PHP_BUILD_PROVIDER"] = "valet.sh"

    # system pkg-config missing
    ENV["KERBEROS_CFLAGS"] = " "
    if OS.mac?
      ENV["SASL_CFLAGS"] = "-I#{MacOS.sdk_path_if_needed}/usr/include/sasl"
      ENV["SASL_LIBS"] = "-lsasl2"
    else
      ENV["SQLITE_CFLAGS"] = "-I#{Formula["sqlite"].opt_include}"
      ENV["SQLITE_LIBS"] = "-lsqlite3"
      ENV["BZIP_DIR"] = Formula["bzip2"].opt_prefix
    end

    # Each extension that is built on Mojave needs a direct reference to the
    # sdk path or it won't find the headers
    headers_path = "=#{MacOS.sdk_path_if_needed}/usr" if OS.mac?

    # `_www` only exists on macOS.
    fpm_user = OS.mac? ? "_www" : "www-data"
    fpm_group = OS.mac? ? "_www" : "www-data"

    ENV["EXTENSION_DIR"] = "#{prefix}/lib/#{name}/20240924"
    ENV["PHP_PEAR_PHP_BIN"] = "#{bin}/php#{bin_suffix}"

    args = %W[
      --prefix=#{prefix}
      --localstatedir=#{var}
      --sysconfdir=#{config_path}
      --libdir=#{prefix}/lib/#{name}
      --includedir=#{prefix}/include/#{name}
      --datadir=#{prefix}/share/#{name}
      --with-config-file-path=#{config_path}
      --with-config-file-scan-dir=#{config_path}/conf.d
      --program-suffix=#{bin_suffix}
      --with-pear=#{pkgshare}/pear
      --disable-intl
      --enable-bcmath
      --enable-calendar
      --enable-dba
      --enable-exif
      --enable-ftp
      --enable-fpm
      --enable-gd
      --enable-mbregex
      --enable-mbstring
      --enable-mysqlnd
      --enable-opcache
      --enable-pcntl
      --enable-phpdbg
      --enable-phpdbg-readline
      --enable-shmop
      --enable-soap
      --enable-sockets
      --enable-sysvmsg
      --enable-sysvsem
      --enable-sysvshm
      --with-bz2#{headers_path}
      --with-curl
      --with-external-gd
      --with-external-pcre
      --with-ffi
      --with-fpm-user=#{fpm_user}
      --with-fpm-group=#{fpm_group}
      --with-gettext=#{Formula["gettext"].opt_prefix}
      --with-gmp=#{Formula["gmp"].opt_prefix}
      --with-iconv#{headers_path}
      --with-layout=GNU
      --with-ldap=#{Formula["openldap"].opt_prefix}
      --with-libxml
      --with-libedit
      --with-mhash#{headers_path}
      --with-mysql-sock=/tmp/mysql.sock
      --with-mysqli=mysqlnd
      --with-ndbm#{headers_path}
      --with-openssl
      --with-password-argon2=#{Formula["argon2"].opt_prefix}
      --with-pdo-dblib=#{Formula["freetds"].opt_prefix}
      --with-pdo-mysql=mysqlnd
      --with-pdo-odbc=unixODBC,#{Formula["unixodbc"].opt_prefix}
      --with-pdo-pgsql=#{Formula["libpq"].opt_prefix}
      --with-pdo-sqlite
      --with-pgsql=#{Formula["libpq"].opt_prefix}
      --with-pic
      --with-snmp=#{Formula["net-snmp"].opt_prefix}
      --with-sodium
      --with-sqlite3
      --with-tidy=#{Formula["tidy-html5"].opt_prefix}
      --with-unixODBC
      --with-xsl
      --with-zip
      --with-zlib
    ]

    if OS.mac?
      args << "--enable-dtrace"
      args << "--with-ldap-sasl"
      args << "--with-os-sdkpath=#{MacOS.sdk_path_if_needed}"
    else
      args << "--disable-dtrace"
      args << "--without-ldap-sasl"
      args << "--without-ndbm"
      args << "--without-gdbm"
    end

    system "./configure", *args
    system "make"
    system "make", "install"

    resource("xdebug_module").stage do
      system "#{bin}/phpize#{bin_suffix}"

      # rubocop:disable all
      ENV["CC"] = "/usr/bin/clang"
      ENV["CXX"] = "/usr/bin/clang++"
      # rubocop:enable all

      system "./configure", "--with-php-config=#{bin}/php-config#{bin_suffix}"
      system "make", "clean"
      system "make", "all"
      system "make", "install"
    end

    resource("imagick_module").stage do
      args = %W[
        --with-imagick=#{Formula["imagemagick"].opt_prefix}
      ]
      system "#{bin}/phpize#{bin_suffix}"
      system "./configure", "--with-php-config=#{bin}/php-config#{bin_suffix}", *args
      system "make", "clean"
      system "make", "all"
      system "make", "install"
    end

    # Use OpenSSL cert bundle
    openssl = Formula["openssl@3"]
    %w[development production].each do |mode|
      inreplace "php.ini-#{mode}", /; ?openssl\.cafile=/,
        "openssl.cafile = \"#{openssl.pkgetc}/cert.pem\""
      inreplace "php.ini-#{mode}", /; ?openssl\.capath=/,
        "openssl.capath = \"#{openssl.pkgetc}/certs\""
    end

    inreplace "sapi/fpm/www.conf" do |s|
      s.gsub!(/listen =.*/, "listen = /tmp/#{name}.sock")
    end

    config_files = {
      "php.ini-development"   => "php.ini",
      "sapi/fpm/php-fpm.conf" => "php-fpm.conf",
      "sapi/fpm/www.conf"     => "php-fpm.d/www.conf",
    }
    config_files.each_value do |dst|
      dst_default = config_path/"#{dst}.default"
      rm dst_default if dst_default.exist?
    end
    config_path.install config_files

    unless (var/"log/php-fpm#{bin_suffix}.log").exist?
      (var/"log").mkpath
      touch var/"log/php-fpm#{bin_suffix}.log"
    end

    mv "#{bin}/pecl", "#{bin}/pecl#{bin_suffix}"
    mv "#{bin}/pear", "#{bin}/pear#{bin_suffix}"
    mv "#{bin}/peardev", "#{bin}/peardev#{bin_suffix}"

    cd "ext/intl" do
      system "#{bin}/phpize#{bin_suffix}"
      if OS.mac?
        # rubocop:disable all
        ENV["CC"] = "/usr/bin/clang"
        ENV["CXX"] = "/usr/bin/clang++"
        # rubocop:enable all
      end
      system "./configure", "--with-php-config=#{bin}/php-config#{bin_suffix}"
      system "make"
      system "make", "install", "EXTENSION_DIR=#{lib}/php/#{orig_ext_dir}"
    end
  end

  def post_install
    # check if php extension dir (e.g. 20180731) exists and is not a symlink
    # only relevant when running "brew postinstall" manually
    if (lib/"#{name}/#{php_ext_dir}").exist? && !(lib/"#{name}/#{php_ext_dir}").symlink?
        (var/"#{name}/#{php_ext_dir}").mkpath unless (var/"#{name}/#{php_ext_dir}").exist?

        Dir.glob(lib/"#{name}/#{php_ext_dir}/*") do |php_module|
            php_module_name = File.basename(php_module)
            mv php_module.to_s, var/"#{name}/#{php_ext_dir}/#{php_module_name}"
        end

        rm_r lib/"#{name}/#{php_ext_dir}"
        ln_s var/"#{name}/#{php_ext_dir}", lib/"#{name}/#{php_ext_dir}"
    end

    pear_prefix = pkgshare/"pear"

    puts pear_prefix

    pear_files = %W[
      #{pear_prefix}/.depdblock
      #{pear_prefix}/.filemap
      #{pear_prefix}/.depdb
      #{pear_prefix}/.lock
    ]

    %W[
      #{pear_prefix}/.channels
      #{pear_prefix}/.channels/.alias
    ].each do |f|
      chmod 0755, f
      pear_files.concat(Dir["#{f}/*"])
    end

    chmod 0644, pear_files

    {
      "php_ini" => etc/"#{name}/php.ini",
    }.each do |key, value|
      value.mkpath if /(?<!bin|man)_dir$/.match?(key)
      system bin/"pear#{bin_suffix}", "config-set", key, value, "system"
    end

    system bin/"pear#{bin_suffix}", "update-channels"

    %w[
      opcache
    ].each do |e|
      ext_config_path = etc/"#{name}/conf.d/ext-#{e}.ini"
      extension_type = (e == "opcache") ? "zend_extension" : "extension"
      if ext_config_path.exist?
        inreplace ext_config_path,
          /#{extension_type}=.*$/, "#{extension_type}=#{e}.so"
      else
        ext_config_path.write <<~EOS
          [#{e}]
          #{extension_type}="#{e}.so"
        EOS
      end
    end
  end

  def php_version
    version.to_s.split(".")[0..1].join(".")
  end

  def bin_suffix
    php_version.to_s
  end

  def php_ext_dir
    extension_dir = Utils.safe_popen_read("#{bin}/php-config#{bin_suffix}", "--extension-dir").chomp
    File.basename(extension_dir)
  end

  service do
    php_version = @formula.version.to_s.split(".")[0..1].join(".")
    bin_suffix = php_version

    run ["#{opt_sbin}/php-fpm#{bin_suffix}", "--nodaemonize"]
    keep_alive true
    working_dir var
    error_log_path var/"log/vsh-php84.log"
  end

  test do
    assert_match(/^Zend OPcache$/, shell_output("#{bin}/php#{bin_suffix} -i"),
      "Zend OPCache extension not loaded")
    # Test related to libxml2 and
    # https://github.com/Homebrew/homebrew-core/issues/28398
    assert_includes MachO::Tools.dylibs("#{bin}/php#{bin_suffix}"),
      "#{Formula["libpq"].opt_lib}/libpq.5.dylib"
    system "#{sbin}/php-fpm#{bin_suffix}", "-t"
    system "#{bin}/phpdbg#{bin_suffix}", "-V"
    system "#{bin}/php-cgi#{bin_suffix}", "-m"
    # Prevent SNMP extension to be added
    refute_match(/^snmpx$/, shell_output("#{bin}/php#{bin_suffix} -m"),
      "SNMP extension doesn't work reliably with Homebrew on High Sierra")
  end
end
