package FBAFileUtil::FBAFileUtilImpl;
use strict;
use Bio::KBase::Exceptions;
# Use Semantic Versioning (2.0.0-rc.1)
# http://semver.org 
our $VERSION = '0.1.0';
our $GIT_URL = 'https://github.com/kbaseapps/FBAFileUtil';
our $GIT_COMMIT_HASH = 'bafcacd40a161094f96925a52776dea311c92c43';

=head1 NAME

FBAFileUtil

=head1 DESCRIPTION



=cut

#BEGIN_HEADER
use Cwd;

use File::Copy;
use File::Basename;

use Config::IniFiles;
use Data::UUID;

use Data::Dumper;

use Bio::KBase::workspace::Client;
use DataFileUtil::DataFileUtilClient;

# after submitting a system call, check the return code
sub check_system_call
{
    my $return_code = shift;

    if ($return_code == -1) {
        print "Failed to execute command.\n";
        die "Failed to execute command.";
    }
    elsif ($return_code & 127) {
        printf "\ncommand died with signal %d, %s coredump\n",
            ($return_code & 127),  ($return_code & 128) ? 'with' : 'without';
        die "Error running command.";
    }
    else {
        my $code = $return_code >> 8;
        print "\ncommand exited with value $code \n", ;
        if( $code != 0) {
            die "Error running command.";
        }
    }
    return();
}

# class method because it requires scratch config, this creates a new unique
# area for running a script
sub set_working_dir
{
    my $self = shift;

    my $ugen = Data::UUID->new;
    my $uuid_str = $ugen->create_str();
    my $path = $self->{'scratch'}.'/'.$uuid_str;

    mkdir $path;
    chdir $path;

    return $path;
}

# go through the a directory and get result files.  Probably a better perl way to
# do this, but it works
sub get_result_files
{
    my $path = shift;

    opendir(DIR, $path);
    my @files = readdir(DIR);
    closedir(DIR);

    my @filtered_files = ();
    my $file;
    foreach $file (@files) {
        next if $file eq '.' or $file eq '..';
        push @filtered_files, $file;
        print("  -> generated file: $file\n");
    }
    return @filtered_files;
}

sub get_ws_obj_ref
{
    my $self = shift;
    my $ws_name = shift;
    my $obj = shift;

    my $ws = new Bio::KBase::workspace::Client($self->{'workspace-url'});
    my $info = $ws->get_object_info_new({ objects=>[ { ref=>$ws_name.'/'.$obj } ] })->[0];

    return "$info->[6]/$info->[0]/$info->[4]";
}

# give a File object, which can either have a 'path' defined or a shock_id.
# if the shock_id is defined and is a nonemtpy string, then get the file from shock, 
# and return the path to the file.  Otherwise, just return what is in 'path'
sub get_file_path
{
    my $self = shift;
    my $file = shift;
    my $target_dir = shift;

    if(exists $file->{shock_id} && $file->{shock_id} ne "") {
        # file has a shock id, so try to fetch it 
        my $dataUtil = DataFileUtil::DataFileUtilClient->new($self->{callbackURL});

        my $f = $dataUtil->shock_to_file({ 
                                shock_id=>$file->{shock_id},
                                file_path=>$target_dir,
                                unpack=>0
                            });
        return $target_dir.'/'.$f->{node_file_name};
    }

    return $file->{path};
}

sub load_to_shock
{
    my $self = shift;
    my $file_path = shift;
    my $dataUtil = DataFileUtil::DataFileUtilClient->new($self->{callbackURL});
    my $f = $dataUtil->file_to_shock({ 
                                file_path=>$file_path,
                                #attributes->{ string=> UnspecifiedObject } # we can set shock attributes if we want
                                gzip=>0,
                                make_handle=>0
                            });

    return $f->{shock_id};
}



#END_HEADER

sub new
{
    my($class, @args) = @_;
    my $self = {
    };
    bless $self, $class;
    #BEGIN_CONSTRUCTOR

    my $config_file = $ENV{ KB_DEPLOYMENT_CONFIG };
    my $cfg = Config::IniFiles->new(-file=>$config_file);

    my $ws_url = $cfg->val('FBAFileUtil','workspace-url');
    die "no workspace-url defined" unless $ws_url;
    $self->{'workspace-url'} = $ws_url;

    my $tpp = $cfg->val('FBAFileUtil','transform-plugin-path');
    die "no transform-plugin-path defined" unless $tpp;
    $self->{'transform-plugin-path'} = $tpp;

    my $scratch = $cfg->val('FBAFileUtil','scratch');
    die "no scratch space defined" unless $scratch;
    $self->{'scratch'} = $scratch;

    # the callback url is how we call data to files
    $self->{'callbackURL'} = $ENV{ SDK_CALLBACK_URL };

    #END_CONSTRUCTOR

    if ($self->can('_init_instance'))
    {
	$self->_init_instance();
    }
    return $self;
}

=head1 METHODS



=head2 excel_file_to_model

  $return = $obj->excel_file_to_model($p)

=over 4

=item Parameter and return types

=begin html

<pre>
$p is a FBAFileUtil.ModelCreationParams
$return is a FBAFileUtil.WorkspaceRef
ModelCreationParams is a reference to a hash where the following keys are defined:
	model_file has a value which is a FBAFileUtil.File
	model_name has a value which is a string
	workspace_name has a value which is a string
	genome has a value which is a string
	biomass has a value which is a reference to a list where each element is a string
	compounds_file has a value which is a FBAFileUtil.File
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string
WorkspaceRef is a reference to a hash where the following keys are defined:
	ref has a value which is a string

</pre>

=end html

=begin text

$p is a FBAFileUtil.ModelCreationParams
$return is a FBAFileUtil.WorkspaceRef
ModelCreationParams is a reference to a hash where the following keys are defined:
	model_file has a value which is a FBAFileUtil.File
	model_name has a value which is a string
	workspace_name has a value which is a string
	genome has a value which is a string
	biomass has a value which is a reference to a list where each element is a string
	compounds_file has a value which is a FBAFileUtil.File
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string
WorkspaceRef is a reference to a hash where the following keys are defined:
	ref has a value which is a string


=end text



=item Description



=back

=cut

sub excel_file_to_model
{
    my $self = shift;
    my($p) = @_;

    my @_bad_arguments;
    (ref($p) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"p\" (value was \"$p\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to excel_file_to_model:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'excel_file_to_model');
    }

    my $ctx = $FBAFileUtil::FBAFileUtilServer::CallContext;
    my($return);
    #BEGIN excel_file_to_model

    print('excel_file_to_model parameters:');
    print(Dumper($p));

    # setup output scripts to call
    my $excelValidateScript = $self->{'transform-plugin-path'}.'/scripts/validate/trns_validate_Excel_FBAModel.pl';
    #my $uploadScript = $self->{'transform-plugin-path'}.'/scripts/upload/trns_transform_Excel_FBAModel_to_KBaseFBA_FBAModel.pl';
    # Needed to patch because $fbaurl and $wsurl parameters were not read in properly
    my $uploadScript = '/kb/module/lib/PATCH_trns_transform_Excel_FBAModel_to_KBaseFBA_FBAModel.pl';

    # get the file path (will download to scratch if the input is a shock node)
    my $model_file_path = $self->get_file_path($p->{'model_file'}, $self->{scratch});

    # validate
    my @vArgs = ("perl", $excelValidateScript, '--input_file_name', $model_file_path);
    print("Running: @vArgs \n");
    my $vRet = system(@vArgs);
    check_system_call($vRet);

    ### could pull out this logic into separate function:
    my @uploadArgs = ("perl", $uploadScript,
                    '--input_file_name', $model_file_path,
                    '--object_name', $p->{'model_name'},
                    '--workspace_name', $p->{'workspace_name'},
                    '--workspace_service_url', $self->{'workspace-url'},
                    '--fba_service_url', 'impl');

    if(exists $p->{'genome'} && defined($p->{'genome'})) {
        push @uploadArgs, '--genome';
        push @uploadArgs, $p->{'genome'};
    }
    if(exists $p->{'biomass'} && defined($p->{'biomass'}) && scalar(@{$p->{'biomass'}})>0) {
        push @uploadArgs, '--biomass';
        push @uploadArgs, join(';', @{$p->{'biomass'}} );
    }
    # No compounds file allowed for excel files; data is in excel file
    #if(exists $p->{'compounds_file'}) {
    #}
                    
    print("Running: @uploadArgs \n");
    my $ret = system(@uploadArgs);
    check_system_call($ret);

    # get WS info so we can determine the ws reference to return
    my $ref = $self->get_ws_obj_ref($p->{'workspace_name'}, $p->{'model_name'});
    $return = { ref => $ref };
    print("Saved new FBA Model to: $ref\n");

    #END excel_file_to_model
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to excel_file_to_model:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'excel_file_to_model');
    }
    return($return);
}




=head2 sbml_file_to_model

  $return = $obj->sbml_file_to_model($p)

=over 4

=item Parameter and return types

=begin html

<pre>
$p is a FBAFileUtil.ModelCreationParams
$return is a FBAFileUtil.WorkspaceRef
ModelCreationParams is a reference to a hash where the following keys are defined:
	model_file has a value which is a FBAFileUtil.File
	model_name has a value which is a string
	workspace_name has a value which is a string
	genome has a value which is a string
	biomass has a value which is a reference to a list where each element is a string
	compounds_file has a value which is a FBAFileUtil.File
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string
WorkspaceRef is a reference to a hash where the following keys are defined:
	ref has a value which is a string

</pre>

=end html

=begin text

$p is a FBAFileUtil.ModelCreationParams
$return is a FBAFileUtil.WorkspaceRef
ModelCreationParams is a reference to a hash where the following keys are defined:
	model_file has a value which is a FBAFileUtil.File
	model_name has a value which is a string
	workspace_name has a value which is a string
	genome has a value which is a string
	biomass has a value which is a reference to a list where each element is a string
	compounds_file has a value which is a FBAFileUtil.File
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string
WorkspaceRef is a reference to a hash where the following keys are defined:
	ref has a value which is a string


=end text



=item Description



=back

=cut

