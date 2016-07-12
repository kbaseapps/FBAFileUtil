package DataFileUtil::DataFileUtilClient;

use JSON::RPC::Client;
use POSIX;
use strict;
use Data::Dumper;
use URI;
use Bio::KBase::Exceptions;
use Time::HiRes;
my $get_time = sub { time, 0 };
eval {
    require Time::HiRes;
    $get_time = sub { Time::HiRes::gettimeofday() };
};

use Bio::KBase::AuthToken;

# Client version should match Impl version
# This is a Semantic Version number,
# http://semver.org
our $VERSION = "0.1.0";

=head1 NAME

DataFileUtil::DataFileUtilClient

=head1 DESCRIPTION


Contains utilities for saving and retrieving data to and from KBase data
services. Requires Shock 0.9.6+ and Workspace Service 0.4.1+.


=cut

sub new
{
    my($class, $url, @args) = @_;
    
    if (!defined($url))
    {
	$url = 'https://kbase.us/services/njs_wrapper';
    }

    my $self = {
	client => DataFileUtil::DataFileUtilClient::RpcClient->new,
	url => $url,
	headers => [],
    };
    my %arg_hash = @args;
    my $async_job_check_time = 5.0;
    if (exists $arg_hash{"async_job_check_time_ms"}) {
        $async_job_check_time = $arg_hash{"async_job_check_time_ms"} / 1000.0;
    }
    $self->{async_job_check_time} = $async_job_check_time;
    my $service_version = 'a47de0273593b2f9999f3506af179effab832220';
    if (exists $arg_hash{"service_version"}) {
        $service_version = $arg_hash{"async_version"};
    }
    $self->{service_version} = $service_version;

    chomp($self->{hostname} = `hostname`);
    $self->{hostname} ||= 'unknown-host';

    #
    # Set up for propagating KBRPC_TAG and KBRPC_METADATA environment variables through
    # to invoked services. If these values are not set, we create a new tag
    # and a metadata field with basic information about the invoking script.
    #
    if ($ENV{KBRPC_TAG})
    {
	$self->{kbrpc_tag} = $ENV{KBRPC_TAG};
    }
    else
    {
	my ($t, $us) = &$get_time();
	$us = sprintf("%06d", $us);
	my $ts = strftime("%Y-%m-%dT%H:%M:%S.${us}Z", gmtime $t);
	$self->{kbrpc_tag} = "C:$0:$self->{hostname}:$$:$ts";
    }
    push(@{$self->{headers}}, 'Kbrpc-Tag', $self->{kbrpc_tag});

    if ($ENV{KBRPC_METADATA})
    {
	$self->{kbrpc_metadata} = $ENV{KBRPC_METADATA};
	push(@{$self->{headers}}, 'Kbrpc-Metadata', $self->{kbrpc_metadata});
    }

    if ($ENV{KBRPC_ERROR_DEST})
    {
	$self->{kbrpc_error_dest} = $ENV{KBRPC_ERROR_DEST};
	push(@{$self->{headers}}, 'Kbrpc-Errordest', $self->{kbrpc_error_dest});
    }

    #
    # This module requires authentication.
    #
    # We create an auth token, passing through the arguments that we were (hopefully) given.

    {
	my $token = Bio::KBase::AuthToken->new(@args);
	
	if (!$token->error_message)
	{
	    $self->{token} = $token->token;
	    $self->{client}->{token} = $token->token;
	}
    }

    my $ua = $self->{client}->ua;	 
    my $timeout = $ENV{CDMI_TIMEOUT} || (30 * 60);	 
    $ua->timeout($timeout);
    bless $self, $class;
    #    $self->_validate_version();
    return $self;
}

sub _check_job {
    my($self, @args) = @_;
# Authentication: ${method.authentication}
    if ((my $n = @args) != 1) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
                                   "Invalid argument count for function _check_job (received $n, expecting 1)");
    }
    {
        my($job_id) = @args;
        my @_bad_arguments;
        (!ref($job_id)) or push(@_bad_arguments, "Invalid type for argument 0 \"job_id\" (it should be a string)");
        if (@_bad_arguments) {
            my $msg = "Invalid arguments passed to _check_job:\n" . join("", map { "\t$_\n" } @_bad_arguments);
            Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
                                   method_name => '_check_job');
        }
    }
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "DataFileUtil._check_job",
        params => \@args});
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
                           code => $result->content->{error}->{code},
                           method_name => '_check_job',
                           data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
                          );
        } else {
            return $result->result->[0];
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method _check_job",
                        status_line => $self->{client}->status_line,
                        method_name => '_check_job');
    }
}




