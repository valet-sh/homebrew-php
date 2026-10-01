class VshPhp80 < Formula
  desc "General-purpose scripting language"
  homepage "https://www.php.net/"
  url "https://github.com/shivammathur/php-src-backports/archive/31b3988504b443365bfa4881257782b00919a751.tar.gz"
  version "8.0.30"
  sha256 "6f0f2a0dbb37e904859d7cc9ac12425434333a5c4b811b674621525430bd5472"
  license "PHP-3.01"
  revision 3

  bottle do
    root_url "https://ghcr.io/v2/valet-sh/php"
    rebuild 1
    sha256 arm64_tahoe: "0c14ed5c81e9c4b1cafd2e3986a5c4236594ee1d26e8e3477850c7f13d76dc38"
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
  depends_on "gcc"
  depends_on "gd"
  depends_on "gettext"
  depends_on "glib"
  depends_on "gmp"
  depends_on "icu4c@78"
  depends_on "imagemagick"
  depends_on "jpeg"
  depends_on "krb5"
  depends_on "libffi"
  depends_on "libpng"
  depends_on "libpq"
  depends_on "libsodium"
  depends_on "libyaml"
  depends_on "libzip"
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

  fails_with :clang do
    cause "Performs worse due to lack of general global register variables"
  end

  resource "xdebug_module" do
    url "https://github.com/xdebug/xdebug/archive/refs/tags/3.4.7.tar.gz"
    sha256 "6959726ee2bb99efd660796736801b198ec0847b6360230a8143ad5e2d2063c2"
  end

  resource "imagick_module" do
    url "https://github.com/Imagick/imagick/archive/refs/tags/3.8.0.tar.gz"
    sha256 "a964e54a441392577f195d91da56e0b3cf30c32e6d60d0531a355b37bb1e1a59"
  end

  patch :DATA

  def install
    ENV.append "CFLAGS", "-std=gnu17"

    # Work around for building with Xcode 15.3
    if DevelopmentTools.clang_build_version >= 1500
      ENV.append "CFLAGS", "-Wno-incompatible-function-pointer-types"
      ENV.append "LDFLAGS", "-lresolv"
    end

    ENV.append "CFLAGS", "-Wno-incompatible-pointer-types" if OS.mac? && ENV.compiler.to_s.start_with?("gcc")

    # Work around to support `icu4c` 75, which needs C++17.
    ENV["ICU_CXXFLAGS"] = "-std=c++17"

    # buildconf required due to system library linking bug patch
    system "./buildconf", "--force"

    config_path = etc/name.to_s
    # Prevent system pear config from inhibiting pear install
    (config_path/"pear.conf").delete if (config_path/"pear.conf").exist?

    ENV["lt_cv_path_SED"] = "sed"

    ENV["PHP_BUILD_PROVIDER"] = "valet.sh"

    # system pkg-config missing
    ENV["KERBEROS_CFLAGS"] = " "
    if OS.mac?
      ENV["SASL_CFLAGS"] = "-I#{MacOS.sdk_path}/usr/include/sasl"
      ENV["SASL_LIBS"] = "-lsasl2"
    else
      ENV["SQLITE_CFLAGS"] = "-I#{formula_opt_include("sqlite")}"
      ENV["SQLITE_LIBS"] = "-lsqlite3"
      ENV["BZIP_DIR"] = formula_opt_prefix("bzip2")
    end

    # Each extension that is built on Mojave needs a direct reference to the
    # sdk path or it won't find the headers
    headers_path = "=#{MacOS.sdk_path}/usr"

    ENV["EXTENSION_DIR"] = "#{prefix}/lib/#{name}/20200930"
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
      --enable-dtrace
      --enable-exif
      --enable-ftp
      --enable-fpm
      --enable-gd
      --enable-intl
      --enable-mbregex
      --enable-mbstring
      --enable-mysqlnd
      --enable-pcntl
      --enable-phpdbg
      --enable-phpdbg-readline
      --enable-phpdbg-webhelper
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
      --with-fpm-user=_www
      --with-fpm-group=_www
      --with-freetype
      --with-gettext=#{formula_opt_prefix("gettext")}
      --with-gmp=#{formula_opt_prefix("gmp")}
      --with-iconv#{headers_path}
      --with-jpeg
      --with-kerberos
      --with-layout=GNU
      --with-ldap=#{formula_opt_prefix("openldap")}
      --with-ldap-sasl
      --with-libxml
      --with-libedit
      --with-mhash#{headers_path}
      --with-mysql-sock=/tmp/mysql.sock
      --with-mysqli=mysqlnd
      --with-ndbm#{headers_path}
      --with-openssl
      --with-password-argon2=#{formula_opt_prefix("argon2")}
      --with-pdo-dblib=#{formula_opt_prefix("freetds")}
      --with-pdo-mysql=mysqlnd
      --with-pdo-odbc=unixODBC,#{formula_opt_prefix("unixodbc")}
      --with-pdo-pgsql=#{formula_opt_prefix("libpq")}
      --with-pdo-sqlite
      --with-pgsql=#{formula_opt_prefix("libpq")}
      --with-pic
      --with-pspell=#{formula_opt_prefix("aspell")}
      --with-sodium
      --with-sqlite3
      --with-tidy=#{formula_opt_prefix("tidy-html5")}
      --with-unixODBC
      --with-webp
      --with-xmlrpc
      --with-xsl
      --with-zip
      --with-zlib
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
      system "./configure", "--with-php-config=#{bin}/php-config#{bin_suffix}"
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
        ENV.clang
      end
      system "./configure", "--with-php-config=#{bin}/php-config#{bin_suffix}"
      system "make"
      system "make", "install"
    end
  end

  post_install_steps do
    # Keep shared extensions in var so they survive upgrades: move the keg's
    # extension dir there and leave a symlink in its place. The symlink from an
    # earlier run is removed first so these steps stay idempotent.
    mkdir_p "{{var}}/{{name}}/20200930"
    remove "{{lib}}/{{name}}/20200930", symlink_target_contains: "/var/vsh-php80/20200930"
    if_path_exists "{{lib}}/{{name}}/20200930" do
      move_contents "{{lib}}/{{name}}/20200930", "{{var}}/{{name}}/20200930"
      remove "{{lib}}/{{name}}/20200930", recursive: true
    end
    symlink "{{var}}/{{name}}/20200930", "{{lib}}/{{name}}/20200930"

    # pear ships its registry without read access for group/other
    set_permissions "{{pkgshare}}/pear/.channels", "u=rwX,go=rX"
    set_permissions ["{{pkgshare}}/pear/.depdblock", "{{pkgshare}}/pear/.filemap"], "0644", recursive: false
    set_permissions ["{{pkgshare}}/pear/.depdb", "{{pkgshare}}/pear/.lock"], "0644", recursive: false

    run "{{bin}}/pear{{version.major_minor}}", args: ["config-set", "php_ini", "{{pkgetc}}/php.ini", "system"]
    run "{{bin}}/pear{{version.major_minor}}", args: ["update-channels"], network_access: true

    # Register shared extensions. Existing files are kept and only the
    # extension line is normalised.
    write_file "{{pkgetc}}/conf.d/ext-intl.ini", <<~INI, overwrite: false
      [intl]
      extension=intl.so
    INI
    inreplace "{{pkgetc}}/conf.d/ext-intl.ini", /extension=.*$/, "extension=intl.so"
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
    error_log_path var/"log/vsh-php80.log"
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
diff --git a/ext/curl/interface.c b/ext/curl/interface.c
index 134de48d6fe..90f486dfe77 100644
--- a/ext/curl/interface.c
+++ b/ext/curl/interface.c
@@ -1453,11 +1453,11 @@ static int curl_fnmatch(void *ctx, const char *pattern, const char *string)
 /* }}} */

 /* {{{ curl_progress */