sub sbml_file_to_model
{
    my $self = shift;
    my($p) = @_;

    my @_bad_arguments;
    (ref($p) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"p\" (value was \"$p\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to sbml_file_to_model:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'sbml_file_to_model');
    }

    my $ctx = $FBAFileUtil::FBAFileUtilServer::CallContext;
    my($return);
    #BEGIN sbml_file_to_model
    print('sbml_file_to_model parameters:');
    print(Dumper($p));

    # setup output scripts to call
    my $sbmlValidateScript = $self->{'transform-plugin-path'}.'/scripts/validate/trns_validate_SBML_FBAModel.py';
    my $uploadScript = $self->{'transform-plugin-path'}.'/scripts/upload/trns_transform_SBML_FBAModel_to_KBaseFBA_FBAModel.pl';

    # get the file path (will download to scratch if the input is a shock node)
    my $model_file_path = $self->get_file_path($p->{'model_file'}, $self->{scratch});

    # Skip SBML Validation - some missing dependencies exist here... need to install libsbml and install validate
    #my $working_dir = $self->set_working_dir();
    #my @vArgs = ("python", $sbmlValidateScript,
    #                '--input_file_name', $model_file_path,
    #                '--working_directory', $working_dir);
    #print("Running: @vArgs \n");
    #my $vRet = system(@vArgs);
    #check_system_call($vRet);


#"input_file_name|s=s"  => \$In_RxnFile,
#       "compounds|c=s"      => \$In_CpdFile,
#       "object_name|o=s"    => \$Out_Object,
#       "workspace_name|w=s" => \$Out_WS,
#       "genome|g=s"         => \$Genome,
#       "biomass|b=s@"        => \$Biomass,
#       "workspace_service_url=s" => \$wsurl,
#       "fba_service_url=s" => \$fbaurl,

    ### could pull out this logic into separate function:
    my @uploadArgs = ("perl", $uploadScript,
                    '--input_file_name', $model_file_path,
                    '--object_name', $p->{'model_name'},
                    '--workspace_name', $p->{'workspace_name'},
                    '--workspace_service_url', $self->{'workspace-url'},
                    '--fba_service_url', 'impl');

    if(exists $p->{'genome'} && defined($p->{'genome'})) {
        push @uploadArgs, '--genome';
        push @uploadArgs, $p->{'genome'};
    }
    if(exists $p->{'biomass'} && defined($p->{'biomass'}) && scalar(@{$p->{'biomass'}})>0) {
        push @uploadArgs, '--biomass';
        push @uploadArgs, join(';', @{$p->{'biomass'}} );
    }
    # annoying, but need to check that shock_id or path is defined and exists and is not empty
    if(exists $p->{'compounds_file'} && defined($p->{'compounds_file'})) {
        if(exists($p->{'compounds_file'}->{'shock_id'}) && defined($p->{'compounds_file'}->{'shock_id'}) &&
            $p->{'compounds_file'}->{'shock_id'} ne '') {
                push @uploadArgs, '--compounds';
                my $compounds_file_path = $self->get_file_path($p->{'compounds_file'}, $self->{scratch});
                push @uploadArgs, $compounds_file_path;
        } else {
            if(exists($p->{'compounds_file'}->{'path'}) && defined($p->{'compounds_file'}->{'path'}) &&
                $p->{'compounds_file'}->{'path'} ne '') {
                push @uploadArgs, '--compounds';
                my $compounds_file_path = $self->get_file_path($p->{'compounds_file'}, $self->{scratch});
                push @uploadArgs, $compounds_file_path;
            }
        }
    }
                    
    print("Running: @uploadArgs \n");
    my $ret = system(@uploadArgs);
    check_system_call($ret);

    # get WS info so we can determine the ws reference to return
    my $ref = $self->get_ws_obj_ref($p->{'workspace_name'}, $p->{'model_name'});
    $return = { ref => $ref };
    print("Saved new FBA Model to: $ref\n");

    #END sbml_file_to_model
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to sbml_file_to_model:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'sbml_file_to_model');
    }
    return($return);
}




=head2 tsv_file_to_model

  $return = $obj->tsv_file_to_model($p)

=over 4

=item Parameter and return types

=begin html

<pre>
$p is a FBAFileUtil.ModelCreationParams
$return is a FBAFileUtil.WorkspaceRef
ModelCreationParams is a reference to a hash where the following keys are defined:
	model_file has a value which is a FBAFileUtil.File
	model_name has a value which is a string
	workspace_name has a value which is a string
	genome has a value which is a string
	biomass has a value which is a reference to a list where each element is a string
	compounds_file has a value which is a FBAFileUtil.File
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string
WorkspaceRef is a reference to a hash where the following keys are defined:
	ref has a value which is a string

</pre>

=end html

=begin text

$p is a FBAFileUtil.ModelCreationParams
$return is a FBAFileUtil.WorkspaceRef
ModelCreationParams is a reference to a hash where the following keys are defined:
	model_file has a value which is a FBAFileUtil.File
	model_name has a value which is a string
	workspace_name has a value which is a string
	genome has a value which is a string
	biomass has a value which is a reference to a list where each element is a string
	compounds_file has a value which is a FBAFileUtil.File
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string
WorkspaceRef is a reference to a hash where the following keys are defined:
	ref has a value which is a string


=end text



=item Description



=back

=cut

sub tsv_file_to_model
{
    my $self = shift;
    my($p) = @_;

    my @_bad_arguments;
    (ref($p) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"p\" (value was \"$p\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to tsv_file_to_model:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'tsv_file_to_model');
    }

    my $ctx = $FBAFileUtil::FBAFileUtilServer::CallContext;
    my($return);
    #BEGIN tsv_file_to_model
    print('tsv_file_to_model parameters:');
    print(Dumper($p));

    # setup output scripts to call
    my $tsvValidateScript = $self->{'transform-plugin-path'}.'/scripts/validate/trns_validate_TSV_FBAModel.pl';
    #my $uploadScript = $self->{'transform-plugin-path'}.'/scripts/upload/trns_transform_Excel_FBAModel_to_KBaseFBA_FBAModel.pl';
    # Needed to patch because $fbaurl and $wsurl parameters were not read in properly
    my $uploadScript = '/kb/module/lib/PATCH_trns_transform_TSV_FBAModel_to_KBaseFBA_FBAModel.pl';

    my $model_file_path = $self->get_file_path($p->{'model_file'}, $self->{scratch});

    # validate
    my @vArgs = ("perl", $tsvValidateScript, '--input_file_name', $model_file_path);
    print("Running: @vArgs \n");
    my $vRet = system(@vArgs);
    check_system_call($vRet);

    ### could pull out this logic into separate function:
    my @uploadArgs = ("perl", $uploadScript,
                    '--input_file_name', $model_file_path,
                    '--object_name', $p->{'model_name'},
                    '--workspace_name', $p->{'workspace_name'},
                    '--workspace_service_url', $self->{'workspace-url'},
                    '--fba_service_url', 'impl');

    if(exists $p->{'genome'} && defined($p->{'genome'})) {
        push @uploadArgs, '--genome';
        push @uploadArgs, $p->{'genome'};
    }
    if(exists $p->{'biomass'} && defined($p->{'biomass'}) && scalar(@{$p->{'biomass'}})>0) {
        push @uploadArgs, '--biomass';
        push @uploadArgs, join(';', @{$p->{'biomass'}} );
    }
     if(exists $p->{'compounds_file'} && defined($p->{'compounds_file'})) {
        if(exists($p->{'compounds_file'}->{'shock_id'}) && defined($p->{'compounds_file'}->{'shock_id'}) &&
            $p->{'compounds_file'}->{'shock_id'} ne '') {
                push @uploadArgs, '--compounds';
                my $compounds_file_path = $self->get_file_path($p->{'compounds_file'}, $self->{scratch});
                push @uploadArgs, $compounds_file_path;
        } else {
            if(exists($p->{'compounds_file'}->{'path'}) && defined($p->{'compounds_file'}->{'path'}) &&
                $p->{'compounds_file'}->{'path'} ne '') {
                push @uploadArgs, '--compounds';
                my $compounds_file_path = $self->get_file_path($p->{'compounds_file'}, $self->{scratch});
                push @uploadArgs, $compounds_file_path;
            }
        }
    }
                    
    print("Running: @uploadArgs \n");
    my $ret = system(@uploadArgs);
    check_system_call($ret);

    # get WS info so we can determine the ws reference to return
    my $ref = $self->get_ws_obj_ref($p->{'workspace_name'}, $p->{'model_name'});
    $return = { ref => $ref };
    print("Saved new FBA Model to: $ref\n");

    #END tsv_file_to_model
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to tsv_file_to_model:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'tsv_file_to_model');
    }
    return($return);
}




=head2 model_to_excel_file

  $f = $obj->model_to_excel_file($model)

=over 4

=item Parameter and return types

=begin html

<pre>
$model is a FBAFileUtil.ModelObjectSelectionParams
$f is a FBAFileUtil.File
ModelObjectSelectionParams is a reference to a hash where the following keys are defined:
	workspace_name has a value which is a string
	model_name has a value which is a string
	save_to_shock has a value which is a FBAFileUtil.boolean
boolean is an int
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string

</pre>

=end html

=begin text

$model is a FBAFileUtil.ModelObjectSelectionParams
$f is a FBAFileUtil.File
ModelObjectSelectionParams is a reference to a hash where the following keys are defined:
	workspace_name has a value which is a string
	model_name has a value which is a string
	save_to_shock has a value which is a FBAFileUtil.boolean
boolean is an int
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string


=end text



=item Description



=back

=cut

sub model_to_excel_file
{
    my $self = shift;
    my($model) = @_;

    my @_bad_arguments;
    (ref($model) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"model\" (value was \"$model\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to model_to_excel_file:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'model_to_excel_file');
    }

    my $ctx = $FBAFileUtil::FBAFileUtilServer::CallContext;
    my($f);
    #BEGIN model_to_excel_file
    print('model_to_excel_file parameters:');
    print(Dumper($model));

    # TODO: better input error checking
    my $output_dir = $self->set_working_dir();
    my $script = $self->{'transform-plugin-path'}.'/scripts/download/trns_transform_KBaseFBA_FBAModel_to_Excel_FBAModel.pl';

    # [object_name=s', 'workspace object name from which the input is to be read'],
    # ['workspace_name=s', 'workspace name from which the input is to be read'],
    # ['workspace_service_url=s', 'workspace service url to pull from']
    my @args = ("perl", $script, 
                    '--object_name', $model->{'model_name'},
                    '--workspace_name', $model->{'workspace_name'},
                    '--workspace_service_url', $self->{'workspace-url'});
    print("Running: @args \n");

    my $ret = system(@args);
    check_system_call($ret);

    # collect output
    my @files = get_result_files($output_dir);
    if( scalar(@files) != 1 ) {
        print("Generated : @files");
        die 'Incorrect number of files was generated! Expected 1 file.';
    }
    my $file_path = $output_dir . '/' . $files[0];
    if(exists $model->{save_to_shock} &&  defined($model->{'save_to_shock'}) && $model->{save_to_shock}==1) {
        $f = { shock_id => $self->load_to_shock($file_path) };
    } else {
        $f = { path => $file_path };
    }

    #END model_to_excel_file
    my @_bad_returns;
    (ref($f) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"f\" (value was \"$f\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to model_to_excel_file:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'model_to_excel_file');
    }
    return($f);
}




=head2 model_to_sbml_file

  $f = $obj->model_to_sbml_file($model)

=over 4

=item Parameter and return types

=begin html

<pre>
$model is a FBAFileUtil.ModelObjectSelectionParams
$f is a FBAFileUtil.File
ModelObjectSelectionParams is a reference to a hash where the following keys are defined:
	workspace_name has a value which is a string
	model_name has a value which is a string
	save_to_shock has a value which is a FBAFileUtil.boolean
boolean is an int
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string

</pre>

=end html

=begin text

$model is a FBAFileUtil.ModelObjectSelectionParams
$f is a FBAFileUtil.File
ModelObjectSelectionParams is a reference to a hash where the following keys are defined:
	workspace_name has a value which is a string
	model_name has a value which is a string
	save_to_shock has a value which is a FBAFileUtil.boolean
