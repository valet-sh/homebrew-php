class VshGeoip < Formula
  desc "This library is for the GeoIP Legacy format (dat)"
  homepage "https://github.com/maxmind/geoip-api-c"
  url "https://github.com/maxmind/geoip-api-c/releases/download/v1.6.12/GeoIP-1.6.12.tar.gz"
  sha256 "1dfb748003c5e4b7fd56ba8c4cd786633d5d6f409547584f6910398389636f80"
  # revision 1
  license "LGPL-2.1-or-later"
  head "https://github.com/maxmind/geoip-api-c.git", branch: "main"

  bottle do
    root_url "https://ghcr.io/v2/valet-sh/php"
    sha256 cellar: :any,                 arm64_tahoe:  "0a554d6d4c197408fc8277fd276ed59183e037896f308939f2155f2807d49a45"
    sha256 cellar: :any,                 sequoia:      "a7da3793ae72d2527e140791ff3edfbd53015d2e40a18be9b5f098dc0de4a630"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "bb7b16a8c7e7b7ca574cf5c7cf733e15e45efc1e9feff0d70f3bd707f785ac4b"
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

  def post_install
    geoip_data = Pathname.new "#{var}/GeoIP"
    geoip_data.mkpath

    # Since default data directory moved, copy existing DBs
    legacy_data = Pathname.new "#{HOMEBREW_PREFIX}/share/GeoIP"
    cp Dir["#{legacy_data}/*"], geoip_data if legacy_data.exist?

    full = Pathname.new "#{geoip_data}/GeoIP.dat"
    ln_s "GeoLiteCountry.dat", full if !full.exist? && !full.symlink?
    full = Pathname.new "#{geoip_data}/GeoIPCity.dat"
    ln_s "GeoLiteCity.dat", full if !full.exist? && !full.symlink?
  end

  test do
    resource("database").stage do
      output = shell_output("#{bin}/geoiplookup -f GeoIP.dat 8.8.8.8")
      assert_match "GeoIP Country Edition: US, United States", output
    end
  end
end