-static size_t curl_progress(void *clientp, double dltotal, double dlnow, double ultotal, double ulnow)
+static int curl_progress(void *clientp, double dltotal, double dlnow, double ultotal, double ulnow)
 {
 	php_curl *ch = (php_curl *)clientp;
 	php_curl_progress *t = ch->handlers->progress;
-	size_t	rval = 0;
+	int rval = 0;

 #if PHP_CURL_DEBUG
 	fprintf(stderr, "curl_progress() called\n");
@@ -1817,8 +1817,8 @@ static void _php_curl_set_default_options(php_curl *ch)
 {
 	char *cainfo;

-	curl_easy_setopt(ch->cp, CURLOPT_NOPROGRESS,        1);
-	curl_easy_setopt(ch->cp, CURLOPT_VERBOSE,           0);
+	curl_easy_setopt(ch->cp, CURLOPT_NOPROGRESS,        1L);
+	curl_easy_setopt(ch->cp, CURLOPT_VERBOSE,           0L);
 	curl_easy_setopt(ch->cp, CURLOPT_ERRORBUFFER,       ch->err.str);
 	curl_easy_setopt(ch->cp, CURLOPT_WRITEFUNCTION,     curl_write);
 	curl_easy_setopt(ch->cp, CURLOPT_FILE,              (void *) ch);
@@ -1829,8 +1829,8 @@ static void _php_curl_set_default_options(php_curl *ch)
 #ifndef ZTS
 	curl_easy_setopt(ch->cp, CURLOPT_DNS_USE_GLOBAL_CACHE, 1);
 #endif
-	curl_easy_setopt(ch->cp, CURLOPT_DNS_CACHE_TIMEOUT, 120);
-	curl_easy_setopt(ch->cp, CURLOPT_MAXREDIRS, 20); /* prevent infinite redirects */
+	curl_easy_setopt(ch->cp, CURLOPT_DNS_CACHE_TIMEOUT, 120L);
+	curl_easy_setopt(ch->cp, CURLOPT_MAXREDIRS, 20L); /* prevent infinite redirects */

 	cainfo = INI_STR("openssl.cafile");
 	if (!(cainfo && cainfo[0] != '\0')) {
@@ -1841,7 +1841,7 @@ static void _php_curl_set_default_options(php_curl *ch)
 	}

 #ifdef ZTS
-	curl_easy_setopt(ch->cp, CURLOPT_NOSIGNAL, 1);
+	curl_easy_setopt(ch->cp, CURLOPT_NOSIGNAL, 1L);
 #endif
 }
 /* }}} */
@@ -2216,7 +2216,7 @@ static int _php_curl_setopt(php_curl *ch, zend_long option, zval *zvalue, bool i
 			lval = zval_get_long(zvalue);
 			if (lval == 1) {
 				php_error_docref(NULL, E_NOTICE, "CURLOPT_SSL_VERIFYHOST no longer accepts the value 1, value 2 will be used instead");
-				error = curl_easy_setopt(ch->cp, option, 2);
+				error = curl_easy_setopt(ch->cp, option, 2L);
 				break;
 			}
 		case CURLOPT_AUTOREFERER:
@@ -2377,7 +2377,7 @@ static int _php_curl_setopt(php_curl *ch, zend_long option, zval *zvalue, bool i
 				return 1;
 			}
 # endif
-			error = curl_easy_setopt(ch->cp, option, lval);
+			error = curl_easy_setopt(ch->cp, option, (long) lval);
 			break;
 		case CURLOPT_SAFE_UPLOAD:
 			if (!zend_is_true(zvalue)) {
@@ -2711,7 +2711,7 @@ static int _php_curl_setopt(php_curl *ch, zend_long option, zval *zvalue, bool i

 		case CURLOPT_FOLLOWLOCATION:
 			lval = zend_is_true(zvalue);
-			error = curl_easy_setopt(ch->cp, option, lval);
+			error = curl_easy_setopt(ch->cp, option, (long) lval);
 			break;

 		case CURLOPT_HEADERFUNCTION:
@@ -2729,7 +2729,7 @@ static int _php_curl_setopt(php_curl *ch, zend_long option, zval *zvalue, bool i
 					/* no need to build the mime structure for empty hashtables;
 					   also works around https://github.com/curl/curl/issues/6455 */
 					curl_easy_setopt(ch->cp, CURLOPT_POSTFIELDS, "");
-					error = curl_easy_setopt(ch->cp, CURLOPT_POSTFIELDSIZE, 0);
+					error = curl_easy_setopt(ch->cp, CURLOPT_POSTFIELDSIZE, 0L);
 				} else {
 					return build_mime_structure_from_hash(ch, zvalue);
 				}
@@ -2794,7 +2794,7 @@ static int _php_curl_setopt(php_curl *ch, zend_long option, zval *zvalue, bool i

 		case CURLOPT_POSTREDIR:
 			lval = zval_get_long(zvalue);
-			error = curl_easy_setopt(ch->cp, CURLOPT_POSTREDIR, lval & CURL_REDIR_POST_ALL);
+			error = curl_easy_setopt(ch->cp, CURLOPT_POSTREDIR, (long) (lval & CURL_REDIR_POST_ALL));
 			break;

 		/* the following options deal with files, therefore the open_basedir check
@@ -2829,11 +2829,11 @@ static int _php_curl_setopt(php_curl *ch, zend_long option, zval *zvalue, bool i
 			if (zend_is_true(zvalue)) {
 				curl_easy_setopt(ch->cp, CURLOPT_DEBUGFUNCTION, curl_debug);
 				curl_easy_setopt(ch->cp, CURLOPT_DEBUGDATA, (void *)ch);
-				curl_easy_setopt(ch->cp, CURLOPT_VERBOSE, 1);
+				curl_easy_setopt(ch->cp, CURLOPT_VERBOSE, 1L);
 			} else {
 				curl_easy_setopt(ch->cp, CURLOPT_DEBUGFUNCTION, NULL);
 				curl_easy_setopt(ch->cp, CURLOPT_DEBUGDATA, NULL);
-				curl_easy_setopt(ch->cp, CURLOPT_VERBOSE, 0);
+				curl_easy_setopt(ch->cp, CURLOPT_VERBOSE, 0L);
 			}
 			break;