=head2 shock_to_file

  $out = $obj->shock_to_file($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a DataFileUtil.ShockToFileParams
$out is a DataFileUtil.ShockToFileOutput
ShockToFileParams is a reference to a hash where the following keys are defined:
	shock_id has a value which is a string
	file_path has a value which is a string
	unpack has a value which is a DataFileUtil.boolean
boolean is an int
ShockToFileOutput is a reference to a hash where the following keys are defined:
	node_file_name has a value which is a string
	attributes has a value which is a reference to a hash where the key is a string and the value is an UnspecifiedObject, which can hold any non-null object

</pre>

=end html

=begin text

$params is a DataFileUtil.ShockToFileParams
$out is a DataFileUtil.ShockToFileOutput
ShockToFileParams is a reference to a hash where the following keys are defined:
	shock_id has a value which is a string
	file_path has a value which is a string
	unpack has a value which is a DataFileUtil.boolean
boolean is an int
ShockToFileOutput is a reference to a hash where the following keys are defined:
	node_file_name has a value which is a string
	attributes has a value which is a reference to a hash where the key is a string and the value is an UnspecifiedObject, which can hold any non-null object


=end text

=item Description

Download a file from Shock.

=back

=cut

sub shock_to_file
{
    my($self, @args) = @_;
    my $job_id = $self->_shock_to_file_submit(@args);
    while (1) {
        Time::HiRes::sleep($self->{async_job_check_time});
        my $job_state_ref = $self->_check_job($job_id);
        if ($job_state_ref->{"finished"} != 0) {
            if (!exists $job_state_ref->{"result"}) {
                $job_state_ref->{"result"} = [];
            }
            return wantarray ? @{$job_state_ref->{"result"}} : $job_state_ref->{"result"}->[0];
        }
    }
}

sub _shock_to_file_submit {
    my($self, @args) = @_;
# Authentication: required
    if ((my $n = @args) != 1) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
                                   "Invalid argument count for function shock_to_file_async (received $n, expecting 1)");
    }
    {
        my($params) = @args;
        my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
            my $msg = "Invalid arguments passed to _shock_to_file_submit:\n" . join("", map { "\t$_\n" } @_bad_arguments);
            Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
                                   method_name => '_shock_to_file_submit');
        }
    }
    my $context = undef;
    if ($self->{service_version}) {
        $context = {'service_ver' => $self->{service_version}};
    }
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "DataFileUtil._shock_to_file_submit",
        params => \@args}, context => $context);
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
                           code => $result->content->{error}->{code},
                           method_name => '_shock_to_file_submit',
                           data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
            );
        } else {
            return $result->result->[0];  # job_id
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method _shock_to_file_submit",
                        status_line => $self->{client}->status_line,
                        method_name => '_shock_to_file_submit');
    }
}

 


=head2 file_to_shock

  $out = $obj->file_to_shock($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a DataFileUtil.FileToShockParams
$out is a DataFileUtil.FileToShockOutput
FileToShockParams is a reference to a hash where the following keys are defined:
	file_path has a value which is a string
	attributes has a value which is a reference to a hash where the key is a string and the value is an UnspecifiedObject, which can hold any non-null object
	make_handle has a value which is a DataFileUtil.boolean
	gzip has a value which is a DataFileUtil.boolean
boolean is an int
FileToShockOutput is a reference to a hash where the following keys are defined:
	shock_id has a value which is a string
	handle has a value which is a DataFileUtil.Handle
Handle is a reference to a hash where the following keys are defined:
	hid has a value which is a string
	file_name has a value which is a string
	id has a value which is a string
	url has a value which is a string
	type has a value which is a string
	remote_md5 has a value which is a string

</pre>

=end html

=begin text

$params is a DataFileUtil.FileToShockParams
$out is a DataFileUtil.FileToShockOutput
FileToShockParams is a reference to a hash where the following keys are defined:
	file_path has a value which is a string
	attributes has a value which is a reference to a hash where the key is a string and the value is an UnspecifiedObject, which can hold any non-null object
	make_handle has a value which is a DataFileUtil.boolean
	gzip has a value which is a DataFileUtil.boolean
boolean is an int
FileToShockOutput is a reference to a hash where the following keys are defined:
	shock_id has a value which is a string
	handle has a value which is a DataFileUtil.Handle
Handle is a reference to a hash where the following keys are defined:
	hid has a value which is a string
	file_name has a value which is a string
	id has a value which is a string
	url has a value which is a string
	type has a value which is a string
	remote_md5 has a value which is a string


=end text

=item Description

Load a file to Shock.

=back

=cut

sub file_to_shock
{
    my($self, @args) = @_;
    my $job_id = $self->_file_to_shock_submit(@args);
    while (1) {
        Time::HiRes::sleep($self->{async_job_check_time});
        my $job_state_ref = $self->_check_job($job_id);
        if ($job_state_ref->{"finished"} != 0) {
            if (!exists $job_state_ref->{"result"}) {
                $job_state_ref->{"result"} = [];
            }
            return wantarray ? @{$job_state_ref->{"result"}} : $job_state_ref->{"result"}->[0];
        }
    }
}

sub _file_to_shock_submit {
    my($self, @args) = @_;
# Authentication: required
    if ((my $n = @args) != 1) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
                                   "Invalid argument count for function file_to_shock_async (received $n, expecting 1)");
    }
    {
        my($params) = @args;
        my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
            my $msg = "Invalid arguments passed to _file_to_shock_submit:\n" . join("", map { "\t$_\n" } @_bad_arguments);
            Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
                                   method_name => '_file_to_shock_submit');
        }
    }
    my $context = undef;
    if ($self->{service_version}) {
        $context = {'service_ver' => $self->{service_version}};
    }
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "DataFileUtil._file_to_shock_submit",
        params => \@args}, context => $context);
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
                           code => $result->content->{error}->{code},
                           method_name => '_file_to_shock_submit',
                           data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
            );
        } else {
            return $result->result->[0];  # job_id
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method _file_to_shock_submit",
                        status_line => $self->{client}->status_line,
                        method_name => '_file_to_shock_submit');
    }
}

 


