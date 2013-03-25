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
