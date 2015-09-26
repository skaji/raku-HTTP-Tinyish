[![Build Status](https://travis-ci.org/shoichikaji/perl6-HTTP-Tinyish.svg?branch=master)](https://travis-ci.org/shoichikaji/perl6-HTTP-Tinyish)

NAME
====

HTTP::Tinyish - perl6 port of HTTP::Tinyish

SYNOPSIS
========

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

DESCRIPTION
===========

HTTP::Tinyish is perl6 port of [https://github.com/miyagawa/HTTP-Tinyish](https://github.com/miyagawa/HTTP-Tinyish). Currently only support curl.

COPYRIGHT AND LICENSE
=====================

Copyright 2015 Shoichi Kaji <skaji@cpan.org>

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

Original perl5 HTTP::Tinyish COPYRIGHT and LICENSE:

    COPYRIGHT
    Tatsuhiko Miyagawa, 2015-

    LICENSE
    This module is licensed under the same terms as Perl itself.