boolean is an int
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string


=end text



=item Description



=back

=cut

sub model_to_sbml_file
{
    my $self = shift;
    my($model) = @_;

    my @_bad_arguments;
    (ref($model) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"model\" (value was \"$model\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to model_to_sbml_file:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'model_to_sbml_file');
    }

    my $ctx = $FBAFileUtil::FBAFileUtilServer::CallContext;
    my($f);
    #BEGIN model_to_sbml_file
    print('model_to_sbml_file parameters:');
    print(Dumper($model));

    # TODO: better input error checking
    my $output_dir = $self->set_working_dir();
    my $script = $self->{'transform-plugin-path'}.'/scripts/download/trns_transform_KBaseFBA_FBAModel_to_SBML_FBAModel.pl';

    # [object_name=s', 'workspace object name from which the input is to be read'],
    # ['workspace_name=s', 'workspace name from which the input is to be read'],
    # ['workspace_service_url=s', 'workspace service url to pull from']
    my @args = ("perl", $script, 
                    '--object_name', $model->{'model_name'},
                    '--workspace_name', $model->{'workspace_name'},
                    '--workspace_service_url', $self->{'workspace-url'},
                    '--fba_service_url', 'impl');
    print("Running: @args \n");

    my $ret = system(@args);
    check_system_call($ret);

    # collect output
    my @files = get_result_files($output_dir);
    if( scalar(@files) != 1 ) {
        print("Generated : @files");
        die 'Incorrect number of files was generated! Expected 1 file.';
    }
    my $file_path = $output_dir . '/' . $files[0];
    if(exists $model->{save_to_shock} &&  defined($model->{'save_to_shock'})  && $model->{save_to_shock}==1) {
        $f = { shock_id => $self->load_to_shock($file_path) };
    } else {
        $f = { path => $file_path };
    }

    #END model_to_sbml_file
    my @_bad_returns;
    (ref($f) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"f\" (value was \"$f\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to model_to_sbml_file:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'model_to_sbml_file');
    }
    return($f);
}




=head2 model_to_tsv_file

  $files = $obj->model_to_tsv_file($model)

=over 4

=item Parameter and return types

=begin html

<pre>
$model is a FBAFileUtil.ModelObjectSelectionParams
$files is a FBAFileUtil.ModelTsvFiles
ModelObjectSelectionParams is a reference to a hash where the following keys are defined:
	workspace_name has a value which is a string
	model_name has a value which is a string
	save_to_shock has a value which is a FBAFileUtil.boolean
boolean is an int
ModelTsvFiles is a reference to a hash where the following keys are defined:
	compounds_file has a value which is a FBAFileUtil.File
	reactions_file has a value which is a FBAFileUtil.File
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string

</pre>

=end html

=begin text

$model is a FBAFileUtil.ModelObjectSelectionParams
$files is a FBAFileUtil.ModelTsvFiles
ModelObjectSelectionParams is a reference to a hash where the following keys are defined:
	workspace_name has a value which is a string
	model_name has a value which is a string
	save_to_shock has a value which is a FBAFileUtil.boolean
boolean is an int
ModelTsvFiles is a reference to a hash where the following keys are defined:
	compounds_file has a value which is a FBAFileUtil.File
	reactions_file has a value which is a FBAFileUtil.File
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string


=end text



=item Description



=back

=cut

sub model_to_tsv_file
{
    my $self = shift;
    my($model) = @_;

    my @_bad_arguments;
    (ref($model) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"model\" (value was \"$model\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to model_to_tsv_file:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'model_to_tsv_file');
    }

    my $ctx = $FBAFileUtil::FBAFileUtilServer::CallContext;
    my($files);
    #BEGIN model_to_tsv_file
    print('model_to_tsv_file parameters:');
    print(Dumper($model));

    # TODO: better input error checking
    my $output_dir = $self->set_working_dir();
    my $script = $self->{'transform-plugin-path'}.'/scripts/download/trns_transform_KBaseFBA_FBAModel_to_TSV_FBAModel.pl';

    # [object_name=s', 'workspace object name from which the input is to be read'],
    # ['workspace_name=s', 'workspace name from which the input is to be read'],
    # ['workspace_service_url=s', 'workspace service url to pull from']
    my @args = ("perl", $script, 
                    '--object_name', $model->{'model_name'},
                    '--workspace_name', $model->{'workspace_name'},
                    '--workspace_service_url', $self->{'workspace-url'});
    print("Running: @args \n");

    my $ret = system(@args);
    check_system_call($ret);

    # collect output
    my @files_list = get_result_files($output_dir);
    if( scalar(@files_list) != 2 ) {
        die 'Incorrect number of files was generated! Expected 2 files.';
    }

    $files = {};
    foreach my $f (@files_list) {
        if($f =~ m/FBAModelCompounds.tsv$/) {
            my $file_path = $output_dir . '/' . $f;
            if(exists $model->{save_to_shock} &&  defined($model->{'save_to_shock'})  && $model->{save_to_shock}==1) {
                $files->{compounds_file} = { shock_id => $self->load_to_shock($file_path) };
            } else {
                $files->{compounds_file} = { path => $file_path };
            }
        }
        if($f =~ m/FBAModelReactions.tsv$/) {
            my $file_path = $output_dir . '/' . $f;
            if(exists $model->{save_to_shock} &&  defined($model->{'save_to_shock'})  && $model->{save_to_shock}==1) {
                $files->{reactions_file} = { shock_id => $self->load_to_shock($file_path) };
            } else {
                $files->{reactions_file} = { path => $file_path };
            }
        }
    }
    # TODO: may have to zip up the files since there are two results

    #END model_to_tsv_file
    my @_bad_returns;
    (ref($files) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"files\" (value was \"$files\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to model_to_tsv_file:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'model_to_tsv_file');
    }
    return($files);
}




=head2 export_model_as_excel_file

  $output = $obj->export_model_as_excel_file($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a FBAFileUtil.ExportParams
$output is a FBAFileUtil.ExportOutput
ExportParams is a reference to a hash where the following keys are defined:
	input_ref has a value which is a string
ExportOutput is a reference to a hash where the following keys are defined:
	shock_id has a value which is a string

</pre>

=end html

=begin text

$params is a FBAFileUtil.ExportParams
$output is a FBAFileUtil.ExportOutput
ExportParams is a reference to a hash where the following keys are defined:
	input_ref has a value which is a string
ExportOutput is a reference to a hash where the following keys are defined:
	shock_id has a value which is a string


=end text



=item Description



=back

=cut

sub export_model_as_excel_file
{
    my $self = shift;
    my($params) = @_;

    my @_bad_arguments;
    (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"params\" (value was \"$params\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to export_model_as_excel_file:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'export_model_as_excel_file');
    }

    my $ctx = $FBAFileUtil::FBAFileUtilServer::CallContext;
    my($output);
    #BEGIN export_model_as_excel_file

    my $funcname = 'export_model_as_excel_file';
    print("$funcname parameters:");
    print(Dumper($params));

    # validate parameters
    if(!exists($params->{input_ref}) ||  !defined($params->{input_ref})) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error => 'input_ref required field was not defined', method_name => $funcname);
    }

    # get WS metadata to get ws_name and obj_name
    my $ws = new Bio::KBase::workspace::Client($self->{'workspace-url'});
    my $info = $ws->get_object_info_new({ objects=>[ { ref=>$params->{input_ref} } ] })->[0];

    # export to a file using existing function
    my $files = $self->model_to_excel_file({
                                model_name=> $info->[1],
                                workspace_name=> $info->[7]
                            });

    # create the output directory and move the file there
    my $export_dir = $self->{'scratch'}.'/'.$info->[1];
    mkdir $export_dir;
    my $success = move($files->{path}, $export_dir.'/'.basename($files->{path}));
    if(!$success) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error => 'could not move files to export dir: '.$export_dir,method_name => $funcname);
    }

    # package it up and be done
    my $dataUtil = DataFileUtil::DataFileUtilClient->new($self->{callbackURL});
    my $package_details = $dataUtil->package_for_download({ 
                                        file_path => $export_dir,
                                        ws_refs   => [ $params->{input_ref} ]
                                    });
    $output = { shock_id => $package_details->{shock_id} };

    #END export_model_as_excel_file
    my @_bad_returns;
    (ref($output) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"output\" (value was \"$output\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to export_model_as_excel_file:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'export_model_as_excel_file');
    }
    return($output);
}




=head2 export_model_as_tsv_file

  $output = $obj->export_model_as_tsv_file($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a FBAFileUtil.ExportParams
$output is a FBAFileUtil.ExportOutput
ExportParams is a reference to a hash where the following keys are defined:
	input_ref has a value which is a string
ExportOutput is a reference to a hash where the following keys are defined:
	shock_id has a value which is a string

</pre>

=end html

=begin text

$params is a FBAFileUtil.ExportParams
$output is a FBAFileUtil.ExportOutput
ExportParams is a reference to a hash where the following keys are defined:
	input_ref has a value which is a string
ExportOutput is a reference to a hash where the following keys are defined:
	shock_id has a value which is a string


=end text



=item Description



=back

=cut

sub export_model_as_tsv_file
{
    my $self = shift;
    my($params) = @_;

    my @_bad_arguments;
    (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"params\" (value was \"$params\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to export_model_as_tsv_file:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'export_model_as_tsv_file');
    }

    my $ctx = $FBAFileUtil::FBAFileUtilServer::CallContext;
    my($output);
    #BEGIN export_model_as_tsv_file

    my $funcname = 'export_model_as_tsv_file';
    print("$funcname parameters:");
    print(Dumper($params));

    # validate parameters
    if(!exists($params->{input_ref}) ||  !defined($params->{input_ref})) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error => 'input_ref required field was not defined', method_name => $funcname);
    }

    # get WS metadata to get ws_name and obj_name
    my $ws = new Bio::KBase::workspace::Client($self->{'workspace-url'});
    my $info = $ws->get_object_info_new({ objects=>[ { ref=>$params->{input_ref} } ] })->[0];

    # export to a file using existing function
    my $files = $self->model_to_tsv_file({
                                model_name=> $info->[1],
                                workspace_name=> $info->[7]
                            });

    # create the output directory and move the file there
    my $export_dir = $self->{'scratch'}.'/'.$info->[1];
    mkdir $export_dir;
    my $success = move($files->{reactions_file}->{path}, $export_dir.'/'.basename($files->{reactions_file}->{path}));
    if(!$success) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error => 'could not move files to export dir: '.$export_dir,method_name => $funcname);
    }
    my $success = move($files->{compounds_file}->{path}, $export_dir.'/'.basename($files->{compounds_file}->{path}));
    if(!$success) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error => 'could not move files to export dir: '.$export_dir,method_name => $funcname);
    }

    # package it up and be done
    my $dataUtil = DataFileUtil::DataFileUtilClient->new($self->{callbackURL});
    my $package_details = $dataUtil->package_for_download({ 
                                        file_path => $export_dir,
                                        ws_refs   => [ $params->{input_ref} ]
                                    });
    $output = { shock_id => $package_details->{shock_id} };


    #END export_model_as_tsv_file
    my @_bad_returns;
    (ref($output) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"output\" (value was \"$output\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to export_model_as_tsv_file:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'export_model_as_tsv_file');
    }
    return($output);
}




