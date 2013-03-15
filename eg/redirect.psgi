use Chaco;

get '/' => sub {
	redirect '/to';
};

get '/to' => sub {
	res->content_type('text/plain');
	res->body('to');
};

run;
