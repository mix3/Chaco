use strict;
use warnings;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;

BEGIN { $ENV{'PLACK_ENV'} = 'development'; }

my $app = do {
	use Chaco;
	use FindBin;

	xslate_opt
		cache    => 0,
		function => { 'sprintf' => sub { sprintf(shift, @_) } },
		path     => [ "$FindBin::Bin/tmpl" ];

	get '/' => sub { tmpl 'index.tx' };

	get '/sprintf' => sub { text \q{<: sprintf("%d => %s", $d, $s) | raw :>}, { d => 100, s => 'おは' } };

	run;
};

test_psgi $app, sub {
	my $cb = shift;
	do {
		my $res = $cb->(GET '/');
		is $res->code, 200;
		is $res->header('Content-Type'), 'text/html';
		is $res->content, "こんにちは\n";
	};
	do {
		my $res = $cb->(GET '/sprintf');
		is $res->code, 200;
		is $res->content, '100 => おは';
	};
};

done_testing;
