class Neomutt < Formula
  desc "Bringing together all the Mutt Code"
  homepage "http://www.neomutt.org/"
  url "https://github.com/neomutt/neomutt.git", :tag => "neomutt-20160404", :revision => "fba0ecd82522c2eacb1aaa70044cae5a77c93acf"

  head do
    url "https://github.com/neomutt/neomutt.git", :branch => "neomutt"

    # TODO: this resource is a single HTML page in the original mutt.rb
    # The index page for NeoMutt, downloaded here, won't be as useful
    resource "html" do
      url "http://www.neomutt.org/manual/", :using => :nounzip
      sha256 "9968bf7ea6f26c424f9d04c95a51ce5bbb1086572dbdfc6850b563e8a428ea7f"
    end
  end

  conflicts_with "tin",
    :because => "both install mmdf.5 and mbox.5 man pages"

  conflicts_with "mutt", :because => "both install mutt binaries"

  option "with-debug", "Build with debug option enabled"
  option "with-s-lang", "Build against slang instead of ncurses"

  # Neomutt-specific patches
  option "with-sidebar-patch", "Apply sidebar patch"

  depends_on "autoconf" => :build
  depends_on "automake" => :build

  depends_on "openssl"
  depends_on "tokyo-cabinet"
  depends_on "gettext" => :optional
  depends_on "gpgme" => :optional
  depends_on "libidn" => :optional
  depends_on "s-lang" => :optional

  def install
    user_admin = Etc.getgrnam("admin").mem.include?(ENV["USER"])

    args = %W[
      --disable-dependency-tracking
      --disable-warnings
      --prefix=#{prefix}
      --with-ssl=#{Formula["openssl"].opt_prefix}
      --with-sasl
      --with-gss
      --enable-imap
      --enable-smtp
      --enable-pop
      --enable-hcache
      --with-tokyocabinet
    ]

    # This is just a trick to keep 'make install' from trying
    # to chgrp the mutt_dotlock file (which we can't do if
    # we're running as an unprivileged user)
    args << "--with-homespool=.mbox" unless user_admin

    args << "--disable-nls" if build.without? "gettext"
    args << "--enable-gpgme" if build.with? "gpgme"
    args << "--with-slang" if build.with? "s-lang"
    args << "--enable-sidebar" if build.with? "sidebar-patch"

    if build.with? "debug"
      args << "--enable-debug"
    else
      args << "--disable-debug"
    end

    system "./prepare", *args
    system "make"

    # This permits the `mutt_dotlock` file to be installed under a group
    # that isn't `mail`.
    # https://github.com/Homebrew/homebrew/issues/45400
    if user_admin
      inreplace "Makefile", /^DOTLOCK_GROUP =.*$/, "DOTLOCK_GROUP = admin"
    end

    system "make", "install"
    doc.install resource("html") if build.head?
  end

  test do
    system bin/"mutt", "-D"
  end
end