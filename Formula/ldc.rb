class Ldc < Formula
  desc "Portable D programming language compiler"
  homepage "https://wiki.dlang.org/LDC"
  url "https://github.com/ldc-developers/ldc/releases/download/v1.14.0/ldc-1.14.0-src.tar.gz"
  sha256 "2c790f5f7f944e5ee2e73df2720baf211a02e42345f2f4fd375674f9ffa7fb90"
  head "https://github.com/ldc-developers/ldc.git", :shallow => false

  bottle do
    root_url "https://linuxbrew.bintray.com/bottles"
    cellar :any_skip_relocation
    sha256 "2f1aa9300d244dbeb1a14cc358fefc86b7bf4d76885edb18c1778bf3f391bc43" => :mojave
    sha256 "cde039bb59b8922df58bb395b649dfb643a14caac2afd2abfcf3f25b5f055f28" => :high_sierra
    sha256 "ac65b80edd5acbbdb0e75b5eff174ceaa0e4e67f0f6e7d27027636fd2206d969" => :sierra
    sha256 "b71378d2ef9b1c64e5818de0d35a4a81c9ca0287fc2fe0f28e0955e54b58f307" => :x86_64_linux
  end

  depends_on "cmake" => :build
  depends_on "libconfig" => :build
  depends_on "llvm"

  resource "ldc-bootstrap" do
    if OS.mac?
      url "https://github.com/ldc-developers/ldc/releases/download/v1.12.0/ldc2-1.12.0-osx-x86_64.tar.xz"
      version "1.12.0"
      sha256 "a946e658aaff1eed80bffeb4d69b572f259368fac44673731781f6d487dea3cd"
    else
      url "https://github.com/ldc-developers/ldc/releases/download/v1.12.0/ldc2-1.12.0-linux-x86_64.tar.xz"
      version "1.12.0"
      sha256 "eeb83d3356d6ba3f5892f629de466df79c02bac5fd1f0e1ecdf01fe6171d42ac"
    end
  end

  def install
    # Fix the error:
    # CMakeFiles/LDCShared.dir/build.make:68: recipe for target 'dmd2/id.h' failed
    ENV.deparallelize unless OS.mac?

    ENV.cxx11
    (buildpath/"ldc-bootstrap").install resource("ldc-bootstrap")

    mkdir "build" do
      args = std_cmake_args + %W[
        -DLLVM_ROOT_DIR=#{Formula["llvm"].opt_prefix}
        -DINCLUDE_INSTALL_DIR=#{include}/dlang/ldc
        -DD_COMPILER=#{buildpath}/ldc-bootstrap/bin/ldmd2
        -DLDC_WITH_LLD=OFF
        -DRT_ARCHIVE_WITH_LDC=OFF
      ]
      # LDC_WITH_LLD see https://github.com/ldc-developers/ldc/releases/tag/v1.4.0 Known issues
      # RT_ARCHIVE_WITH_LDC see https://github.com/ldc-developers/ldc/issues/2350

      system "cmake", "..", *args
      system "make"
      system "make", "install"
    end
  end

  test do
    (testpath/"test.d").write <<~EOS
      import std.stdio;
      void main() {
        writeln("Hello, world!");
      }
    EOS
    system bin/"ldc2", "test.d"
    assert_match "Hello, world!", shell_output("./test")
    # Fix Error: The LLVMgold.so plugin (needed for LTO) was not found.
    if OS.mac?
      system bin/"ldc2", "-flto=thin", "test.d"
      assert_match "Hello, world!", shell_output("./test")
      system bin/"ldc2", "-flto=full", "test.d"
      assert_match "Hello, world!", shell_output("./test")
    end
    system bin/"ldmd2", "test.d"
    assert_match "Hello, world!", shell_output("./test")
  end
end
