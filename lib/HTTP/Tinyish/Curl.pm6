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
has @!tempfiles; # cleanup each request

method !tempfile() {
    my ($file, $fh) = tempfile(:!unlink);
    @!tempfiles.push( [$file, $fh] );
    $file, $fh;
}
method !cleanup-tempfiles() {
    for @!tempfiles -> $tempfile {
        $tempfile[0].IO.unlink if $tempfile[0].defined && $tempfile[0].IO.e;
        $tempfile[1].close     if $tempfile[1].defined;
    }
    @!tempfiles = ();
}

method request($method, $url, *%opts) {
    LEAVE { self!cleanup-tempfiles }
    my ($out-file, $out-fh) = self!tempfile;
    my ($err-file, $err-fh) = self!tempfile;
    my ($header-file, $header-fh) = self!tempfile;
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
    LEAVE { self!cleanup-tempfiles }
    my ($out-file, $out-fh) = self!tempfile;
    my ($err-file, $err-fh) = self!tempfile;
    my ($header-file, $header-fh) = self!tempfile;
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

method !translate-headers(%headers, @options) {
    for %headers.kv -> $field, $value {
        if $value ~~ Positional {
            @options.append( $value.map({|("-H", "$field:$_")}) );
        } else {
            @options.push("-H", "$field:$value");
        }
    }
}
