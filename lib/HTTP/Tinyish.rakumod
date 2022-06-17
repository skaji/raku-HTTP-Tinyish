unit class HTTP::Tinyish:ver<0.3.0>:auth<cpan:SKAJI>;

my $*HTTP-TINYISH-PREFERRED-BACKEND;

my %BACKENDS;

has Capture $!capture;

# Store arguments passed to the constructor for building backends
submethod TWEAK (|c) { $!capture = c }

method delete ( $url, |c ) { self!backend-for($url).delete: $url, |c }
method get    ( $url, |c ) { self!backend-for($url).get:    $url, |c }
method head   ( $url, |c ) { self!backend-for($url).head:   $url, |c }
method mirror ( $url, |c ) { self!backend-for($url).mirror: $url, |c }
method patch  ( $url, |c ) { self!backend-for($url).patch:  $url, |c }
method post   ( $url, |c ) { self!backend-for($url).post:   $url, |c }
method put    ( $url, |c ) { self!backend-for($url).put:    $url, |c }

method request ( $method, $url, |c ) {
    self!backend-for($url).request: $method, $url, |c;
}

method !backend-for ($url) is hidden-from-backtrace {
    $url ~~ / ^ $<scheme> = ( https? ) '://' /
        or die "URL Scheme '$url' not supported.";

    once {
        my $lock = Lock.new;
        for < Curl HTTPTiny >.map: { "HTTP::Tinyish::$_" } -> $backend {
            $lock.lock;
            require ::($backend);
            $lock.unlock;

            next if ::($backend) ~~ Failure;

            my %meta = ::($backend).configure;

            for %meta.keys -> $scheme {
                %BACKENDS{$scheme} //= [];
                %BACKENDS{$scheme}.push: ::($backend);
            }
        }
    }

    my $matcher = $*HTTP-TINYISH-PREFERRED-BACKEND
        ?? { .^name ~~ $*HTTP-TINYISH-PREFERRED-BACKEND }
        !! *;

    my $backend = %BACKENDS{ ~$<scheme> }.first($matcher);

    die "No backend configured for scheme $<scheme>" if $backend === Any;

    $backend.new: |$!capture;
}

=begin pod

=head1 NAME

HTTP::Tinyish - Raku port of HTTP::Tinyish

=head1 SYNOPSIS

Synchronous way:

=begin code :lang<raku>

my $http = HTTP::Tinyish.new(agent => "Mozilla/4.0");

my %res = $http.get("http://www.cpan.org/");
warn %res<status>;

$http.post:
  "http://example.com/post",
  headers => { "Content-Type" => "application/x-www-form-urlencoded" },
  content => "foo=bar&baz=quux",
;

$http.mirror:
  "http://www.cpan.org/modules/02packages.details.txt.gz",
  "./02packages.details.txt.gz",
;

=end code

Asynchronous way:

=begin code :lang<raku>

my $http = HTTP::Tinyish.new(:async);

my @url = <
  https://raku.org/
  https://doc.raku.org/
  https://design.raku.org/
>;

my @promise = @url.map: -> $url {
  $http.get($url).then: -> $promise {
    my %res = $promise.result;
    say "Done %res<status> %res<url>";
    %res;
  };
};

my @res = await @promise;

=end code

=head1 DESCRIPTION

HTTP::Tinyish is a Raku port of L<https://github.com/miyagawa/HTTP-Tinyish>.
It provides a common API for multiple backend HTTP clients, which are selected
based on their availability and the features they support. Currently, it supports
C<curl> and HTTP::Tiny.

=head2 Str VS Buf

Raku distinguishes Str from Buf.
HTTP::Tinyish handles data as Str by default
(that is, encode/decode utf-8 if needed by default).
If you want to handle data as Buf, please follow the instruction below.

If you want to send Buf content, just specify Buf in content:

=begin code :lang<raku>

my $binary-data = "file.bin".IO.slurp(:bin);
$http.post:
  "http://example.com/post",
  content => $binary-data,
;

=end code

If you want to recieve http content as Buf, then call request/get/post/... method with
C<< bin => True >>:

=begin code :lang<raku>

my %res = $http.get("http://example.com/image.png", bin => True);
does-ok %res<content>, Buf; # pass

=end code

And decode C<< %res<content> >> by yourself if you want.

=head1 COPYRIGHT AND LICENSE

Copyright 2015 Shoichi Kaji <skaji@cpan.org>

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

Original perl5 HTTP::Tinyish COPYRIGHT and LICENSE:

  COPYRIGHT
  Tatsuhiko Miyagawa, 2015-

  LICENSE
  This module is licensed under the same terms as Perl itself.

=end pod
