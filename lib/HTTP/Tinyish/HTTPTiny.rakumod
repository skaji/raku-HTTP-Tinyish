use HTTP::Tinyish::Base;

unit class HTTP::Tinyish::HTTPTiny is HTTP::Tinyish::Base;

my constant DEBUG = %*ENV<HTTP_TINYISH_DEBUG>;

has      $!client;
has      $.async = False;
has Int  $.timeout = 60;
has Int  $.max-redirect = 5;
has      $.agent = $?PACKAGE.perl;
has      %.default-headers;
has Bool $.verify-ssl = True;

submethod TWEAK {
    ( try require ::('HTTP::Tiny') ) === Nil and return;

    $!client = ::('HTTP::Tiny').new:
        :%!default-headers,
        :$!agent,
        :$!verify-ssl,
        :$!max-redirect,
        :$!timeout;
}

method configure ( --> Hash ) {
    my %meta;

    ( try require ::('HTTP::Tiny') ) === Nil and return %meta;

    %meta<http>  = True;
    %meta<https> = so ::('HTTP::Tiny').can-ssl;

    return %meta;
}

method request ( $method, $url, Bool :$bin = False, *%opts ) {
    warn "=> { $method, $url, |%opts }" if DEBUG;

    if $.async {
        my $raw = start $!client.request: $method, $url, |%opts;

        return $raw if $bin;

        return $raw.then: {
            my $res = .result;
            $res<content> = ( $res<content> // Blob.new ).decode;
            $res;
        }
    }

    my $res = $!client.request: $method, $url, |%opts;

    $res<content> = ( $res<content> // Blob.new ).decode unless $bin;

    return $res;
}

method mirror ( $url, $file, Bool :$bin = False, *%opts ) {
    warn "=> { $url, $file, |%opts }" if DEBUG;

    if $.async {
        my $raw = start $!client.mirror: $url, $file, |%opts;

        return $raw if $bin;

        return $raw.then: {
            my $res = .result;
            $res<content> = ( $res<content> // Blob.new ).decode;
            $res;
        }
    }

    my $res = $!client.mirror: $url, $file, |%opts;

    $res<content> = ( $res<content> // Blob.new ).decode unless $bin;

    return $res;
}
