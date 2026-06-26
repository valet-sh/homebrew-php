class VshPhp56 < Formula
  desc "General-purpose scripting language"
  homepage "https://secure.php.net/"
  url "https://github.com/shivammathur/php-src-backports/archive/6cfe49e294414185452ec89bad39b1bd42cc72c9.tar.gz"
  version "5.6.40"
  sha256 "c7aea2d4742a6daadfa333dce1e6707bd648b2ed54e36238674db026e27d43cf"
  license "PHP-3.01"
  revision 2

  bottle do
    root_url "https://ghcr.io/v2/valet-sh/php"
    sha256 arm64_tahoe: "671e3ee4654337e1245a4db50e9941282c3b84b3958654c1f044d621451e8abe"
  end

  depends_on "bison" => :build
  depends_on "pkgconf" => :build
  depends_on "re2c" => :build
  depends_on "apr"
  depends_on "apr-util"
  depends_on "aspell"
  depends_on "autoconf"
  depends_on "curl"
  depends_on "freetds"
  depends_on "freetype"
  depends_on "gd"
  depends_on "gettext"
  depends_on "gmp"
  depends_on "icu4c@78"
  depends_on "imagemagick"
  depends_on "jpeg"
  depends_on "krb5"
  depends_on "libpng"
  depends_on "libpq"
  depends_on "libtool"
  depends_on "libx11"
  depends_on "libxpm"
  depends_on "libzip"
  depends_on "openldap"
  depends_on "openssl@3"
  depends_on "pcre"
  depends_on "sqlite"
  depends_on "tidy-html5"
  depends_on "unixodbc"
  depends_on "vsh-geoip"
  depends_on "vsh-mcrypt"

  uses_from_macos "bzip2"
  uses_from_macos "libedit"
  uses_from_macos "libxml2"
  uses_from_macos "libxslt"
  uses_from_macos "zlib"

  on_macos do
    # PHP build system incorrectly links system libraries
    patch :DATA
  end

  # rubocop:disable all
  resource "xdebug_module" do
    url "https://github.com/xdebug/xdebug/archive/XDEBUG_2_5_5.tar.gz"
    sha256 "77faf3bc49ca85d9b67ae2aa9d9cc4b017544f2566e918bf90fe23d68e044244"
  end
  # rubocop:enable all

  resource "imagick_module" do
    url "https://github.com/Imagick/imagick/archive/refs/tags/3.8.0.tar.gz"
    sha256 "a964e54a441392577f195d91da56e0b3cf30c32e6d60d0531a355b37bb1e1a59"
  end

  resource "geoip_module" do
    url "https://github.com/valet-sh/php-geoip/releases/download/1.1.1/geoip-1.1.1.tar.gz"
    sha256 "33280eb74a4ea4cbc1a3867f8fd0f633f9de2d19043d4825bf57863d0c5e20e7"
  end

  def install
    ENV.append "CFLAGS", "-std=gnu17"

    # Work around configure issues with Xcode 12
    # See https://bugs.php.net/bug.php?id=80171
    ENV.append "CFLAGS", "-Wno-implicit-function-declaration"

    # Work around for building with Xcode 15.3
    if DevelopmentTools.clang_build_version >= 1500
      ENV.append "CFLAGS", "-std=gnu11"
      ENV.append "CXXFLAGS", "-std=gnu++17"

      ENV.append "CFLAGS", "-Wno-incompatible-function-pointer-types"
      ENV.append "CFLAGS", "-Wno-implicit-int"
    end

    # Workaround for https://bugs.php.net/80310
    ENV.append "CFLAGS", "-DU_DEFINE_FALSE_AND_TRUE=1"
    ENV.append "CXXFLAGS", "-DU_DEFINE_FALSE_AND_TRUE=1"

    # icu4c 61.1 compatibility
    ENV.append "CPPFLAGS", "-DU_USING_ICU_NAMESPACE=1"

    # Work around to support `icu4c` 75, which needs C++17.
    ENV.append "CXX", "-std=c++17"
    ENV.libcxx if ENV.compiler == :clang

    # buildconf required due to system library linking bug patch
    system "./buildconf", "--force"

    inreplace "sapi/fpm/php-fpm.conf.in", ";daemonize = yes", "daemonize = no"

    # API compatibility with tidy-html5 v5.0.0 - https://github.com/htacg/tidy-html5/issues/224
    inreplace "ext/tidy/tidy.c", "buffio.h", "tidybuffio.h"

    config_path = etc/name.to_s
    # Prevent system pear config from inhibiting pear install
    (config_path/"pear.conf").delete if (config_path/"pear.conf").exist?

    # Prevent homebrew from hardcoding path to sed shim in phpize script
    ENV["lt_cv_path_SED"] = "sed"

    # Each extension that is built on Mojave needs a direct reference to the sdk path or it won't find the headers
    headers_path = "=#{MacOS.sdk_for_formula(self).path}/usr"
    gettext_path = "=#{formula_opt_prefix("gettext")}"

    # `_www` only exists on macOS.
    fpm_user = OS.mac? ? "_www" : "www-data"
    fpm_group = OS.mac? ? "_www" : "www-data"

    ENV["EXTENSION_DIR"] = "#{prefix}/lib/#{name}/20131226"
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
      --enable-exif
      --enable-ftp
      --enable-fpm
      --enable-intl
      --enable-mbregex
      --enable-mbstring
      --enable-mysqlnd
      --enable-opcache
      --enable-pcntl
      --enable-phpdbg
      --enable-shmop
      --enable-soap
      --enable-sockets
      --enable-sysvmsg
      --enable-sysvsem
      --enable-sysvshm
      --enable-wddx
      --enable-zip
      --with-curl=#{formula_opt_prefix("curl")}
      --with-fpm-user=#{fpm_user}
      --with-fpm-group=#{fpm_group}
      --with-freetype-dir=#{formula_opt_prefix("freetype")}
      --with-gd=#{formula_opt_prefix("gd")}
      --with-gettext#{gettext_path}
      --with-gmp=#{formula_opt_prefix("gmp")}
      --with-iconv#{headers_path}
      --with-icu-dir=#{formula_opt_prefix("icu4c@78")}
      --with-jpeg-dir=#{formula_opt_prefix("jpeg")}
      --with-kerberos#{headers_path}
      --with-layout=GNU
      --with-ldap=#{formula_opt_prefix("openldap")}
      --with-ldap-sasl#{headers_path}
      --with-libzip
      --with-mcrypt=#{formula_opt_prefix("vsh-mcrypt")}
      --with-mhash#{headers_path}
      --with-mysql-sock=/tmp/mysql.sock
      --with-mysqli=mysqlnd
      --with-mysql=mysqlnd
      --with-openssl=#{formula_opt_prefix("openssl@3")}
      --with-pdo-dblib=#{formula_opt_prefix("freetds")}
      --with-pdo-mysql=mysqlnd
      --with-pdo-odbc=unixODBC,#{formula_opt_prefix("unixodbc")}
      --with-pdo-pgsql=#{formula_opt_prefix("libpq")}
      --with-pdo-sqlite=#{formula_opt_prefix("sqlite")}
      --with-pgsql=#{formula_opt_prefix("libpq")}
      --with-pic
      --with-png-dir=#{formula_opt_prefix("libpng")}
      --with-pspell=#{formula_opt_prefix("aspell")}
      --with-sqlite3=#{formula_opt_prefix("sqlite")}
      --with-tidy=#{formula_opt_prefix("tidy-html5")}
      --with-unixODBC=#{formula_opt_prefix("unixodbc")}
      --with-xmlrpc
      --with-xpm-dir=#{formula_opt_prefix("libxpm")}
      --with-bz2#{headers_path}
      --with-libedit#{headers_path}
      --with-libxml-dir#{headers_path}
      --with-ndbm#{headers_path}
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

    resource("geoip_module").stage do
      args = %W[
        --with-geoip=#{formula_opt_prefix("vsh-geoip")}
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

    inreplace "sapi/fpm/php-fpm.conf" do |s|
      s.gsub!(/listen =.*/, "listen = /tmp/#{name}.sock")
    end

    config_files = {
      "php.ini-development"   => "php.ini",
      "sapi/fpm/php-fpm.conf" => "php-fpm.conf",
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
    error_log_path var/"log/vsh-php56.log"
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
diff --git a/Zend/zend_compile.h b/Zend/zend_compile.h
index a0955e34fe..09b4984f90 100644
--- a/Zend/zend_compile.h
+++ b/Zend/zend_compile.h
@@ -414,9 +414,6 @@ struct _zend_execute_data {

 #define EX(element) execute_data.element

-#define EX_TMP_VAR(ex, n)	   ((temp_variable*)(((char*)(ex)) + ((int)(n))))
-#define EX_TMP_VAR_NUM(ex, n)  (EX_TMP_VAR(ex, 0) - (1 + (n)))
-
 #define EX_CV_NUM(ex, n)       (((zval***)(((char*)(ex))+ZEND_MM_ALIGNED_SIZE(sizeof(zend_execute_data))))+(n))


diff --git a/Zend/zend_execute.h b/Zend/zend_execute.h
index a7af67bc13..ae71a5c73f 100644
--- a/Zend/zend_execute.h
+++ b/Zend/zend_execute.h
@@ -71,6 +71,15 @@ ZEND_API int zend_eval_stringl_ex(char *str, int str_len, zval *retval_ptr, char
 ZEND_API char * zend_verify_arg_class_kind(const zend_arg_info *cur_arg_info, ulong fetch_type, const char **class_name, zend_class_entry **pce TSRMLS_DC);
 ZEND_API int zend_verify_arg_error(int error_type, const zend_function *zf, zend_uint arg_num, const char *need_msg, const char *need_kind, const char *given_msg, const char *given_kind TSRMLS_DC);

+static zend_always_inline temp_variable *EX_TMP_VAR(void *ex, int n)
+{
+	return (temp_variable *)((zend_uintptr_t)ex + n);
+}
+static inline temp_variable *EX_TMP_VAR_NUM(void *ex, int n)
+{
+	return (temp_variable *)((zend_uintptr_t)ex - (1 + n) * sizeof(temp_variable));
+}
+
 static zend_always_inline void i_zval_ptr_dtor(zval *zval_ptr ZEND_FILE_LINE_DC TSRMLS_DC)
 {
	if (!Z_DELREF_P(zval_ptr)) {