=head2 copy_shock_node

  $out = $obj->copy_shock_node($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a DataFileUtil.CopyShockNodeParams
$out is a DataFileUtil.CopyShockNodeOutput
CopyShockNodeParams is a reference to a hash where the following keys are defined:
	shock_id has a value which is a string
	make_handle has a value which is a DataFileUtil.boolean
boolean is an int
CopyShockNodeOutput is a reference to a hash where the following keys are defined:
	shock_id has a value which is a string
	handle has a value which is a DataFileUtil.Handle
Handle is a reference to a hash where the following keys are defined:
	hid has a value which is a string
	file_name has a value which is a string
	id has a value which is a string
	url has a value which is a string
	type has a value which is a string
	remote_md5 has a value which is a string

</pre>

=end html

=begin text

$params is a DataFileUtil.CopyShockNodeParams
$out is a DataFileUtil.CopyShockNodeOutput
CopyShockNodeParams is a reference to a hash where the following keys are defined:
	shock_id has a value which is a string
	make_handle has a value which is a DataFileUtil.boolean
boolean is an int
CopyShockNodeOutput is a reference to a hash where the following keys are defined:
	shock_id has a value which is a string
	handle has a value which is a DataFileUtil.Handle
Handle is a reference to a hash where the following keys are defined:
	hid has a value which is a string
	file_name has a value which is a string
	id has a value which is a string
	url has a value which is a string
	type has a value which is a string
	remote_md5 has a value which is a string


=end text

=item Description

Copy a Shock node.

=back

=cut

sub copy_shock_node
{
    my($self, @args) = @_;
    my $job_id = $self->_copy_shock_node_submit(@args);
    while (1) {
        Time::HiRes::sleep($self->{async_job_check_time});
        my $job_state_ref = $self->_check_job($job_id);
        if ($job_state_ref->{"finished"} != 0) {
            if (!exists $job_state_ref->{"result"}) {
                $job_state_ref->{"result"} = [];
            }
            return wantarray ? @{$job_state_ref->{"result"}} : $job_state_ref->{"result"}->[0];
        }
    }
}

sub _copy_shock_node_submit {
    my($self, @args) = @_;
# Authentication: required
    if ((my $n = @args) != 1) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
                                   "Invalid argument count for function copy_shock_node_async (received $n, expecting 1)");
    }
    {
        my($params) = @args;
        my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
            my $msg = "Invalid arguments passed to _copy_shock_node_submit:\n" . join("", map { "\t$_\n" } @_bad_arguments);
            Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
                                   method_name => '_copy_shock_node_submit');
        }
    }
    my $context = undef;
    if ($self->{service_version}) {
        $context = {'service_ver' => $self->{service_version}};
    }
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "DataFileUtil._copy_shock_node_submit",
        params => \@args}, context => $context);
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
                           code => $result->content->{error}->{code},
                           method_name => '_copy_shock_node_submit',
                           data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
            );
        } else {
            return $result->result->[0];  # job_id
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method _copy_shock_node_submit",
                        status_line => $self->{client}->status_line,
                        method_name => '_copy_shock_node_submit');
    }
}

 


=head2 versions

  $wsver, $shockver = $obj->versions()

