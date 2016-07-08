use strict;
use Data::Dumper;
use Test::More;
use Config::Simple;
use Time::HiRes qw(time);
use Bio::KBase::AuthToken;
use Bio::KBase::workspace::Client;
use FBAFileUtil::FBAFileUtilImpl;

local $| = 1;
my $token = $ENV{'KB_AUTH_TOKEN'};
my $config_file = $ENV{'KB_DEPLOYMENT_CONFIG'};
my $config = new Config::Simple($config_file)->get_block('FBAFileUtil');
my $ws_url = $config->{"workspace-url"};
my $ws_name = undef;
my $ws_client = new Bio::KBase::workspace::Client($ws_url,token => $token);
my $auth_token = Bio::KBase::AuthToken->new(token => $token, ignore_authrc => 1);
my $ctx = LocalCallContext->new($token, $auth_token->user_id);
$FBAFileUtil::FBAFileUtilServer::CallContext = $ctx;
my $impl = new FBAFileUtil::FBAFileUtilImpl();

sub get_ws_name {
    if (!defined($ws_name)) {
        my $suffix = int(time * 1000);
        $ws_name = 'test_FBAFileUtil_' . $suffix;
        $ws_client->create_workspace({workspace => $ws_name});
    }
    return $ws_name;
}

sub test_model_import_export {

    # Prepare test objects in workspace if needed using 
    # $ws_client->save_objects({workspace => get_ws_name(), objects => []});
    #

    
    # Model to/from Excel file
    my $retObj = $impl->excel_file_to_model({
                        model_name=>'excel_test_Rhodobacter.fbamdl', 
                        workspace_name=>get_ws_name(),
                        model_file=>{path=>'/kb/module/test/data/Sample_Model_Spreadsheet.xls'}
                    });
    print('New Model Ref: '.$retObj->{'ref'}."\n");
    my $retObj = $impl->excel_file_to_model({
                        model_name=>'excel_test_Rhodobacter.fbamdl', 
                        workspace_name=>get_ws_name(),
                        model_file=>{path=>'/kb/module/test/data/Sample_Model_Spreadsheet.xlsx'}
                    });
    print('New Model Ref: '.$retObj->{'ref'}."\n");

    my $info = $ws_client->get_object_info_new({ objects=>[ { ref=>$retObj->{'ref'} } ] })->[0];
    my $ret = $impl->model_to_excel_file({
                        model_name=>$info->[1], 
                        workspace_name=>$info->[7]
                    });
    print('Got excel file: '.$ret->{path}."\n");


    # Model to/from TSV file
    my $retObj = $impl->tsv_file_to_model({
                        model_name=>'tsv_test_Rhodobacter.fbamdl', 
                        workspace_name=>get_ws_name(),
                        model_file=>{path=>'/kb/module/test/data/Reactions.txt'},
                        compounds_file=>{path=>'/kb/module/test/data/compounds.txt'}
                    });
    print('New Model Ref: '.$retObj->{'ref'}."\n");

    my $info = $ws_client->get_object_info_new({ objects=>[ { ref=>$retObj->{'ref'} } ] })->[0];
    my $ret = $impl->model_to_tsv_file({
                        model_name=>$info->[1], 
                        workspace_name=>$info->[7]
                    });
    print('Got tsv file: '.Dumper($ret->{path})."\n");


    # Test To and From SBML File
    my $retObj = $impl->sbml_file_to_model({
                        model_name=>'sbml_test_Rhodobacter.fbamdl', 
                        workspace_name=>get_ws_name(),
                        model_file=>{path=>'/kb/module/test/data/test-sbml.xml'},
                        compounds_file=>{path=>'/kb/module/test/data/compounds.txt'}
                    });
    print('New Model Ref: '.$retObj->{'ref'}."\n");

    my $info = $ws_client->get_object_info_new({ objects=>[ { ref=>$retObj->{'ref'} } ] })->[0];
    my $ret = $impl->model_to_sbml_file({
                        model_name=>$info->[1], 
                        workspace_name=>$info->[7]
                    });
    print('Got file: '.$ret->{path}."\n");
}


