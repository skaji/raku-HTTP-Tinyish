use v6;
unit class HTTP::Tinyish;
use HTTP::Tinyish::Curl;

method new(*%opt) {
    HTTP::Tinyish::Curl.new(|%opt);
}

=begin pod

=head1 NAME

HTTP::Tinyish - perl6 port of HTTP::Tinyish

=head1 SYNOPSIS

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

=head1 DESCRIPTION

HTTP::Tinyish is perl6 port of L<https://github.com/miyagawa/HTTP-Tinyish>.
Currently only support curl.

=head1 COPYRIGHT AND LICENSE

Copyright 2015 Shoichi Kaji <skaji@cpan.org>

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

Original perl5 HTTP::Tinyish COPYRIGHT and LICENSE:

  COPYRIGHT
  Tatsuhiko Miyagawa, 2015-

  LICENSE
  This module is licensed under the same terms as Perl itself.

=end pod