=head2 export_model_as_sbml_file

  $output = $obj->export_model_as_sbml_file($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a FBAFileUtil.ExportParams
$output is a FBAFileUtil.ExportOutput
ExportParams is a reference to a hash where the following keys are defined:
	input_ref has a value which is a string
ExportOutput is a reference to a hash where the following keys are defined:
	shock_id has a value which is a string

</pre>

=end html

=begin text

$params is a FBAFileUtil.ExportParams
$output is a FBAFileUtil.ExportOutput
ExportParams is a reference to a hash where the following keys are defined:
	input_ref has a value which is a string
ExportOutput is a reference to a hash where the following keys are defined:
	shock_id has a value which is a string


=end text



=item Description



=back

=cut

sub export_model_as_sbml_file
{
    my $self = shift;
    my($params) = @_;

    my @_bad_arguments;
    (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"params\" (value was \"$params\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to export_model_as_sbml_file:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'export_model_as_sbml_file');
    }

    my $ctx = $FBAFileUtil::FBAFileUtilServer::CallContext;
    my($output);
    #BEGIN export_model_as_sbml_file

    my $funcname = 'export_model_as_sbml_file';
    print("$funcname parameters:");
    print(Dumper($params));

    # validate parameters
    if(!exists($params->{input_ref}) ||  !defined($params->{input_ref})) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error => 'input_ref required field was not defined', method_name => $funcname);
    }

    # get WS metadata to get ws_name and obj_name
    my $ws = new Bio::KBase::workspace::Client($self->{'workspace-url'});
    my $info = $ws->get_object_info_new({ objects=>[ { ref=>$params->{input_ref} } ] })->[0];

    # export to a file using existing function
    my $files = $self->model_to_sbml_file({
                                model_name=> $info->[1],
                                workspace_name=> $info->[7]
                            });

    # create the output directory and move the file there
    my $export_dir = $self->{'scratch'}.'/'.$info->[1];
    mkdir $export_dir;
    my $success = move($files->{path}, $export_dir.'/'.basename($files->{path}));
    if(!$success) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error => 'could not move files to export dir: '.$export_dir,method_name => $funcname);
    }

    # package it up and be done
    my $dataUtil = DataFileUtil::DataFileUtilClient->new($self->{callbackURL});
    my $package_details = $dataUtil->package_for_download({ 
                                        file_path => $export_dir,
                                        ws_refs   => [ $params->{input_ref} ]
                                    });
    $output = { shock_id => $package_details->{shock_id} };

    #END export_model_as_sbml_file
    my @_bad_returns;
    (ref($output) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"output\" (value was \"$output\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to export_model_as_sbml_file:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'export_model_as_sbml_file');
    }
    return($output);
}




=head2 fba_to_excel_file

  $f = $obj->fba_to_excel_file($fba)

=over 4

=item Parameter and return types

=begin html

<pre>
$fba is a FBAFileUtil.FBAObjectSelectionParams
$f is a FBAFileUtil.File
FBAObjectSelectionParams is a reference to a hash where the following keys are defined:
	workspace_name has a value which is a string
	fba_name has a value which is a string
	save_to_shock has a value which is a FBAFileUtil.boolean
boolean is an int
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string

</pre>

=end html

=begin text

$fba is a FBAFileUtil.FBAObjectSelectionParams
$f is a FBAFileUtil.File
FBAObjectSelectionParams is a reference to a hash where the following keys are defined:
	workspace_name has a value which is a string
	fba_name has a value which is a string
	save_to_shock has a value which is a FBAFileUtil.boolean
boolean is an int
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string


=end text



=item Description



=back

=cut

sub fba_to_excel_file
{
    my $self = shift;
    my($fba) = @_;

    my @_bad_arguments;
    (ref($fba) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"fba\" (value was \"$fba\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to fba_to_excel_file:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'fba_to_excel_file');
    }

    my $ctx = $FBAFileUtil::FBAFileUtilServer::CallContext;
    my($f);
    #BEGIN fba_to_excel_file
    print('fba_to_excel_file parameters:');
    print(Dumper($fba));

    # TODO: better input error checking
    my $output_dir = $self->set_working_dir();
    my $script = $self->{'transform-plugin-path'}.'/scripts/download/trns_transform_KBaseFBA_FBA_to_Excel_FBA.pl';

    my @args = ("perl", $script, 
                    '--object_name', $fba->{'fba_name'},
                    '--workspace_name', $fba->{'workspace_name'},
                    '--workspace_service_url', $self->{'workspace-url'});
    print("Running: @args \n");

    my $ret = system(@args);
    check_system_call($ret);

    # collect output
    my @files = get_result_files($output_dir);
    if( scalar(@files) != 1 ) {
        print("Generated : @files");
        die 'Incorrect number of files was generated! Expected 1 file.';
    }
    my $file_path = $output_dir . '/' . $files[0];
    if(exists $fba->{save_to_shock} &&  defined($fba->{'save_to_shock'})  && $fba->{save_to_shock}==1) {
        $f = { shock_id => $self->load_to_shock($file_path) };
    } else {
        $f = { path => $file_path };
    }

    #END fba_to_excel_file
    my @_bad_returns;
    (ref($f) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"f\" (value was \"$f\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to fba_to_excel_file:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'fba_to_excel_file');
    }
    return($f);
}




=head2 fba_to_tsv_file

  $files = $obj->fba_to_tsv_file($fba)

=over 4

=item Parameter and return types

=begin html

<pre>
$fba is a FBAFileUtil.FBAObjectSelectionParams
$files is a FBAFileUtil.FBATsvFiles
FBAObjectSelectionParams is a reference to a hash where the following keys are defined:
	workspace_name has a value which is a string
	fba_name has a value which is a string
	save_to_shock has a value which is a FBAFileUtil.boolean
boolean is an int
FBATsvFiles is a reference to a hash where the following keys are defined:
	compounds_file has a value which is a FBAFileUtil.File
	reactions_file has a value which is a FBAFileUtil.File
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string

</pre>

=end html

=begin text

$fba is a FBAFileUtil.FBAObjectSelectionParams
$files is a FBAFileUtil.FBATsvFiles
FBAObjectSelectionParams is a reference to a hash where the following keys are defined:
	workspace_name has a value which is a string
	fba_name has a value which is a string
	save_to_shock has a value which is a FBAFileUtil.boolean
boolean is an int
FBATsvFiles is a reference to a hash where the following keys are defined:
	compounds_file has a value which is a FBAFileUtil.File
	reactions_file has a value which is a FBAFileUtil.File
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string


=end text



=item Description



=back

=cut

sub fba_to_tsv_file
{
    my $self = shift;
    my($fba) = @_;

    my @_bad_arguments;
    (ref($fba) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"fba\" (value was \"$fba\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to fba_to_tsv_file:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'fba_to_tsv_file');
    }

    my $ctx = $FBAFileUtil::FBAFileUtilServer::CallContext;
    my($files);
    #BEGIN fba_to_tsv_file
    print('fba_to_tsv_file parameters:');
    print(Dumper($fba));

    # TODO: better input error checking
    my $output_dir = $self->set_working_dir();
    my $script = $self->{'transform-plugin-path'}.'/scripts/download/trns_transform_KBaseFBA_FBA_to_TSV_FBA.pl';

    my @args = ("perl", $script, 
                    '--object_name', $fba->{'fba_name'},
                    '--workspace_name', $fba->{'workspace_name'},
                    '--workspace_service_url', $self->{'workspace-url'});
    print("Running: @args \n");

    my $ret = system(@args);
    check_system_call($ret);

    # collect output
    my @files_list = get_result_files($output_dir);
    if( scalar(@files_list) != 2 ) {
        die 'Incorrect number of files was generated! Expected 2 files.';
    }

    $files = {};
    foreach my $f (@files_list) {
        if($f =~ m/FBACompounds.tsv$/) {
            my $file_path = $output_dir . '/' . $f;
            if(exists $fba->{save_to_shock} &&  defined($fba->{'save_to_shock'}) && $fba->{save_to_shock}==1) {
                $files->{compounds_file} = { shock_id =>  $self->load_to_shock($file_path) };
            } else {
                $files->{compounds_file} = { path => $file_path };
            }
        }
        if($f =~ m/FBAReactions.tsv$/) {
            my $file_path = $output_dir . '/' . $f;
            if(exists $fba->{save_to_shock} &&  defined($fba->{'save_to_shock'}) && $fba->{save_to_shock}==1) {
                $files->{reactions_file} = { shock_id =>  $self->load_to_shock($file_path) };
            } else {
                $files->{reactions_file} = { path => $file_path };
            }
        }
    }
    # TODO: may have to zip up the files since there are two results

    #END fba_to_tsv_file
    my @_bad_returns;
    (ref($files) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"files\" (value was \"$files\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to fba_to_tsv_file:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'fba_to_tsv_file');
    }
    return($files);
}




=head2 export_fba_as_excel_file

  $output = $obj->export_fba_as_excel_file($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a FBAFileUtil.ExportParams
$output is a FBAFileUtil.ExportOutput
ExportParams is a reference to a hash where the following keys are defined:
	input_ref has a value which is a string
ExportOutput is a reference to a hash where the following keys are defined:
	shock_id has a value which is a string

</pre>

=end html

=begin text

$params is a FBAFileUtil.ExportParams
$output is a FBAFileUtil.ExportOutput
ExportParams is a reference to a hash where the following keys are defined:
	input_ref has a value which is a string
ExportOutput is a reference to a hash where the following keys are defined:
	shock_id has a value which is a string


=end text



=item Description



=back

=cut

sub export_fba_as_excel_file
{
    my $self = shift;
    my($params) = @_;

    my @_bad_arguments;
    (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"params\" (value was \"$params\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to export_fba_as_excel_file:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'export_fba_as_excel_file');
    }

    my $ctx = $FBAFileUtil::FBAFileUtilServer::CallContext;
    my($output);
    #BEGIN export_fba_as_excel_file

    my $funcname = 'export_fba_as_excel_file';
    print("$funcname parameters:");
    print(Dumper($params));

    # validate parameters
    if(!exists($params->{input_ref}) ||  !defined($params->{input_ref})) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error => 'input_ref required field was not defined', method_name => $funcname);
    }

    # get WS metadata to get ws_name and obj_name
    my $ws = new Bio::KBase::workspace::Client($self->{'workspace-url'});
    my $info = $ws->get_object_info_new({ objects=>[ { ref=>$params->{input_ref} } ] })->[0];

    # export to a file using existing function
    my $files = $self->fba_to_excel_file({
                                fba_name=> $info->[1],
                                workspace_name=> $info->[7]
                            });

    # create the output directory and move the file there
    my $export_dir = $self->{'scratch'}.'/'.$info->[1];
    mkdir $export_dir;
    my $success = move($files->{path}, $export_dir.'/'.basename($files->{path}));
    if(!$success) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error => 'could not move files to export dir: '.$export_dir,method_name => $funcname);
    }

    # package it up and be done
    my $dataUtil = DataFileUtil::DataFileUtilClient->new($self->{callbackURL});
    my $package_details = $dataUtil->package_for_download({ 
                                        file_path => $export_dir,
                                        ws_refs   => [ $params->{input_ref} ]
                                    });
    $output = { shock_id => $package_details->{shock_id} };

    #END export_fba_as_excel_file
    my @_bad_returns;
    (ref($output) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"output\" (value was \"$output\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to export_fba_as_excel_file:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'export_fba_as_excel_file');
    }
    return($output);
}