sub test_media_import_export {

    # Media to/from Excel file
    my $retObj = $impl->excel_file_to_media({
                        media_name=>'excel_test_media', 
                        workspace_name=>get_ws_name(),
                        media_file=>{path=>'/kb/module/test/data/media_example.xlsx'}
                    });
    print('New Media Ref: '.$retObj->{'ref'}."\n");

    my $info = $ws_client->get_object_info_new({ objects=>[ { ref=>$retObj->{'ref'} } ] })->[0];
    my $ret = $impl->media_to_excel_file({
                        media_name=>$info->[1], 
                        workspace_name=>$info->[7]
                    });
    print('Got excel file: '.$ret->{path}."\n");

    # Media to/from TSV file
    my $retObj = $impl->tsv_file_to_media({
                        media_name=>'tsv_test_media', 
                        workspace_name=>get_ws_name(),
                        media_file=>{path=>'/kb/module/test/data/media_example.txt'}
                    });
    print('New Media Ref: '.$retObj->{'ref'}."\n");

    my $info = $ws_client->get_object_info_new({ objects=>[ { ref=>$retObj->{'ref'} } ] })->[0];
    my $ret = $impl->media_to_tsv_file({
                        media_name=>$info->[1], 
                        workspace_name=>$info->[7]
                    });
    print('Got tsv file: '.$ret->{path}."\n");
}

sub test_phenotype_set_import_export {

    # requires a media
    my $current_ws_name = get_ws_name();
    my $retObj = $impl->tsv_file_to_media({
                        media_name=>'tsv_test_media', 
                        workspace_name=>$current_ws_name,
                        media_file=>{path=>'/kb/module/test/data/media_example.txt'}
                    });
    my $info = $ws_client->get_object_info_new({ objects=>[ { ref=>$retObj->{'ref'} } ] })->[0];

    # create a test phenotype set file
    my $filename = '/kb/module/test/data/temp_test_phenotype_set_data.txt';
    open(my $fh, '>', $filename) or die "Could not open file '$filename' $!";
    print $fh "media\tmediaws\tgrowth\tgeneko\taddtlCpd\n";
    print $fh "tsv_test_media\t$current_ws_name\t1\tnone\tnone\n";
    close $fh;

    # Phenotype Set to/from TSV file
    my $retObj = $impl->tsv_file_to_phenotype_set({
                        phenotype_set_name=>'excel_test_phenotype_set', 
                        workspace_name=>get_ws_name(),
                        phenotype_set_file=>{path=>'/kb/module/test/data/temp_test_phenotype_set_data.txt'}
                    });
    print('New Phenotype Set Ref: '.$retObj->{'ref'}."\n");

    my $info = $ws_client->get_object_info_new({ objects=>[ { ref=>$retObj->{'ref'} } ] })->[0];
    my $ret = $impl->phenotype_set_to_tsv_file({
                        phenotype_set_name=>$info->[1], 
                        workspace_name=>$info->[7]
                    });
    print('Got tsv file: '.$ret->{path}."\n");
}




#######  actually run the tests here
eval {
    test_phenotype_set_import_export();

    test_media_import_export();

    test_model_import_export();

};
my $err = undef;
if ($@) {
    $err = $@;
}
eval {
    if (defined($ws_name)) {
        $ws_client->delete_workspace({workspace => $ws_name});
        print("Test workspace was deleted\n");
    }
};
if (defined($err)) {
    if(ref($err) eq "Bio::KBase::Exceptions::KBaseException") {
        die("Error while running tests: " . $err->trace->as_string);
    } else {
        die $err;
    }
}

{
    package LocalCallContext;
    use strict;
    sub new {
        my($class,$token,$user) = @_;
        my $self = {
            token => $token,
            user_id => $user
        };
        return bless $self, $class;
    }
    sub user_id {
        my($self) = @_;
        return $self->{user_id};
    }
    sub token {
        my($self) = @_;
        return $self->{token};
    }
    sub provenance {
        my($self) = @_;
        return [{'service' => 'FBAFileUtil', 'method' => 'please_never_use_it_in_production', 'method_params' => []}];
    }
    sub authenticated {
        return 1;
    }
    sub log_debug {
        my($self,$msg) = @_;
        print STDERR $msg."\n";
    }
    sub log_info {
        my($self,$msg) = @_;
        print STDERR $msg."\n";
    }
}
