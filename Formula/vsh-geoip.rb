class VshGeoip < Formula
  desc "This library is for the GeoIP Legacy format (dat)"
  homepage "https://github.com/maxmind/geoip-api-c"
  url "https://github.com/maxmind/geoip-api-c/releases/download/v1.6.12/GeoIP-1.6.12.tar.gz"
  sha256 "1dfb748003c5e4b7fd56ba8c4cd786633d5d6f409547584f6910398389636f80"
  license "LGPL-2.1-or-later"
  revision 1
  head "https://github.com/maxmind/geoip-api-c.git", branch: "main"

  bottle do
    root_url "https://ghcr.io/v2/valet-sh/php"
    sha256 cellar: :any, arm64_golden_gate: "4d6b6567230a40437e771d0de44a8b5a6e1c6e4f721bbad3479c44751e6eb1f4"
    sha256 cellar: :any, arm64_tahoe:       "9baee7e49a81e727597f8063aaf3ddcac2167fe23da679342e5e459b9e8e67b5"
  end

  resource "database" do
    url "https://src.fedoraproject.org/lookaside/pkgs/GeoIP/GeoIP.dat.gz/4bc1e8280fe2db0adc3fe48663b8926e/GeoIP.dat.gz"
    sha256 "7fd7e4829aaaae2677a7975eeecd170134195e5b7e6fc7d30bf3caf34db41bcd"
  end

  def install
    system "./configure", "--disable-dependency-tracking",
                          "--disable-silent-rules",
                          "--datadir=#{var}",
                          "--prefix=#{prefix}"
    system "make", "install"
  end

  post_install_steps do
    mkdir_p "{{var}}/GeoIP"

    # The data directory moved from share/GeoIP to var/GeoIP: carry over existing databases.
    if_path_exists "{{HOMEBREW_PREFIX}}/share/GeoIP" do
      run "/bin/cp", args: ["-R", "{{HOMEBREW_PREFIX}}/share/GeoIP/.", "{{var}}/GeoIP"]
    end

    # Default database names expected by geoiplookup. A real file is left alone,
    # a missing or dangling link is (re)created.
    unless_path_exists "{{var}}/GeoIP/GeoIP.dat" do
      symlink "{{var}}/GeoIP/GeoLiteCountry.dat", "{{var}}/GeoIP/GeoIP.dat", overwrite: true
    end
    unless_path_exists "{{var}}/GeoIP/GeoIPCity.dat" do
      symlink "{{var}}/GeoIP/GeoLiteCity.dat", "{{var}}/GeoIP/GeoIPCity.dat", overwrite: true
    end
  end

  test do
    resource("database").stage do
      output = shell_output("#{bin}/geoiplookup -f GeoIP.dat 8.8.8.8")
      assert_match "GeoIP Country Edition: US, United States", output
    end
  end
end
