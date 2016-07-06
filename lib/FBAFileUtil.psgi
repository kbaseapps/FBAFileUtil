use FBAFileUtil::FBAFileUtilImpl;

use FBAFileUtil::FBAFileUtilServer;
use Plack::Middleware::CrossOrigin;



my @dispatch;

{
    my $obj = FBAFileUtil::FBAFileUtilImpl->new;
    push(@dispatch, 'FBAFileUtil' => $obj);
}


my $server = FBAFileUtil::FBAFileUtilServer->new(instance_dispatch => { @dispatch },
				allow_get => 0,
			       );

my $handler = sub { $server->handle_input(@_) };

$handler = Plack::Middleware::CrossOrigin->wrap( $handler, origins => "*", headers => "*");
