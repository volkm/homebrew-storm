class CarlStorm < Formula
  desc "Computer ARithmetic and Logic library for the probabilistic model checker Storm"
  homepage "https://github.com/moves-rwth/carl-storm/"
  # version is extracted from url
  url "https://github.com/moves-rwth/carl-storm/archive/refs/tags/14.25.tar.gz"
  sha256 "511740d53c2a6a41c3ccb3bd3b2d9ec89d0576f37b8804fc15fbe083e7a357da"
  license "MIT"

  head "https://github.com/moves-rwth/carl-storm.git", branch: "master", using: :git

  depends_on "boost"
  depends_on "cmake"
  depends_on "eigen"
  depends_on "gmp"
  on_intel do
    depends_on "cln"
    depends_on "ginac"
  end

  def install
    args = [
      "-DEXPORT_TO_CMAKE=OFF",
      "-DCMAKE_BUILD_TYPE=RELEASE",
      "-DEXCLUDE_TESTS_FROM_ALL=ON",
      "-DTHREAD_SAFE=ON",
    ]
    args += ["-DUSE_CLN_NUMBERS=ON", "-DUSE_GINAC=ON"] if Hardware::CPU.intel?
    args += ["-DUSE_CLN_NUMBERS=OFF", "-DUSE_GINAC=OFF"] if Hardware::CPU.arm?

    mktemp do
      system "cmake", buildpath, *(std_cmake_args + args)
      system "make", "install"
    end
  end

  test do
    (testpath/"test.cpp").write <<~EOS
      #include <carl/core/RationalFunction.h>
      #include <carl/numbers/numbers.h>
      #include <carl/util/stringparser.h>

      using Rational = mpq_class;
      typedef carl::MultivariatePolynomial<Rational> Pol;
      typedef carl::RationalFunction<Pol> RFunc;

      int main() {
          carl::StringParser sp;
          sp.setVariables({"x", "y", "z"});
          Pol p1 = sp.parseMultivariatePolynomial<Rational>("3*x*y + x");
          Pol p2 = sp.parseMultivariatePolynomial<Rational>("5*y");
          RFunc r1(p1, p2);
          RFunc r2 = r1 * p2;
          return r2.denominator() == 1;
      }
    EOS
    libs = ["-lcarl", "-L#{lib}"]
    libs += ["-lgmp", "-lgmpxx", "-L#{Formula["gmp"].lib}"]
    libs += ["-lcln", "-L#{Formula["cln"].lib}"] if Hardware::CPU.intel?
    libs += ["-lginac", "-L#{Formula["ginac"].lib}"] if Hardware::CPU.intel?

    system ENV.cxx, "test.cpp", "-std=c++17", "-o", "test", *libs
    system "./test"
  end
end