=head2 export_fba_as_tsv_file

  $output = $obj->export_fba_as_tsv_file($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a FBAFileUtil.ExportParams
$output is a FBAFileUtil.ExportOutput
ExportParams is a reference to a hash where the following keys are defined:
	input_ref has a value which is a string
ExportOutput is a reference to a hash where the following keys are defined:
	shock_id has a value which is a string

</pre>

=end html

=begin text

$params is a FBAFileUtil.ExportParams
$output is a FBAFileUtil.ExportOutput
ExportParams is a reference to a hash where the following keys are defined:
	input_ref has a value which is a string
ExportOutput is a reference to a hash where the following keys are defined:
	shock_id has a value which is a string


=end text



=item Description



=back

=cut

sub export_fba_as_tsv_file
{
    my $self = shift;
    my($params) = @_;

    my @_bad_arguments;
    (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"params\" (value was \"$params\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to export_fba_as_tsv_file:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'export_fba_as_tsv_file');
    }

    my $ctx = $FBAFileUtil::FBAFileUtilServer::CallContext;
    my($output);
    #BEGIN export_fba_as_tsv_file

    my $funcname = 'export_fba_as_tsv_file';
    print("$funcname parameters:");
    print(Dumper($params));

    # validate parameters
    if(!exists($params->{input_ref}) ||  !defined($params->{input_ref})) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error => 'input_ref required field was not defined', method_name => $funcname);
    }

    # get WS metadata to get ws_name and obj_name
    my $ws = new Bio::KBase::workspace::Client($self->{'workspace-url'});
    my $info = $ws->get_object_info_new({ objects=>[ { ref=>$params->{input_ref} } ] })->[0];

    # export to a file using existing function
    my $files = $self->fba_to_tsv_file({
                                fba_name=> $info->[1],
                                workspace_name=> $info->[7]
                            });

    # create the output directory and move the file there
    my $export_dir = $self->{'scratch'}.'/'.$info->[1];
    mkdir $export_dir;
    my $success = move($files->{reactions_file}->{path}, $export_dir.'/'.basename($files->{reactions_file}->{path}));
    if(!$success) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error => 'could not move files to export dir: '.$export_dir,method_name => $funcname);
    }
    my $success = move($files->{compounds_file}->{path}, $export_dir.'/'.basename($files->{compounds_file}->{path}));
    if(!$success) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error => 'could not move files to export dir: '.$export_dir,method_name => $funcname);
    }
    
    # package it up and be done
    my $dataUtil = DataFileUtil::DataFileUtilClient->new($self->{callbackURL});
    my $package_details = $dataUtil->package_for_download({ 
                                        file_path => $export_dir,
                                        ws_refs   => [ $params->{input_ref} ]
                                    });
    $output = { shock_id => $package_details->{shock_id} };

    #END export_fba_as_tsv_file
    my @_bad_returns;
    (ref($output) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"output\" (value was \"$output\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to export_fba_as_tsv_file:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'export_fba_as_tsv_file');
    }
    return($output);
}




=head2 tsv_file_to_media

  $return = $obj->tsv_file_to_media($p)

=over 4

=item Parameter and return types

=begin html

<pre>
$p is a FBAFileUtil.MediaCreationParams
$return is a FBAFileUtil.WorkspaceRef
MediaCreationParams is a reference to a hash where the following keys are defined:
	media_file has a value which is a FBAFileUtil.File
	media_name has a value which is a string
	workspace_name has a value which is a string
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string
WorkspaceRef is a reference to a hash where the following keys are defined:
	ref has a value which is a string

</pre>

=end html

=begin text

$p is a FBAFileUtil.MediaCreationParams
$return is a FBAFileUtil.WorkspaceRef
MediaCreationParams is a reference to a hash where the following keys are defined:
	media_file has a value which is a FBAFileUtil.File
	media_name has a value which is a string
	workspace_name has a value which is a string
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string
WorkspaceRef is a reference to a hash where the following keys are defined:
	ref has a value which is a string


=end text



=item Description



=back

=cut

sub tsv_file_to_media
{
    my $self = shift;
    my($p) = @_;

    my @_bad_arguments;
    (ref($p) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"p\" (value was \"$p\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to tsv_file_to_media:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'tsv_file_to_media');
    }

    my $ctx = $FBAFileUtil::FBAFileUtilServer::CallContext;
    my($return);
    #BEGIN tsv_file_to_media
    print('tsv_file_to_media parameters:');
    print(Dumper($p));

    my $media_file_path = $self->get_file_path($p->{'media_file'}, $self->{scratch});

    # setup output scripts to call
    my $uploadScript = $self->{'transform-plugin-path'}.'/scripts/upload/trns_transform_TSV_Media_to_KBaseBiochem_Media.pl';

    my @uploadArgs = ("perl", $uploadScript,
                    '--input_file_name', $media_file_path,
                    '--object_name', $p->{'media_name'},
                    '--workspace_name', $p->{'workspace_name'},
                    '--workspace_service_url', $self->{'workspace-url'},
                    '--fba_service_url', 'impl');

    print("Running: @uploadArgs \n");
    my $ret = system(@uploadArgs);
    check_system_call($ret);

    # get WS info so we can determine the ws reference to return
    my $ref = $self->get_ws_obj_ref($p->{'workspace_name'}, $p->{'media_name'});
    $return = { ref => $ref };
    print("Saved new Media to: $ref\n");

    #END tsv_file_to_media
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to tsv_file_to_media:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'tsv_file_to_media');
    }
    return($return);
}




=head2 excel_file_to_media

  $return = $obj->excel_file_to_media($p)

=over 4

=item Parameter and return types

=begin html

<pre>
$p is a FBAFileUtil.MediaCreationParams
$return is a FBAFileUtil.WorkspaceRef
MediaCreationParams is a reference to a hash where the following keys are defined:
	media_file has a value which is a FBAFileUtil.File
	media_name has a value which is a string
	workspace_name has a value which is a string
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string
WorkspaceRef is a reference to a hash where the following keys are defined:
	ref has a value which is a string

</pre>

=end html

=begin text

$p is a FBAFileUtil.MediaCreationParams
$return is a FBAFileUtil.WorkspaceRef
MediaCreationParams is a reference to a hash where the following keys are defined:
	media_file has a value which is a FBAFileUtil.File
	media_name has a value which is a string
	workspace_name has a value which is a string
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string
WorkspaceRef is a reference to a hash where the following keys are defined:
	ref has a value which is a string


=end text



=item Description



=back

=cut

sub excel_file_to_media
{
    my $self = shift;
    my($p) = @_;

    my @_bad_arguments;
    (ref($p) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"p\" (value was \"$p\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to excel_file_to_media:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'excel_file_to_media');
    }

    my $ctx = $FBAFileUtil::FBAFileUtilServer::CallContext;
    my($return);
    #BEGIN excel_file_to_media
    print('excel_file_to_media parameters:');
    print(Dumper($p));

    my $media_file_path = $self->get_file_path($p->{'media_file'}, $self->{scratch});

    # setup output scripts to call
    my $excelValidateScript = $self->{'transform-plugin-path'}.'/scripts/validate/trns_validate_Excel_Media.pl';
    #my $uploadScript = $self->{'transform-plugin-path'}.'/scripts/upload/trns_transform_Excel_Media_to_KBaseBiochem_Media.pl';
    # Needed to patch because $fbaurl and $wsurl parameters were not read in properly
    my $uploadScript = '/kb/module/lib/PATCH_trns_transform_Excel_Media_to_KBaseBiochem_Media.pl';

    # validate
    my @vArgs = ("perl", $excelValidateScript, '--input_file_name', $media_file_path);
    print("Running: @vArgs \n");
    my $vRet = system(@vArgs);
    check_system_call($vRet);

    my @uploadArgs = ("perl", $uploadScript,
                    '--input_file_name', $media_file_path,
                    '--object_name', $p->{'media_name'},
                    '--workspace_name', $p->{'workspace_name'},
                    '--workspace_service_url', $self->{'workspace-url'},
                    '--fba_service_url', 'impl');

    print("Running: @uploadArgs \n");
    my $ret = system(@uploadArgs);
    check_system_call($ret);

    # get WS info so we can determine the ws reference to return
    my $ref = $self->get_ws_obj_ref($p->{'workspace_name'}, $p->{'media_name'});
    $return = { ref => $ref };
    print("Saved new Media to: $ref\n");

    #END excel_file_to_media
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to excel_file_to_media:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'excel_file_to_media');
    }
    return($return);
}




=head2 media_to_tsv_file

  $f = $obj->media_to_tsv_file($media)

=over 4

=item Parameter and return types

=begin html

<pre>
$media is a FBAFileUtil.MediaObjectSelectionParams
$f is a FBAFileUtil.File
MediaObjectSelectionParams is a reference to a hash where the following keys are defined:
	workspace_name has a value which is a string
	media_name has a value which is a string
	save_to_shock has a value which is a FBAFileUtil.boolean
boolean is an int
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string

</pre>

=end html

=begin text

$media is a FBAFileUtil.MediaObjectSelectionParams
$f is a FBAFileUtil.File
MediaObjectSelectionParams is a reference to a hash where the following keys are defined:
	workspace_name has a value which is a string
	media_name has a value which is a string
	save_to_shock has a value which is a FBAFileUtil.boolean
boolean is an int
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string


=end text



=item Description



=back

=cut

sub media_to_tsv_file
{
    my $self = shift;
    my($media) = @_;

    my @_bad_arguments;
    (ref($media) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"media\" (value was \"$media\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to media_to_tsv_file:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'media_to_tsv_file');
    }

    my $ctx = $FBAFileUtil::FBAFileUtilServer::CallContext;
    my($f);
    #BEGIN media_to_tsv_file
    print('media_to_tsv_file parameters:');
    print(Dumper($media));

    # TODO: better input error checking
    my $output_dir = $self->set_working_dir();
    my $script = $self->{'transform-plugin-path'}.'/scripts/download/trns_transform_KBaseBiochem_Media_to_TSV_Media.pl';

    my @args = ("perl", $script, 
                    '--object_name', $media->{'media_name'},
                    '--workspace_name', $media->{'workspace_name'},
                    '--workspace_service_url', $self->{'workspace-url'});
    print("Running: @args \n");

    my $ret = system(@args);
    check_system_call($ret);

    # collect output
    my @files = get_result_files($output_dir);
    if( scalar(@files) != 1 ) {
        print("Generated : @files");
        die 'Incorrect number of files was generated! Expected 1 file.';
    }
    my $file_path = $output_dir . '/' . $files[0];
    if(exists $media->{save_to_shock} &&  defined($media->{save_to_shock})  && $media->{save_to_shock}==1) {
        $f = { shock_id => $self->load_to_shock($file_path) };
    } else {
        $f = { path => $file_path };
    }

    #END media_to_tsv_file
    my @_bad_returns;
    (ref($f) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"f\" (value was \"$f\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to media_to_tsv_file:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'media_to_tsv_file');
    }
    return($f);
}




