class VshPhp72 < Formula
  desc "General-purpose scripting language"
  homepage "https://www.php.net/"
  url "https://github.com/shivammathur/php-src-backports/archive/269a597ce7d22198bca3745157a45783d86da7ac.tar.gz"
  version "7.2.34"
  sha256 "01e8a6bf83a7b5e77ec6b02d5933e12a39911a4f34bfa572d99ac0020c9513b0"
  license "PHP-3.01"
  revision 3

  bottle do
    root_url "https://ghcr.io/v2/valet-sh/php"
    sha256 arm64_tahoe: "5b9869fa52b8c4f9bfc0ff097c571fbd98ce58b0366de91862f7fedefff0a736"
  end

  depends_on "bison" => :build
  depends_on "pkgconf" => :build
  depends_on "re2c" => :build
  depends_on "apr"
  depends_on "apr-util"
  depends_on "argon2"
  depends_on "aspell"
  depends_on "autoconf"
  depends_on "curl"
  depends_on "freetds"
  depends_on "freetype"
  depends_on "gd"
  depends_on "gettext"
  depends_on "glib"
  depends_on "gmp"
  depends_on "icu4c@77"
  depends_on "imagemagick"
  depends_on "jpeg"
  depends_on "krb5"
  depends_on "libpng"
  depends_on "libpq"
  depends_on "libsodium"
  depends_on "libx11"
  depends_on "libxpm"
  depends_on "libyaml"
  depends_on "libzip"
  depends_on "openldap"
  depends_on "openssl@3"
  depends_on "pcre"
  depends_on "sqlite"
  depends_on "tidy-html5"
  depends_on "unixodbc"
  depends_on "webp"

  uses_from_macos "bzip2"
  uses_from_macos "libedit"
  uses_from_macos "libxml2"
  uses_from_macos "libxslt"
  uses_from_macos "zlib"

  resource "xdebug_module" do
    url "https://github.com/xdebug/xdebug/archive/refs/tags/2.9.8.tar.gz"
    sha256 "28f8de8e6491f51ac9f551a221275360458a01c7690c42b23b9a0d2e6429eff4"
  end

  resource "imagick_module" do
    url "https://github.com/Imagick/imagick/archive/refs/tags/3.8.0.tar.gz"
    sha256 "a964e54a441392577f195d91da56e0b3cf30c32e6d60d0531a355b37bb1e1a59"
  end

  patch :DATA

  def install
    ENV.append "CFLAGS", "-std=gnu17"

    # Work around configure issues with Xcode 12
    # See https://bugs.php.net/bug.php?id=80171
    ENV.append "CFLAGS", "-Wno-implicit-function-declaration"

    # Work around for building with Xcode 15.3
    if DevelopmentTools.clang_build_version >= 1500
      ENV.append "CFLAGS", "-Wno-incompatible-function-pointer-types"
      ENV.append "LDFLAGS", "-lresolv"
      inreplace "main/reentrancy.c", "readdir_r(dirp, entry)", "readdir_r(dirp, entry, result)"
    end

    # Workaround for https://bugs.php.net/80310
    ENV.append "CFLAGS", "-DU_DEFINE_FALSE_AND_TRUE=1"
    ENV.append "CXXFLAGS", "-DU_DEFINE_FALSE_AND_TRUE=1"

    # Work around to support `icu4c` 75, which needs C++17.
    ENV.append "CXX", "-std=c++17"
    ENV.libcxx if ENV.compiler == :clang

    # buildconf required due to system library linking bug patch
    system "./buildconf", "--force"

    inreplace "sapi/fpm/php-fpm.conf.in", ";daemonize = yes", "daemonize = no"

    config_path = etc/name.to_s
    # Prevent system pear config from inhibiting pear install
    (config_path/"pear.conf").delete if (config_path/"pear.conf").exist?

    # Prevent homebrew from hardcoding path to sed shim in phpize script
    ENV["lt_cv_path_SED"] = "sed"

    # Each extension that is built on Mojave needs a direct reference to the
    # sdk path or it won't find the headers
    headers_path = "=#{MacOS.sdk_path_if_needed}/usr"

    ENV["EXTENSION_DIR"] = "#{prefix}/lib/#{name}/20170718"
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
      --enable-bcmath
      --enable-calendar
      --enable-dba
      --enable-dtrace
      --enable-exif
      --enable-ftp
      --enable-fpm
      --enable-intl
      --enable-mbregex
      --enable-mbstring
      --enable-mysqlnd
      --enable-opcache-file
      --enable-pcntl
      --enable-phpdbg
      --enable-phpdbg-webhelper
      --enable-shmop
      --enable-soap
      --enable-sockets
      --enable-sysvmsg
      --enable-sysvsem
      --enable-sysvshm
      --enable-wddx
      --enable-zip
      --with-bz2#{headers_path}
      --with-curl=#{formula_opt_prefix("curl")}
      --with-fpm-user=_www
      --with-fpm-group=_www
      --with-freetype-dir=#{formula_opt_prefix("freetype")}
      --with-gd=#{formula_opt_prefix("gd")}
      --with-gettext=#{formula_opt_prefix("gettext")}
      --with-gmp=#{formula_opt_prefix("gmp")}
      --with-iconv#{headers_path}
      --with-icu-dir=#{formula_opt_prefix("icu4c@77")}
      --with-jpeg-dir=#{formula_opt_prefix("jpeg")}
      --with-kerberos#{headers_path}
      --with-layout=GNU
      --with-ldap=#{formula_opt_prefix("openldap")}
      --with-ldap-sasl#{headers_path}
      --with-libxml-dir#{headers_path}
      --with-libedit#{headers_path}
      --with-libzip
      --with-mhash#{headers_path}
      --with-mysql-sock=/tmp/mysql.sock
      --with-mysqli=mysqlnd
      --with-ndbm#{headers_path}
      --with-openssl=#{formula_opt_prefix("openssl@3")}
      --with-password-argon2=#{formula_opt_prefix("argon2")}
      --with-pdo-dblib=#{formula_opt_prefix("freetds")}
      --with-pdo-mysql=mysqlnd
      --with-pdo-odbc=unixODBC,#{formula_opt_prefix("unixodbc")}
      --with-pdo-pgsql=#{formula_opt_prefix("libpq")}
      --with-pdo-sqlite=#{formula_opt_prefix("sqlite")}
      --with-pgsql=#{formula_opt_prefix("libpq")}
      --with-pic
      --with-png-dir=#{formula_opt_prefix("libpng")}
      --with-pspell=#{formula_opt_prefix("aspell")}
      --with-sodium=#{formula_opt_prefix("libsodium")}
      --with-sqlite3=#{formula_opt_prefix("sqlite")}
      --with-tidy=#{formula_opt_prefix("tidy-html5")}
      --with-unixODBC=#{formula_opt_prefix("unixodbc")}
      --with-webp-dir=#{formula_opt_prefix("webp")}
      --with-xpm-dir=#{formula_opt_prefix("libxpm")}
      --with-xmlrpc
      --with-xsl#{headers_path}
      --with-zlib#{headers_path}
    ]

    system "./configure", *args
    system "make"
    system "make", "install"

    resource("xdebug_module").stage do
      system "#{bin}/phpize#{bin_suffix}"
      system "./configure", "--with-php-config=#{bin}/php-config#{bin_suffix}"
      system "make", "clean"
      system "make", "all"
      system "make", "install"
    end

    resource("imagick_module").stage do
      args = %W[
        --with-imagick=#{formula_opt_prefix("imagemagick")}
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

    mv "#{bin}/phar.phar", "#{bin}/phar#{bin_suffix}.phar"
    rm("#{bin}/phar")
    ln_s "#{bin}/phar#{bin_suffix}.phar", "#{bin}/phar#{bin_suffix}"

    mv "#{man1}/phar.1", "#{man1}/phar#{bin_suffix}.1"
    mv "#{man1}/phar.phar.1", "#{man1}/phar#{bin_suffix}.phar.1"
  end

  post_install_steps do
    # Keep shared extensions in var so they survive upgrades: move the keg's
    # extension dir there and leave a symlink in its place. The symlink from an
    # earlier run is removed first so these steps stay idempotent.
    mkdir_p "{{var}}/{{name}}/20170718"
    remove "{{lib}}/{{name}}/20170718", symlink_target_contains: "/var/vsh-php72/20170718"
    if_path_exists "{{lib}}/{{name}}/20170718" do
      move_contents "{{lib}}/{{name}}/20170718", "{{var}}/{{name}}/20170718"
      remove "{{lib}}/{{name}}/20170718", recursive: true
    end
    symlink "{{var}}/{{name}}/20170718", "{{lib}}/{{name}}/20170718"

    # pear ships its registry without read access for group/other
    set_permissions "{{pkgshare}}/pear/.channels", "u=rwX,go=rX"
    set_permissions ["{{pkgshare}}/pear/.depdblock", "{{pkgshare}}/pear/.filemap"], "0644", recursive: false
    set_permissions ["{{pkgshare}}/pear/.depdb", "{{pkgshare}}/pear/.lock"], "0644", recursive: false

    run "{{bin}}/pear{{version.major_minor}}", args: ["config-set", "php_ini", "{{pkgetc}}/php.ini", "system"]
    run "{{bin}}/pear{{version.major_minor}}", args: ["update-channels"], network_access: true

    # Register shared extensions. Existing files are kept and only the
    # extension line is normalised.
    write_file "{{pkgetc}}/conf.d/ext-opcache.ini", <<~INI, overwrite: false
      [opcache]
      zend_extension=opcache.so
    INI
    inreplace "{{pkgetc}}/conf.d/ext-opcache.ini", /zend_extension=.*$/, "zend_extension=opcache.so"
  end

  def php_version
    version.to_s.split(".")[0..1].join(".")
  end

  def bin_suffix
    php_version.to_s
  end

  service do
    php_version = @formula.version.to_s.split(".")[0..1].join(".")
    bin_suffix = php_version

    run ["#{opt_sbin}/php-fpm#{bin_suffix}", "--nodaemonize"]
    keep_alive true
    working_dir var
    error_log_path var/"log/vsh-php72.log"
  end

  test do
    assert_match(/^Zend OPcache$/, shell_output("#{bin}/php#{bin_suffix} -i"),
      "Zend OPCache extension not loaded")
    # Test related to libxml2 and
    # https://github.com/Homebrew/homebrew-core/issues/28398
    assert_includes MachO::Tools.dylibs("#{bin}/php#{bin_suffix}"),
      "#{formula_opt_lib("libpq")}/libpq.5.dylib"
    system "#{sbin}/php-fpm#{bin_suffix}", "-t"
    system "#{bin}/phpdbg#{bin_suffix}", "-V"
    system "#{bin}/php-cgi#{bin_suffix}", "-m"
    # Prevent SNMP extension to be added
    refute_match(/^snmpx$/, shell_output("#{bin}/php#{bin_suffix} -m"),
      "SNMP extension doesn't work reliably with Homebrew on High Sierra")
  end
end

__END__
diff --git a/acinclude.m4 b/acinclude.m4
index 168c465f8d..6c087d152f 100644
--- a/acinclude.m4
+++ b/acinclude.m4
@@ -441,7 +441,11 @@ dnl
 dnl Adds a path to linkpath/runpath (LDFLAGS)
 dnl
 AC_DEFUN([PHP_ADD_LIBPATH],[
-  if test "$1" != "/usr/$PHP_LIBDIR" && test "$1" != "/usr/lib"; then
+  case "$1" in
+  "/usr/$PHP_LIBDIR"|"/usr/lib"[)] ;;
+  /Library/Developer/CommandLineTools/SDKs/*/usr/lib[)] ;;
+  /Applications/Xcode*.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/*/usr/lib[)] ;;
+  *[)]
     PHP_EXPAND_PATH($1, ai_p)
     ifelse([$2],,[
       _PHP_ADD_LIBPATH_GLOBAL([$ai_p])
@@ -452,8 +456,8 @@ AC_DEFUN([PHP_ADD_LIBPATH],[
       else
         _PHP_ADD_LIBPATH_GLOBAL([$ai_p])
       fi
-    ])
-  fi
+    ]) ;;
+  esac
 ])

 dnl