=over 4

=item Parameter and return types

=begin html

<pre>
$wsver is a string
$shockver is a string

</pre>

=end html

=begin text

$wsver is a string
$shockver is a string


=end text

=item Description

Get the versions of the Workspace service and Shock service.

=back

=cut

sub versions
{
    my($self, @args) = @_;
    my $job_id = $self->_versions_submit(@args);
    while (1) {
        Time::HiRes::sleep($self->{async_job_check_time});
        my $job_state_ref = $self->_check_job($job_id);
        if ($job_state_ref->{"finished"} != 0) {
            if (!exists $job_state_ref->{"result"}) {
                $job_state_ref->{"result"} = [];
            }
            return wantarray ? @{$job_state_ref->{"result"}} : $job_state_ref->{"result"}->[0];
        }
    }
}

sub _versions_submit {
    my($self, @args) = @_;
# Authentication: none
    if ((my $n = @args) != 0) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
                                   "Invalid argument count for function versions_async (received $n, expecting 0)");
    }
    my $context = undef;
    if ($self->{service_version}) {
        $context = {'service_ver' => $self->{service_version}};
    }
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "DataFileUtil._versions_submit",
        params => \@args}, context => $context);
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
                           code => $result->content->{error}->{code},
                           method_name => '_versions_submit',
                           data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
            );
        } else {
            return $result->result->[0];  # job_id
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method _versions_submit",
                        status_line => $self->{client}->status_line,
                        method_name => '_versions_submit');
    }
}

 
  

sub version {
    my ($self) = @_;
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "DataFileUtil.version",
        params => [],
    });
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(
                error => $result->error_message,
                code => $result->content->{code},
                method_name => 'versions',
            );
        } else {
            return wantarray ? @{$result->result} : $result->result->[0];
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(
            error => "Error invoking method versions",
            status_line => $self->{client}->status_line,
            method_name => 'versions',
        );
    }
}

sub _validate_version {
    my ($self) = @_;
    my $svr_version = $self->version();
    my $client_version = $VERSION;
    my ($cMajor, $cMinor) = split(/\./, $client_version);
    my ($sMajor, $sMinor) = split(/\./, $svr_version);
    if ($sMajor != $cMajor) {
        Bio::KBase::Exceptions::ClientServerIncompatible->throw(
            error => "Major version numbers differ.",
            server_version => $svr_version,
            client_version => $client_version
        );
    }
    if ($sMinor < $cMinor) {
        Bio::KBase::Exceptions::ClientServerIncompatible->throw(
            error => "Client minor version greater than Server minor version.",
            server_version => $svr_version,
            client_version => $client_version
        );
    }
    if ($sMinor > $cMinor) {
        warn "New client version available for DataFileUtil::DataFileUtilClient\n";
    }
    if ($sMajor == 0) {
        warn "DataFileUtil::DataFileUtilClient version is $svr_version. API subject to change.\n";
    }
}

=head1 TYPES



=head2 boolean

=over 4



=item Description

A boolean - 0 for false, 1 for true.
@range (0, 1)


=item Definition

=begin html

<pre>
an int
</pre>

=end html

=begin text

an int

=end text

=back



=head2 Handle

=over 4



=item Description

A handle for a file stored in Shock.
hid - the id of the handle in the Handle Service that references this
   shock node
id - the id for the shock node
url - the url of the shock server
type - the type of the handle. This should always be ���shock���.
file_name - the name of the file
remote_md5 - the md5 digest of the file.


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
hid has a value which is a string
file_name has a value which is a string
id has a value which is a string
url has a value which is a string
type has a value which is a string
remote_md5 has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
hid has a value which is a string
file_name has a value which is a string
id has a value which is a string
url has a value which is a string
type has a value which is a string
remote_md5 has a value which is a string


=end text

=back



=head2 ShockToFileParams

=over 4



=item Description

Input for the shock_to_file function.

Required parameters:
shock_id - the ID of the Shock node.
file_path - the location to save the file output. If this is a
    directory, the file will be named as per the filename in Shock.

Optional parameters:
unpack - if the file is compressed and / or a file bundle, it will be
    decompressed and unbundled into the directory containing the
    original output file. unpack supports gzip, bzip2, tar, and zip
    files. Default false. Currently unsupported.


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
shock_id has a value which is a string
file_path has a value which is a string
unpack has a value which is a DataFileUtil.boolean

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
shock_id has a value which is a string
file_path has a value which is a string
unpack has a value which is a DataFileUtil.boolean


=end text

=back



=head2 ShockToFileOutput

=over 4



=item Description

