use strict;
use warnings;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;

BEGIN { $ENV{'PLACK_ENV'} = 'development'; }

my $app = do {
	use Chaco;

	xslate_opt cache => 0;

	get '/' => sub { text \q{top} };

	get '/blog/{year:[0-9]+}/:month' => sub {
		text \q{<: $year :>-<: $month :>'s blog}, {
			year  => param->get('year'),
			month => param->get('month'),
		};
	};

	post '/comment' => sub {
		text \q{posted '<: $body :>'}, {
			body => param->get('body'),
		};
	};

	any '/any'  => sub { text \q{any} };

	get '/tmpl' => sub { tmpl 'tmpl.tx' };
	get '/json' => sub { json { hoge => 'fuga' } };
	get '/text' => sub { text 'text.tx' };

	get '/redirect_from'     => sub { redirect '/redirect_to' };
	get '/redirect_from_301' => sub { redirect '/redirect_to', 301 };

	get '/.error' => sub {
		return r404 unless (stash->{is_forward});
		text \q{error};
	};

	get '/error/:is_error' => sub {
		if (param->get('is_error')) {
			stash->{is_forward} = 1;
			forward '/.error';
		} else {
			text \q{not error};
		}
	};

	get '/internal_server_error' => sub { r500 };

	get '/ja_tmpl' => sub { text 'ja.tx' };

	get '/ja_query' => sub { text \q{<: $param :>}, { param => param('query')->get('param') } };

	post '/ja_body' => sub { text \q{<: $param :>}, { param => param('body')->get('param') } };

	get '/ja_args/:param' => sub { text \q{<: $param :>}, { param => param('args')->get('param') } };

	get '/unknown_source' => sub { param('unknown_source') };

	run;
};

test_psgi $app, sub {
	my $cb = shift;
	do {
		my $res = $cb->(GET '/');
		is $res->code, 200;
		is $res->header('Content-Type'), 'text/plain';
		is $res->content, 'top';
	};
	do {
		my $res = $cb->(POST '/');
		is $res->code, 404;
		is $res->content, 'Not Found';
	};
	do {
		my $res = $cb->(GET '/blog/2010/03');
		is $res->code, 200;
		is $res->header('Content-Type'), 'text/plain';
		is $res->content, "2010-03's blog";
	};
	do {
		my $res = $cb->(GET '/blog/sample/03');
		is $res->code, 404;
		is $res->content, 'Not Found';
	};
	do {
		my $res= $cb->(POST '/comment', [ body => 'hi' ]);
		is $res->code, 200;
		is $res->header('Content-Type'), 'text/plain';
		is $res->content, "posted 'hi'";
	};
	do {
		my $res = $cb->(GET '/any');
		is $res->code, 200;
		is $res->header('Content-Type'), 'text/plain';
		is $res->content, 'any';
	};
	do {
		my $res = $cb->(POST '/any');
		is $res->code, 200;
		is $res->header('Content-Type'), 'text/plain';
		is $res->content, 'any';
	};
	do {
		my $res = $cb->(GET '/tmpl');
		is $res->code, 200;
		is $res->header('Content-Type'), 'text/html';
		is $res->content, "tmpl\n\n";
	};
	do {
		my $res = $cb->(GET '/json');
		is $res->code, 200;
		is $res->header('Content-Type'), 'application/json';
		is $res->content, '{"hoge":"fuga"}';
	};
	do {
		my $res = $cb->(GET '/text');
		is $res->code, 200;
		is $res->header('Content-Type'), 'text/plain';
		is $res->content, "text\n\n";
	};
	do {
		my $res = $cb->(GET '/redirect_from');
		is $res->code, 302;
		is $res->header('Location'), '/redirect_to';
	};
	do {
		my $res = $cb->(GET '/redirect_from_301');
		is $res->code, 301;
		is $res->header('Location'), '/redirect_to';
	};
	do {
		my $res = $cb->(GET '/.error');
		is $res->code, 404;
		is $res->content, 'Not Found';
	};
	do {
		my $res = $cb->(GET '/error/0');
		is $res->code, 200;
		is $res->header('Content-Type'), 'text/plain';
		is $res->content, 'not error';
	};
	do {
		my $res = $cb->(GET '/error/1');
		is $res->code, 200;
		is $res->header('Content-Type'), 'text/plain';
		is $res->content, 'error';
	};
	do {
		my $res = $cb->(GET '/internal_server_error');
		is $res->code, 500;
		is $res->content, 'Internal Server Error';
	};
	do {
		my $res = $cb->(GET '/ja_tmpl');
		is $res->code, 200;
		is $res->header('Content-Type'), 'text/plain';
		is $res->content, "こんにちは1\n\n";
	};
	do {
		my $res = $cb->(GET '/ja_query?param=こんにちは2');
		is $res->code, 200;
		is $res->header('Content-Type'), 'text/plain';
		is $res->content, 'こんにちは2';
	};
	do {
		my $res = $cb->(POST '/ja_body', [param => 'こんにちは3']);
		is $res->code, 200;
		is $res->header('Content-Type'), 'text/plain';
		is $res->content, 'こんにちは3';
	};
	do {
		my $res = $cb->(GET '/ja_args/こんにちは4');
		is $res->code, 200;
		is $res->header('Content-Type'), 'text/plain';
		is $res->content, 'こんにちは4';
	};
	do {
		my $res = $cb->(GET '/unknown_source');
		is $res->code, 500;
	};
};

done_testing;

__DATA__

@@ tmpl.tx
tmpl

@@ text.tx
text

@@ ja.tx
こんにちは1

