use Chaco;

get '/:echo' => sub {
	res->content_type('text/plain');
	res->body(param->{'echo'});
};

run;
