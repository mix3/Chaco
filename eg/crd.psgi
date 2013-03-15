use Chaco;

my $kv = {};

get '/' => sub {
  my @list = ();

  push @list, map {
    { k => $_, v => $kv->{$_} }
  } sort {
    $b <=> $a
  } keys %$kv;

  tmpl 'index.tx', { list => \@list };
};

post '/create' => sub {
  my @k = sort { $b <=> $a } keys %$kv;
  my $k = ($k[0]) ? $k[0] + 1 : 1 ;
  $kv->{$k} = param->{'content'};
  redirect '/';
};

post '/delete' => sub {
  if (my $k = param->{'k'}) {
    delete $kv->{$k};
  }
  redirect '/';
};

run;

__DATA__

@@ index.tx
: cascade layouts::base
: around title -> { "Chaco Minimum Framework!" }
: around content -> {
  <form action="/create" method="post">
    <textarea name="content"></textarea><br />
    <input type="submit" value="CREATE" />
  </form>
  <hr />
  <table>
  : for $list -> $row {
    <tr>
      <td>
        [<: $row.k :>]
      </td>
      <td>
        <: $row.v :>
      </td>
      <td>
        <form action="/delete" method="post">
          <input type="hidden" name="k" value="<: $row.k :>" />
          <input type="submit" value="DEL" />
        </form>
      </td>
    </tr>
  : }
  </table>
: }

@@ layouts/base.tx
<!DOCTYPE html>
<html>
  <head><title><: block title -> {} :></title></head>
  <body>
   : block content -> {}
  </body>
</html>
