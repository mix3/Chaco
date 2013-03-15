package Chaco;

use Router::Simple::Sinatraish;
use Plack::Request;
use Text::Xslate;
use Data::Section::Simple;

use parent 'Exporter';

our @EXPORT = qw/run req res tmpl redirect uri_for param/;

my $req, $res, $tx, %args;

sub import {
	my $class = shift;
	strict->import;
	warnings->import;
	utf8->import;
	Router::Simple::Sinatraish->export_to_level(1);
	$class->export_to_level(1);
}

sub run {
	my ($class) = caller(0);

	$tx = Text::Xslate->new(
		path => [ Data::Section::Simple->new($class)->get_data_section() ],
	);

	my $app = sub {
		my $env = shift;
		$req = Plack::Request->new($env);
		$res = $req->new_response;
		$res->status(200);
		$res->content_type('text/html');
		if (my $route = $class->router->match($req->env)) {
			(%args) = map { $_ => $route->{$_} } grep { $_ ne 'code' } keys %$route;
			eval {
				$route->{code}->();
			};
			if ($@) {
				$res->status(500);
				$res->body('Internal Server Error');
			}
		} else {
			$res->status(404);
			$res->body('Not Found');
		}
		$res->finalize;
	};

	if ($ENV{'PLACK_ENV'}) {
		$app;
	} else {
		require Plack::Runner;
		my $runner = Plack::Runner->new;
		$runner->parse_options(@ARGV);
		$runner->run($app);
	}
}

sub req  { $req }
sub res  { $res }
sub tmpl {
	my $render = $tx->render(@_);
	$res->header(['Content-Length' => length $render ]);
	$res->body($render);
}

sub param {
	my $source = shift;
	unless ($source) {
		Hash::MultiValue->new(
			$req->query_parameters->flatten,
			$req->body_parameters->flatten,
			%args,
		);
	} elsif ($source eq 'query') {
		$req->query_parameters;
	} elsif ($source eq 'body') {
		$req->body_parameters;
	} elsif ($source eq 'args') {
		Hash::MultiValue->new(%args);
	} else {
		Hash::MultiValue->new();
	}
}

sub redirect { $res->redirect(@_) };

sub uri_for {
	my ($path, $args) = @_;
	my $uri = $req->base;
	$uri->path($uri->path . $path);
	$uri->query_form(@$args) if ($args);
	$uri;
}

1;

=head1 NAME

Chaco

=head1 SYNOPSIS

    use Chaco;
    
    get '/' => sub {
      tmpl 'index.tx', {};
    };
    
    run;
    
    __DATA__
    
    @@ index.tx
    : cascade layouts::base
    : around title -> { "Chaco" }
    : around content -> {
      Hello World!
    : }
    
    @@ layouts/base.tx
    <!DOCTYPE html>
    <html>
      <head><title><: block title -> {} :></title></head>
      <body>
        : block content -> {}
      </body>
    </html>

=head1 EXPORTABLE FUNCTIONS

=head2 get

=head2 post

=head2 any

=head2 req

=head2 res

=head2 tmpl

=head2 redirect

=head2 uri_for

=head2 param

=head2 run

=head1 SEE ALSO

L<Router::Simple::Sinatraish> L<Plack::Request> L<Plack::Response> L<Text::Xslate> L<Data::Section::Simple>

=cut