=head2 media_to_excel_file

  $f = $obj->media_to_excel_file($media)

=over 4

=item Parameter and return types

=begin html

<pre>
$media is a FBAFileUtil.MediaObjectSelectionParams
$f is a FBAFileUtil.File
MediaObjectSelectionParams is a reference to a hash where the following keys are defined:
	workspace_name has a value which is a string
	media_name has a value which is a string
	save_to_shock has a value which is a FBAFileUtil.boolean
boolean is an int
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string

</pre>

=end html

=begin text

$media is a FBAFileUtil.MediaObjectSelectionParams
$f is a FBAFileUtil.File
MediaObjectSelectionParams is a reference to a hash where the following keys are defined:
	workspace_name has a value which is a string
	media_name has a value which is a string
	save_to_shock has a value which is a FBAFileUtil.boolean
boolean is an int
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string


=end text



=item Description



=back

=cut

sub media_to_excel_file
{
    my $self = shift;
    my($media) = @_;

    my @_bad_arguments;
    (ref($media) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"media\" (value was \"$media\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to media_to_excel_file:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'media_to_excel_file');
    }

    my $ctx = $FBAFileUtil::FBAFileUtilServer::CallContext;
    my($f);
    #BEGIN media_to_excel_file
    print('media_to_excel_file parameters:');
    print(Dumper($media));

    # TODO: better input error checking
    my $output_dir = $self->set_working_dir();
    my $script = $self->{'transform-plugin-path'}.'/scripts/download/trns_transform_KBaseBiochem_Media_to_Excel_Media.pl';

    my @args = ("perl", $script, 
                    '--object_name', $media->{'media_name'},
                    '--workspace_name', $media->{'workspace_name'},
                    '--workspace_service_url', $self->{'workspace-url'});
    print("Running: @args \n");

    my $ret = system(@args);
    check_system_call($ret);

    # collect output
    my @files = get_result_files($output_dir);
    if( scalar(@files) != 1 ) {
        print("Generated : @files");
        die 'Incorrect number of files was generated! Expected 1 file.';
    }
    my $file_path = $output_dir . '/' . $files[0];
    if(exists $media->{save_to_shock} &&  defined($media->{save_to_shock}) && $media->{save_to_shock}==1) {
        $f = { shock_id => $self->load_to_shock($file_path) };
    } else {
        $f = { path => $file_path };
    }

    #END media_to_excel_file
    my @_bad_returns;
    (ref($f) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"f\" (value was \"$f\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to media_to_excel_file:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'media_to_excel_file');
    }
    return($f);
}




=head2 export_media_as_excel_file

  $output = $obj->export_media_as_excel_file($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a FBAFileUtil.ExportParams
$output is a FBAFileUtil.ExportOutput
ExportParams is a reference to a hash where the following keys are defined:
	input_ref has a value which is a string
ExportOutput is a reference to a hash where the following keys are defined:
	shock_id has a value which is a string

</pre>

=end html

=begin text

$params is a FBAFileUtil.ExportParams
$output is a FBAFileUtil.ExportOutput
ExportParams is a reference to a hash where the following keys are defined:
	input_ref has a value which is a string
ExportOutput is a reference to a hash where the following keys are defined:
	shock_id has a value which is a string


=end text



=item Description



=back

=cut

sub export_media_as_excel_file
{
    my $self = shift;
    my($params) = @_;

    my @_bad_arguments;
    (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"params\" (value was \"$params\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to export_media_as_excel_file:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'export_media_as_excel_file');
    }

    my $ctx = $FBAFileUtil::FBAFileUtilServer::CallContext;
    my($output);
    #BEGIN export_media_as_excel_file

    my $funcname = 'export_media_as_excel_file';
    print("$funcname parameters:");
    print(Dumper($params));

    # validate parameters
    if(!exists($params->{input_ref}) ||  !defined($params->{input_ref})) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error => 'input_ref required field was not defined', method_name => $funcname);
    }

    # get WS metadata to get ws_name and obj_name
    my $ws = new Bio::KBase::workspace::Client($self->{'workspace-url'});
    my $info = $ws->get_object_info_new({ objects=>[ { ref=>$params->{input_ref} } ] })->[0];

    # export to a file using existing function
    my $files = $self->media_to_excel_file({
                                media_name=> $info->[1],
                                workspace_name=> $info->[7]
                            });

    # create the output directory and move the file there
    my $export_dir = $self->{'scratch'}.'/'.$info->[1];
    mkdir $export_dir;
    my $success = move($files->{path}, $export_dir.'/'.basename($files->{path}));
    if(!$success) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error => 'could not move files to export dir: '.$export_dir,method_name => $funcname);
    }

    # package it up and be done
    my $dataUtil = DataFileUtil::DataFileUtilClient->new($self->{callbackURL});
    my $package_details = $dataUtil->package_for_download({ 
                                        file_path => $export_dir,
                                        ws_refs   => [ $params->{input_ref} ]
                                    });
    $output = { shock_id => $package_details->{shock_id} };


    #END export_media_as_excel_file
    my @_bad_returns;
    (ref($output) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"output\" (value was \"$output\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to export_media_as_excel_file:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'export_media_as_excel_file');
    }
    return($output);
}




=head2 export_media_as_tsv_file

  $output = $obj->export_media_as_tsv_file($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a FBAFileUtil.ExportParams
$output is a FBAFileUtil.ExportOutput
ExportParams is a reference to a hash where the following keys are defined:
	input_ref has a value which is a string
ExportOutput is a reference to a hash where the following keys are defined:
	shock_id has a value which is a string

</pre>

=end html

=begin text

$params is a FBAFileUtil.ExportParams
$output is a FBAFileUtil.ExportOutput
ExportParams is a reference to a hash where the following keys are defined:
	input_ref has a value which is a string
ExportOutput is a reference to a hash where the following keys are defined:
	shock_id has a value which is a string


=end text



=item Description



=back

=cut

sub export_media_as_tsv_file
{
    my $self = shift;
    my($params) = @_;

    my @_bad_arguments;
    (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"params\" (value was \"$params\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to export_media_as_tsv_file:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'export_media_as_tsv_file');
    }

    my $ctx = $FBAFileUtil::FBAFileUtilServer::CallContext;
    my($output);
    #BEGIN export_media_as_tsv_file

    my $funcname = 'export_media_as_tsv_file';
    print("$funcname parameters:");
    print(Dumper($params));

    # validate parameters
    if(!exists($params->{input_ref}) ||  !defined($params->{input_ref})) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error => 'input_ref required field was not defined', method_name => $funcname);
    }

    # get WS metadata to get ws_name and obj_name
    my $ws = new Bio::KBase::workspace::Client($self->{'workspace-url'});
    my $info = $ws->get_object_info_new({ objects=>[ { ref=>$params->{input_ref} } ] })->[0];

    # export to a file using existing function
    my $files = $self->media_to_tsv_file({
                                media_name=> $info->[1],
                                workspace_name=> $info->[7]
                            });

    # create the output directory and move the file there
    my $export_dir = $self->{'scratch'}.'/'.$info->[1];
    mkdir $export_dir;
    my $success = move($files->{path}, $export_dir.'/'.basename($files->{path}));
    if(!$success) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error => 'could not move files to export dir: '.$export_dir,method_name => $funcname);
    }

    # package it up and be done
    my $dataUtil = DataFileUtil::DataFileUtilClient->new($self->{callbackURL});
    my $package_details = $dataUtil->package_for_download({ 
                                        file_path => $export_dir,
                                        ws_refs   => [ $params->{input_ref} ]
                                    });
    $output = { shock_id => $package_details->{shock_id} };

    #END export_media_as_tsv_file
    my @_bad_returns;
    (ref($output) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"output\" (value was \"$output\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to export_media_as_tsv_file:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'export_media_as_tsv_file');
    }
    return($output);
}




=head2 tsv_file_to_phenotype_set

  $return = $obj->tsv_file_to_phenotype_set($p)

=over 4

=item Parameter and return types

=begin html

<pre>
$p is a FBAFileUtil.PhenotypeSetCreationParams
$return is a FBAFileUtil.WorkspaceRef
PhenotypeSetCreationParams is a reference to a hash where the following keys are defined:
	phenotype_set_file has a value which is a FBAFileUtil.File
	phenotype_set_name has a value which is a string
	workspace_name has a value which is a string
	genome has a value which is a string
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string
WorkspaceRef is a reference to a hash where the following keys are defined:
	ref has a value which is a string

</pre>

=end html

=begin text

$p is a FBAFileUtil.PhenotypeSetCreationParams
$return is a FBAFileUtil.WorkspaceRef
PhenotypeSetCreationParams is a reference to a hash where the following keys are defined:
	phenotype_set_file has a value which is a FBAFileUtil.File
	phenotype_set_name has a value which is a string
	workspace_name has a value which is a string
	genome has a value which is a string
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string
WorkspaceRef is a reference to a hash where the following keys are defined:
	ref has a value which is a string


=end text



=item Description



=back

=cut

sub tsv_file_to_phenotype_set
{
    my $self = shift;
    my($p) = @_;

    my @_bad_arguments;
    (ref($p) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"p\" (value was \"$p\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to tsv_file_to_phenotype_set:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'tsv_file_to_phenotype_set');
    }

    my $ctx = $FBAFileUtil::FBAFileUtilServer::CallContext;
    my($return);
    #BEGIN tsv_file_to_phenotype_set
    print('tsv_file_to_phenotype_set parameters:');
    print(Dumper($p));

    my $phenotype_set_file_path = $self->get_file_path($p->{'phenotype_set_file'}, $self->{scratch});

    # setup output scripts to call
    my $uploadScript = $self->{'transform-plugin-path'}.'/scripts/upload/trns_transform_TSV_Phenotypes_to_KBasePhenotypes_PhenotypeSet.pl';

    my @uploadArgs = ("perl", $uploadScript,
                    '--input_file_name', $phenotype_set_file_path,
                    '--object_name', $p->{'phenotype_set_name'},
                    '--workspace_name', $p->{'workspace_name'},
                    '--workspace_service_url', $self->{'workspace-url'},
                    '--fba_service_url', 'impl');

    print("Running: @uploadArgs \n");
    my $ret = system(@uploadArgs);
    check_system_call($ret);

    # get WS info so we can determine the ws reference to return
    my $ref = $self->get_ws_obj_ref($p->{'workspace_name'}, $p->{'phenotype_set_name'});
    $return = { ref => $ref };
    print("Saved new Phenotype Set to: $ref\n");

    #END tsv_file_to_phenotype_set
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to tsv_file_to_phenotype_set:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'tsv_file_to_phenotype_set');
    }
    return($return);
}




