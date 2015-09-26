use v6;
use HTTP::Tinyish::Base;
use File::Temp;

unit class HTTP::Tinyish::Curl is HTTP::Tinyish::Base;

my constant DEBUG = %*ENV<HTTP_TINYISH_DEBUG>;

has $.curl = "curl";
has Int $.timeout = 60;
has Int $.max-redirect = 5;
has $.agent = $?PACKAGE.perl;
has %.default-headers;
has Bool $.verify-ssl = True;

method request($method, $url, *%opts) {
    my ($out-file, $out-fh);
    my ($err-file, $err-fh);
    my ($header-file, $header-fh);
    LEAVE {
        $_.close for grep {.defined}, $out-fh, $err-fh, $header-fh;
        unlink $_ for grep {.defined && .IO.e}, $out-file, $err-file, $header-file;
    }
    ($out-file, $out-fh) = tempfile(:!unlink);
    ($err-file, $err-fh) = tempfile(:!unlink);
    ($header-file, $header-fh) = tempfile(:!unlink);
    my @cmd =
        $!curl,
        "-X", $method,
        self!build-options($url, |%opts),
        "--dump-header", $header-file
    ;
    @cmd.push("--head") if $method eq "HEAD";
    @cmd.push($url);
    warn "=> @cmd[]" if DEBUG;
    my $status = run |@cmd, :out($out-fh), :err($err-fh);
    $_.close for $out-fh, $err-fh; # XXX
    if ($status.exitcode != 0) {
        my $err = $err-file.IO.slurp;
        return self.internal-error($url, $err);
    }
    my %res = url => $url, content => $out-file.IO.slurp;
    self.parse-http-header($header-file.IO.slurp, %res);
    return %res;
}

method mirror($url, $file, *%opts) {
    my ($out-file, $out-fh);
    my ($err-file, $err-fh);
    my ($header-file, $header-fh);
    LEAVE {
        $_.close for grep {.defined}, $out-fh, $err-fh, $header-fh;
        unlink $_ for grep {.defined && .IO.e}, $out-file, $err-file, $header-file;
    }
    ($out-file, $out-fh) = tempfile(:!unlink);
    ($err-file, $err-fh) = tempfile(:!unlink);
    ($header-file, $header-fh) = tempfile(:!unlink);
    my @cmd =
        $!curl,
        self!build-options($url, |%opts),
        "-z", $file,
        "-o", $file,
        "--dump-header", $header-file,
        "--remote-time",
        $url,
    ;
    my $status = run |@cmd, :out($out-fh), :err($err-fh);
    $_.close for $out-fh, $err-fh; # XXX
    if ($status.exitcode != 0) {
        my $err = $err-file.IO.slurp;
        return self.internal-error($url, $err);
    }
    my %res = url => $url, content => $out-file.IO.slurp;
    self.parse-http-header($header-file.IO.slurp, %res);
    return %res;
}


method !build-options($url, *%opts) {
    my %headers;
    if %!default-headers {
        %headers = |%!default-headers;
    }
    if %opts<headers> {
        %headers = |%headers, |%opts<headers>;
    }

    my @options =
        '--location',
        '--silent',
        '--max-time', $!timeout,
        '--max-redirs', $!max-redirect,
        '--user-agent', $!agent,
    ;
    self!translate-headers(%headers, @options);
    @options.push("--insecure") unless $.verify-ssl;
    if %opts<content>:exists {
        my $content = "";
        if %opts<content> ~~ Callable {
            while %opts<content>() -> $chunk {
                $content ~= $chunk;
            }
        } else {
            $content = %opts<content>;
        }
        @options.push('--data', $content);
    }
    |@options;
}

method !translate-headers(%headers, @options is raw) {
    for %headers.kv -> $field, $value {
        if $value ~~ Positional {
            @options.push( $value.map({|("-H", "$field:$_")}) );
        } else {
            @options.push("-H", "$field:$value");
        }
    }
}