@@ -487,7 +491,11 @@ dnl add an include path.
 dnl if before is 1, add in the beginning of INCLUDES.
 dnl
 AC_DEFUN([PHP_ADD_INCLUDE],[
-  if test "$1" != "/usr/include"; then
+  case "$1" in
+  "/usr/include"[)] ;;
+  /Library/Developer/CommandLineTools/SDKs/*/usr/include[)] ;;
+  /Applications/Xcode*.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/*/usr/include[)] ;;
+  *[)]
     PHP_EXPAND_PATH($1, ai_p)
     PHP_RUN_ONCE(INCLUDEPATH, $ai_p, [
       if test "$2"; then
@@ -495,8 +503,8 @@ AC_DEFUN([PHP_ADD_INCLUDE],[
       else
         INCLUDES="$INCLUDES -I$ai_p"
       fi
-    ])
-  fi
+    ]) ;;
+  esac
 ])

 dnl internal, don't use
@@ -2411,7 +2419,8 @@ AC_DEFUN([PHP_SETUP_ICONV], [
     fi

     if test -f $ICONV_DIR/$PHP_LIBDIR/lib$iconv_lib_name.a ||
-       test -f $ICONV_DIR/$PHP_LIBDIR/lib$iconv_lib_name.$SHLIB_SUFFIX_NAME
+       test -f $ICONV_DIR/$PHP_LIBDIR/lib$iconv_lib_name.$SHLIB_SUFFIX_NAME ||
+       test -f $ICONV_DIR/$PHP_LIBDIR/lib$iconv_lib_name.tbd
     then
       PHP_CHECK_LIBRARY($iconv_lib_name, libiconv, [
         found_iconv=yes