=head2 phenotype_set_to_tsv_file

  $f = $obj->phenotype_set_to_tsv_file($phenotype_set)

=over 4

=item Parameter and return types

=begin html

<pre>
$phenotype_set is a FBAFileUtil.PhenotypeSetObjectSelectionParams
$f is a FBAFileUtil.File
PhenotypeSetObjectSelectionParams is a reference to a hash where the following keys are defined:
	workspace_name has a value which is a string
	phenotype_set_name has a value which is a string
	save_to_shock has a value which is a FBAFileUtil.boolean
boolean is an int
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string

</pre>

=end html

=begin text

$phenotype_set is a FBAFileUtil.PhenotypeSetObjectSelectionParams
$f is a FBAFileUtil.File
PhenotypeSetObjectSelectionParams is a reference to a hash where the following keys are defined:
	workspace_name has a value which is a string
	phenotype_set_name has a value which is a string
	save_to_shock has a value which is a FBAFileUtil.boolean
boolean is an int
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string


=end text



=item Description



=back

=cut

sub phenotype_set_to_tsv_file
{
    my $self = shift;
    my($phenotype_set) = @_;

    my @_bad_arguments;
    (ref($phenotype_set) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"phenotype_set\" (value was \"$phenotype_set\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to phenotype_set_to_tsv_file:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'phenotype_set_to_tsv_file');
    }

    my $ctx = $FBAFileUtil::FBAFileUtilServer::CallContext;
    my($f);
    #BEGIN phenotype_set_to_tsv_file
    print('phenotype_set_to_tsv_file parameters:');
    print(Dumper($phenotype_set));

    # TODO: better input error checking
    my $output_dir = $self->set_working_dir();
    my $script = $self->{'transform-plugin-path'}.'/scripts/download/trns_transform_KBasePhenotypes_PhenotypeSet_to_TSV_PhenotypeSet.pl';

    my @args = ("perl", $script, 
                    '--object_name', $phenotype_set->{'phenotype_set_name'},
                    '--workspace_name', $phenotype_set->{'workspace_name'},
                    '--workspace_service_url', $self->{'workspace-url'});
    print("Running: @args \n");

    my $ret = system(@args);
    check_system_call($ret);

    # collect output
    my @files = get_result_files($output_dir);
    if( scalar(@files) != 1 ) {
        print("Generated : @files");
        die 'Incorrect number of files was generated! Expected 1 file.';
    }
    my $file_path = $output_dir . '/' . $files[0];
    if(exists $phenotype_set->{save_to_shock} && defined($phenotype_set->{save_to_shock}) && $phenotype_set->{save_to_shock}==1) {
        $f = { shock_id => $self->load_to_shock($file_path) };
    } else {
        $f = { path => $file_path };
    }

    #END phenotype_set_to_tsv_file
    my @_bad_returns;
    (ref($f) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"f\" (value was \"$f\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to phenotype_set_to_tsv_file:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'phenotype_set_to_tsv_file');
    }
    return($f);
}




=head2 export_phenotype_set_as_tsv_file

  $output = $obj->export_phenotype_set_as_tsv_file($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a FBAFileUtil.ExportParams
$output is a FBAFileUtil.ExportOutput
ExportParams is a reference to a hash where the following keys are defined:
	input_ref has a value which is a string
ExportOutput is a reference to a hash where the following keys are defined:
	shock_id has a value which is a string

</pre>

=end html

=begin text

$params is a FBAFileUtil.ExportParams
$output is a FBAFileUtil.ExportOutput
ExportParams is a reference to a hash where the following keys are defined:
	input_ref has a value which is a string
ExportOutput is a reference to a hash where the following keys are defined:
	shock_id has a value which is a string


=end text



=item Description



=back

=cut

sub export_phenotype_set_as_tsv_file
{
    my $self = shift;
    my($params) = @_;

    my @_bad_arguments;
    (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"params\" (value was \"$params\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to export_phenotype_set_as_tsv_file:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'export_phenotype_set_as_tsv_file');
    }

    my $ctx = $FBAFileUtil::FBAFileUtilServer::CallContext;
    my($output);
    #BEGIN export_phenotype_set_as_tsv_file

    my $funcname = 'export_phenotype_set_as_tsv_file';
    print("$funcname parameters:");
    print(Dumper($params));

    # validate parameters
    if(!exists($params->{input_ref}) ||  !defined($params->{input_ref})) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error => 'input_ref required field was not defined', method_name => $funcname);
    }

    # get WS metadata to get ws_name and obj_name
    my $ws = new Bio::KBase::workspace::Client($self->{'workspace-url'});
    my $info = $ws->get_object_info_new({ objects=>[ { ref=>$params->{input_ref} } ] })->[0];

    # export to a file using existing function
    my $files = $self->phenotype_set_to_tsv_file({
                                phenotype_set_name=> $info->[1],
                                workspace_name=> $info->[7]
                            });

    # create the output directory and move the file there
    my $export_dir = $self->{'scratch'}.'/'.$info->[1];
    mkdir $export_dir;
    my $success = move($files->{path}, $export_dir.'/'.basename($files->{path}));
    if(!$success) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error => 'could not move files to export dir: '.$export_dir,method_name => $funcname);
    }

    # package it up and be done
    my $dataUtil = DataFileUtil::DataFileUtilClient->new($self->{callbackURL});
    my $package_details = $dataUtil->package_for_download({ 
                                        file_path => $export_dir,
                                        ws_refs   => [ $params->{input_ref} ]
                                    });
    $output = { shock_id => $package_details->{shock_id} };


    #END export_phenotype_set_as_tsv_file
    my @_bad_returns;
    (ref($output) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"output\" (value was \"$output\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to export_phenotype_set_as_tsv_file:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'export_phenotype_set_as_tsv_file');
    }
    return($output);
}




=head2 phenotype_simulation_set_to_excel_file

  $f = $obj->phenotype_simulation_set_to_excel_file($pss)

=over 4

=item Parameter and return types

=begin html

<pre>
$pss is a FBAFileUtil.PhenotypeSimulationSetObjectSelectionParams
$f is a FBAFileUtil.File
PhenotypeSimulationSetObjectSelectionParams is a reference to a hash where the following keys are defined:
	workspace_name has a value which is a string
	phenotype_simulation_set_name has a value which is a string
	save_to_shock has a value which is a FBAFileUtil.boolean
boolean is an int
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string

</pre>

=end html

=begin text

$pss is a FBAFileUtil.PhenotypeSimulationSetObjectSelectionParams
$f is a FBAFileUtil.File
PhenotypeSimulationSetObjectSelectionParams is a reference to a hash where the following keys are defined:
	workspace_name has a value which is a string
	phenotype_simulation_set_name has a value which is a string
	save_to_shock has a value which is a FBAFileUtil.boolean
boolean is an int
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string


=end text



=item Description



=back

=cut

sub phenotype_simulation_set_to_excel_file
{
    my $self = shift;
    my($pss) = @_;

    my @_bad_arguments;
    (ref($pss) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"pss\" (value was \"$pss\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to phenotype_simulation_set_to_excel_file:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'phenotype_simulation_set_to_excel_file');
    }

    my $ctx = $FBAFileUtil::FBAFileUtilServer::CallContext;
    my($f);
    #BEGIN phenotype_simulation_set_to_excel_file
    print('phenotype_simulation_set_to_excel_file parameters:');
    print(Dumper($pss));

    # TODO: better input error checking
    my $output_dir = $self->set_working_dir();
    my $script = $self->{'transform-plugin-path'}.'/scripts/download/trns_transform_KBasePhenotypes_PhenotypeSimulationSet_to_Excel_PhenotypeSimulationSet.pl';

    my @args = ("perl", $script, 
                    '--object_name', $pss->{'phenotype_simulation_set_name'},
                    '--workspace_name', $pss->{'workspace_name'},
                    '--workspace_service_url', $self->{'workspace-url'});
    print("Running: @args \n");

    my $ret = system(@args);
    check_system_call($ret);

    # collect output
    my @files = get_result_files($output_dir);
    if( scalar(@files) != 1 ) {
        print("Generated : @files");
        die 'Incorrect number of files was generated! Expected 1 file.';
    }
    my $file_path = $output_dir . '/' . $files[0];
    if(exists $pss->{save_to_shock} && defined($pss->{save_to_shock}) && $pss->{save_to_shock}==1) {
        $f = { shock_id => $self->load_to_shock($file_path) };
    } else {
        $f = { path => $file_path };
    }


    #END phenotype_simulation_set_to_excel_file
    my @_bad_returns;
    (ref($f) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"f\" (value was \"$f\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to phenotype_simulation_set_to_excel_file:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'phenotype_simulation_set_to_excel_file');
    }
    return($f);
}




=head2 phenotype_simulation_set_to_tsv_file

  $f = $obj->phenotype_simulation_set_to_tsv_file($pss)

=over 4

=item Parameter and return types

=begin html

<pre>
$pss is a FBAFileUtil.PhenotypeSimulationSetObjectSelectionParams
$f is a FBAFileUtil.File
PhenotypeSimulationSetObjectSelectionParams is a reference to a hash where the following keys are defined:
	workspace_name has a value which is a string
	phenotype_simulation_set_name has a value which is a string
	save_to_shock has a value which is a FBAFileUtil.boolean
boolean is an int
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string

</pre>

=end html

=begin text

$pss is a FBAFileUtil.PhenotypeSimulationSetObjectSelectionParams
$f is a FBAFileUtil.File
PhenotypeSimulationSetObjectSelectionParams is a reference to a hash where the following keys are defined:
	workspace_name has a value which is a string
	phenotype_simulation_set_name has a value which is a string
	save_to_shock has a value which is a FBAFileUtil.boolean
boolean is an int
File is a reference to a hash where the following keys are defined:
	path has a value which is a string
	shock_id has a value which is a string


=end text



=item Description



=back

=cut

sub phenotype_simulation_set_to_tsv_file
{
    my $self = shift;
    my($pss) = @_;

    my @_bad_arguments;
    (ref($pss) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"pss\" (value was \"$pss\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to phenotype_simulation_set_to_tsv_file:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'phenotype_simulation_set_to_tsv_file');
    }

    my $ctx = $FBAFileUtil::FBAFileUtilServer::CallContext;
    my($f);
    #BEGIN phenotype_simulation_set_to_tsv_file
    print('phenotype_simulation_set_to_tsv_file parameters:');
    print(Dumper($pss));

        # TODO: better input error checking
    my $output_dir = $self->set_working_dir();
    my $script = $self->{'transform-plugin-path'}.'/scripts/download/trns_transform_KBasePhenotypes_PhenotypeSimulationSet_to_TSV_PhenotypeSimulationSet.pl';

    my @args = ("perl", $script, 
                    '--object_name', $pss->{'phenotype_simulation_set_name'},
                    '--workspace_name', $pss->{'workspace_name'},
                    '--workspace_service_url', $self->{'workspace-url'});
    print("Running: @args \n");

    my $ret = system(@args);
    check_system_call($ret);

    # collect output
    my @files = get_result_files($output_dir);
    if( scalar(@files) != 1 ) {
        print("Generated : @files");
        die 'Incorrect number of files was generated! Expected 1 file.';
    }
    my $file_path = $output_dir . '/' . $files[0];
    if(exists $pss->{save_to_shock} && defined($pss->{save_to_shock}) && $pss->{save_to_shock}==1) {
        $f = { shock_id => $self->load_to_shock($file_path) };
    } else {
        $f = { path => $file_path };
    }


    #END phenotype_simulation_set_to_tsv_file
    my @_bad_returns;
    (ref($f) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"f\" (value was \"$f\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to phenotype_simulation_set_to_tsv_file:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'phenotype_simulation_set_to_tsv_file');
    }
    return($f);
}