Output from the shock_to_file function.

   node_file_name - the filename of the file stored in Shock.
   attributes - the file attributes, if any, stored in Shock.


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
node_file_name has a value which is a string
attributes has a value which is a reference to a hash where the key is a string and the value is an UnspecifiedObject, which can hold any non-null object

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
node_file_name has a value which is a string
attributes has a value which is a reference to a hash where the key is a string and the value is an UnspecifiedObject, which can hold any non-null object


=end text

=back



=head2 FileToShockParams

=over 4



=item Description

Input for the file_to_shock function.

Required parameters:
file_path - the location of the file to load to Shock.

Optional parameters:
attributes - user-specified attributes to save to the Shock node along
    with the file.
make_handle - make a Handle Service handle for the shock node. Default
    false.
gzip - gzip the file before loading it to Shock. This will create a
    file_path.gz file prior to upload. Default false.


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
file_path has a value which is a string
attributes has a value which is a reference to a hash where the key is a string and the value is an UnspecifiedObject, which can hold any non-null object
make_handle has a value which is a DataFileUtil.boolean
gzip has a value which is a DataFileUtil.boolean

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
file_path has a value which is a string
attributes has a value which is a reference to a hash where the key is a string and the value is an UnspecifiedObject, which can hold any non-null object
make_handle has a value which is a DataFileUtil.boolean
gzip has a value which is a DataFileUtil.boolean


=end text

=back



=head2 FileToShockOutput

=over 4



=item Description

Output of the file_to_shock function.

    shock_id - the ID of the new Shock node.
    handle - the new handle, if created. Null otherwise.


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
shock_id has a value which is a string
handle has a value which is a DataFileUtil.Handle

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
shock_id has a value which is a string
handle has a value which is a DataFileUtil.Handle


=end text

=back



=head2 CopyShockNodeParams

=over 4



=item Description

Input for the copy_shock_node function.

       Required parameters:
       shock_id - the id of the node to copy.
       
       Optional parameters:
       make_handle - make a Handle Service handle for the shock node. Default
           false.


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
shock_id has a value which is a string
make_handle has a value which is a DataFileUtil.boolean

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
shock_id has a value which is a string
make_handle has a value which is a DataFileUtil.boolean


=end text

=back



=head2 CopyShockNodeOutput

=over 4



=item Description

Output of the copy_shock_node function.

 shock_id - the id of the new Shock node.
 handle - the new handle, if created. Null otherwise.


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
shock_id has a value which is a string
handle has a value which is a DataFileUtil.Handle

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
shock_id has a value which is a string
handle has a value which is a DataFileUtil.Handle


=end text

=back



=cut

package DataFileUtil::DataFileUtilClient::RpcClient;
use base 'JSON::RPC::Client';
use POSIX;
use strict;

#
# Override JSON::RPC::Client::call because it doesn't handle error returns properly.
#

sub call {
    my ($self, $uri, $headers, $obj) = @_;
    my $result;


    {
	if ($uri =~ /\?/) {
	    $result = $self->_get($uri);
	}
	else {
	    Carp::croak "not hashref." unless (ref $obj eq 'HASH');
	    $result = $self->_post($uri, $headers, $obj);
	}

    }

    my $service = $obj->{method} =~ /^system\./ if ( $obj );

    $self->status_line($result->status_line);

    if ($result->is_success) {

        return unless($result->content); # notification?

        if ($service) {
            return JSON::RPC::ServiceObject->new($result, $self->json);
        }

        return JSON::RPC::ReturnObject->new($result, $self->json);
    }
    elsif ($result->content_type eq 'application/json')
    {
        return JSON::RPC::ReturnObject->new($result, $self->json);
    }
    else {
        return;
    }
}


sub _post {
    my ($self, $uri, $headers, $obj) = @_;
    my $json = $self->json;

    $obj->{version} ||= $self->{version} || '1.1';

    if ($obj->{version} eq '1.0') {
        delete $obj->{version};
        if (exists $obj->{id}) {
            $self->id($obj->{id}) if ($obj->{id}); # if undef, it is notification.
        }
        else {
            $obj->{id} = $self->id || ($self->id('JSON::RPC::Client'));
        }
    }
    else {
        # $obj->{id} = $self->id if (defined $self->id);
	# Assign a random number to the id if one hasn't been set
	$obj->{id} = (defined $self->id) ? $self->id : substr(rand(),2);
    }

    my $content = $json->encode($obj);

    $self->ua->post(
        $uri,
        Content_Type   => $self->{content_type},
        Content        => $content,
        Accept         => 'application/json',
	@$headers,
	($self->{token} ? (Authorization => $self->{token}) : ()),
    );
}



1;
