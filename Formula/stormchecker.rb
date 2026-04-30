class Stormchecker < Formula
  desc "Modern probabilistic model checker"
  homepage "https://www.stormchecker.org"
  url "https://github.com/volkm/storm/archive/refs/tags/1.42.6.tar.gz"
  sha256 "050ac5a6d4a751b68a1a56d25786cffdf878e7202f17f4fe19b127d40c7b8add"
  license "GPL-3.0-only"
  head "https://github.com/stormchecker/storm.git", using: :git, branch: "master"

  bottle do
    root_url "https://github.com/volkm/homebrew-storm/releases/download/stormchecker-1.42.6"
    sha256 cellar: :any,                 arm64_tahoe:   "89ba44f8ce7bfba5b3feb7eaf1cf25f7361d6d25deaca9bd47373229fae0a249"
    sha256 cellar: :any,                 arm64_sequoia: "33d8428da1af81010b49c2fda074822aa7437b63c779746959eba068e35a90c1"
    sha256 cellar: :any,                 arm64_sonoma:  "3bba21e1ab7034e73fe2f97031feead013ade6be4b4c9430934a81b3036ece5f"
    sha256 cellar: :any_skip_relocation, arm64_linux:   "cdedfc015d8778a2d42c7ed5bebf3a68578ef3969db5fcf4efe624546f047966"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "9b03521833acaab7bbdc881de8f330db4ecf1d21ab3d3997a207c3260389fa6b"
  end

  depends_on "automake" => :build
  depends_on "cmake" => :build
  depends_on "boost"
  depends_on "cln"
  depends_on "ginac"
  depends_on "glpk"
  depends_on "gmp"
  depends_on "hwloc"
  depends_on "libarchive"
  depends_on "spot"
  depends_on "xerces-c"
  depends_on "z3"

  # Additional dependencies (usually obtained via FetchContent)
  resource "carl-storm" do
    url "https://github.com/volkm/carl-storm/archive/refs/tags/14.48.tar.gz"
    sha256 "5cf13106b72f4d47f5e8a2b60d4e5536f2fe50cd68a9c0bf07e632358663267a"
  end

  def install
    # Stage resources
    (buildpath/"fetched_deps").mkpath
    resources.each do |r|
      r.stage buildpath/"fetched_deps"/r.name
    end

    # Set CMake flags
    args = %w[
      -DCMAKE_BUILD_TYPE=RELEASE
      -DSTORM_COMPILE_WITH_CCACHE=OFF
      -DSTORM_BUILD_TESTS=OFF
      -DFETCHCONTENT_SOURCE_DIR_CARL=fetched_deps/carl-storm
      -DFETCHCONTENT_SOURCE_DIR_SYLVANFETCH=resources/3rdparty/sylvan
    ]

    # Build and install
    system "cmake", "-S", ".", "-B", "build", *(std_cmake_args + args)
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    # Write small MDP file
    (testpath/"walk.nm").write <<~EOS
      mdp
      const int N;
      const double p = 0.5;
      module main
              x : [0..N] init N/2;
              [right] x<N -> p : (x'=x+1) + (1-p) : (x'=x);
              [left] x>0 -> p : (x'=x-1) + (1-p) : (x'=x);
      endmodule
    EOS
    # Run Storm and check output
    output = shell_output("#{bin}/storm --prism #{testpath}/walk.nm -prop 'Pmax=? [F<=10 x=0]' -const 'N=10' --exact")
    assert_match "Result (for initial states): 319/512", output
  end
end