=head2 export_phenotype_simulation_set_as_excel_file

  $output = $obj->export_phenotype_simulation_set_as_excel_file($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a FBAFileUtil.ExportParams
$output is a FBAFileUtil.ExportOutput
ExportParams is a reference to a hash where the following keys are defined:
	input_ref has a value which is a string
ExportOutput is a reference to a hash where the following keys are defined:
	shock_id has a value which is a string

</pre>

=end html

=begin text

$params is a FBAFileUtil.ExportParams
$output is a FBAFileUtil.ExportOutput
ExportParams is a reference to a hash where the following keys are defined:
	input_ref has a value which is a string
ExportOutput is a reference to a hash where the following keys are defined:
	shock_id has a value which is a string


=end text



=item Description



=back

=cut

sub export_phenotype_simulation_set_as_excel_file
{
    my $self = shift;
    my($params) = @_;

    my @_bad_arguments;
    (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"params\" (value was \"$params\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to export_phenotype_simulation_set_as_excel_file:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'export_phenotype_simulation_set_as_excel_file');
    }

    my $ctx = $FBAFileUtil::FBAFileUtilServer::CallContext;
    my($output);
    #BEGIN export_phenotype_simulation_set_as_excel_file

    my $funcname = 'export_phenotype_simulation_set_as_excel_file';
    print("$funcname parameters:");
    print(Dumper($params));

    # validate parameters
    if(!exists($params->{input_ref}) ||  !defined($params->{input_ref})) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error => 'input_ref required field was not defined', method_name => $funcname);
    }

    # get WS metadata to get ws_name and obj_name
    my $ws = new Bio::KBase::workspace::Client($self->{'workspace-url'});
    my $info = $ws->get_object_info_new({ objects=>[ { ref=>$params->{input_ref} } ] })->[0];

    # export to a file using existing function
    my $files = $self->phenotype_simulation_set_to_excel_file({
                                phenotype_simulation_set_name=> $info->[1],
                                workspace_name=> $info->[7]
                            });

    # create the output directory and move the file there
    my $export_dir = $self->{'scratch'}.'/'.$info->[1];
    mkdir $export_dir;
    my $success = move($files->{path}, $export_dir.'/'.basename($files->{path}));
    if(!$success) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error => 'could not move files to export dir: '.$export_dir,method_name => $funcname);
    }

    # package it up and be done
    my $dataUtil = DataFileUtil::DataFileUtilClient->new($self->{callbackURL});
    my $package_details = $dataUtil->package_for_download({ 
                                        file_path => $export_dir,
                                        ws_refs   => [ $params->{input_ref} ]
                                    });
    $output = { shock_id => $package_details->{shock_id} };


    #END export_phenotype_simulation_set_as_excel_file
    my @_bad_returns;
    (ref($output) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"output\" (value was \"$output\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to export_phenotype_simulation_set_as_excel_file:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'export_phenotype_simulation_set_as_excel_file');
    }
    return($output);
}




=head2 export_phenotype_simulation_set_as_tsv_file

  $output = $obj->export_phenotype_simulation_set_as_tsv_file($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a FBAFileUtil.ExportParams
$output is a FBAFileUtil.ExportOutput
ExportParams is a reference to a hash where the following keys are defined:
	input_ref has a value which is a string
ExportOutput is a reference to a hash where the following keys are defined:
	shock_id has a value which is a string

</pre>

=end html

=begin text

$params is a FBAFileUtil.ExportParams
$output is a FBAFileUtil.ExportOutput
ExportParams is a reference to a hash where the following keys are defined:
	input_ref has a value which is a string
ExportOutput is a reference to a hash where the following keys are defined:
	shock_id has a value which is a string


=end text



=item Description



=back

=cut

sub export_phenotype_simulation_set_as_tsv_file
{
    my $self = shift;
    my($params) = @_;

    my @_bad_arguments;
    (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"params\" (value was \"$params\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to export_phenotype_simulation_set_as_tsv_file:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'export_phenotype_simulation_set_as_tsv_file');
    }

    my $ctx = $FBAFileUtil::FBAFileUtilServer::CallContext;
    my($output);
    #BEGIN export_phenotype_simulation_set_as_tsv_file

    my $funcname = 'export_phenotype_simulation_set_as_tsv_file';
    print("$funcname parameters:");
    print(Dumper($params));

    # validate parameters
    if(!exists($params->{input_ref}) ||  !defined($params->{input_ref})) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error => 'input_ref required field was not defined', method_name => $funcname);
    }

    # get WS metadata to get ws_name and obj_name
    my $ws = new Bio::KBase::workspace::Client($self->{'workspace-url'});
    my $info = $ws->get_object_info_new({ objects=>[ { ref=>$params->{input_ref} } ] })->[0];

    # export to a file using existing function
    my $files = $self->phenotype_simulation_set_to_tsv_file({
                                phenotype_simulation_set_name=> $info->[1],
                                workspace_name=> $info->[7]
                            });

    # create the output directory and move the file there
    my $export_dir = $self->{'scratch'}.'/'.$info->[1];
    mkdir $export_dir;
    my $success = move($files->{path}, $export_dir.'/'.basename($files->{path}));
    if(!$success) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error => 'could not move files to export dir: '.$export_dir,method_name => $funcname);
    }

    # package it up and be done
    my $dataUtil = DataFileUtil::DataFileUtilClient->new($self->{callbackURL});
    my $package_details = $dataUtil->package_for_download({ 
                                        file_path => $export_dir,
                                        ws_refs   => [ $params->{input_ref} ]
                                    });
    $output = { shock_id => $package_details->{shock_id} };

    
    #END export_phenotype_simulation_set_as_tsv_file
    my @_bad_returns;
    (ref($output) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"output\" (value was \"$output\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to export_phenotype_simulation_set_as_tsv_file:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'export_phenotype_simulation_set_as_tsv_file');
    }
    return($output);
}




=head2 status 

  $return = $obj->status()

=over 4

=item Parameter and return types

=begin html

<pre>
$return is a string
</pre>

=end html

=begin text

$return is a string

=end text

=item Description

Return the module status. This is a structure including Semantic Versioning number, state and git info.

=back

=cut

sub status {
    my($return);
    #BEGIN_STATUS
    $return = {"state" => "OK", "message" => "", "version" => $VERSION,
               "git_url" => $GIT_URL, "git_commit_hash" => $GIT_COMMIT_HASH};
    #END_STATUS
    return($return);
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



=head2 File

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
path has a value which is a string
shock_id has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
path has a value which is a string
shock_id has a value which is a string


=end text

=back



=head2 WorkspaceRef

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
ref has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
ref has a value which is a string


=end text

=back



=head2 ExportParams

=over 4



=item Description

input and output structure functions for standard downloaders


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
input_ref has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
input_ref has a value which is a string


=end text

=back



=head2 ExportOutput

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
shock_id has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
shock_id has a value which is a string


=end text

=back



=head2 ModelCreationParams

=over 4



=item Description

compounds_file is not used for excel file creations


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
model_file has a value which is a FBAFileUtil.File
model_name has a value which is a string
workspace_name has a value which is a string
genome has a value which is a string
biomass has a value which is a reference to a list where each element is a string
compounds_file has a value which is a FBAFileUtil.File

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
model_file has a value which is a FBAFileUtil.File
model_name has a value which is a string
workspace_name has a value which is a string
genome has a value which is a string
biomass has a value which is a reference to a list where each element is a string
compounds_file has a value which is a FBAFileUtil.File


=end text

=back



=head2 ModelObjectSelectionParams

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
workspace_name has a value which is a string
model_name has a value which is a string
save_to_shock has a value which is a FBAFileUtil.boolean

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
workspace_name has a value which is a string
model_name has a value which is a string
save_to_shock has a value which is a FBAFileUtil.boolean


=end text

=back



=head2 ModelTsvFiles

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
compounds_file has a value which is a FBAFileUtil.File
reactions_file has a value which is a FBAFileUtil.File

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
compounds_file has a value which is a FBAFileUtil.File
reactions_file has a value which is a FBAFileUtil.File


=end text

=back



=head2 FBAObjectSelectionParams

=over 4



=item Description

****** FBA Result Converters ******


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
workspace_name has a value which is a string
fba_name has a value which is a string
save_to_shock has a value which is a FBAFileUtil.boolean

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
workspace_name has a value which is a string
fba_name has a value which is a string
save_to_shock has a value which is a FBAFileUtil.boolean


=end text

=back



=head2 FBATsvFiles

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
compounds_file has a value which is a FBAFileUtil.File
reactions_file has a value which is a FBAFileUtil.File

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
compounds_file has a value which is a FBAFileUtil.File
reactions_file has a value which is a FBAFileUtil.File


=end text

=back



=head2 MediaCreationParams

=over 4



=item Description

****** Media Converters *********


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
media_file has a value which is a FBAFileUtil.File
media_name has a value which is a string
workspace_name has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
media_file has a value which is a FBAFileUtil.File
media_name has a value which is a string
workspace_name has a value which is a string


=end text

=back



=head2 MediaObjectSelectionParams

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
workspace_name has a value which is a string
media_name has a value which is a string
save_to_shock has a value which is a FBAFileUtil.boolean

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
workspace_name has a value which is a string
media_name has a value which is a string
save_to_shock has a value which is a FBAFileUtil.boolean


=end text

=back



=head2 PhenotypeSetCreationParams

=over 4



=item Description

****** Phenotype Data Converters *******


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
phenotype_set_file has a value which is a FBAFileUtil.File
phenotype_set_name has a value which is a string
workspace_name has a value which is a string
genome has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
phenotype_set_file has a value which is a FBAFileUtil.File
phenotype_set_name has a value which is a string
workspace_name has a value which is a string
genome has a value which is a string


=end text

=back



=head2 PhenotypeSetObjectSelectionParams

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
workspace_name has a value which is a string
phenotype_set_name has a value which is a string
save_to_shock has a value which is a FBAFileUtil.boolean

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
workspace_name has a value which is a string
phenotype_set_name has a value which is a string
save_to_shock has a value which is a FBAFileUtil.boolean


=end text

=back



=head2 PhenotypeSimulationSetObjectSelectionParams

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
workspace_name has a value which is a string
phenotype_simulation_set_name has a value which is a string
save_to_shock has a value which is a FBAFileUtil.boolean

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
workspace_name has a value which is a string
phenotype_simulation_set_name has a value which is a string
save_to_shock has a value which is a FBAFileUtil.boolean


=end text

=back



=cut

1;
