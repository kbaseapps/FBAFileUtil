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
    #my $retObj = $impl->excel_file_to_model({
    #                    model_name=>'excel_test_Rhodobacter.fbamdl', 
    #                    workspace_name=>get_ws_name(),
    #                    model_file=>{path=>'/kb/module/test/data/Sample_Model_Spreadsheet.xls'}
    #                });
    #print('New Model Ref: '.$retObj->{'ref'}."\n");
    my $retObj = $impl->excel_file_to_model({
                        model_name=>'excel_test_Rhodobacter.fbamdl', 
                        workspace_name=>get_ws_name(),
                        model_file=>{path=>'/kb/module/test/data/Sample_Model_Spreadsheet.xlsx'}
                    });
    print('New Model Ref: '.$retObj->{'ref'}."\n");

    #####SHOCK DOWNLOAD/UPLOAD TEST
    my $info = $ws_client->get_object_info_new({ objects=>[ { ref=>$retObj->{'ref'} } ] })->[0];
    my $ret = $impl->model_to_excel_file({
                        model_name=>$info->[1], 
                        workspace_name=>$info->[7],
                        save_to_shock=>1
                    });
    print('Got excel file in shock node: '.$ret->{shock_id}."\n");

    # NOTE: This fails because the worksheets are incorrectly named in the Model download!
    #my $retObj = $impl->excel_file_to_model({
    #                    model_name=>'excel_test_Rhodobacter.fbamdl', 
    #                    workspace_name=>get_ws_name(),
    #                    model_file=>{shock_id=>$ret->{shock_id}}
    #                });
    #print('New Model Ref loaded from shock excel file: '.$retObj->{'ref'}."\n");
    ##### END SHOCK


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
    my $ret = $impl->model_to_tsv_file({
                        model_name=>$info->[1], 
                        workspace_name=>$info->[7],
                        save_to_shock=>1
                    });
    print('Got tsv files in shock nodes: '.Dumper($ret)."\n");


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
    my $ret = $impl->model_to_sbml_file({
                        model_name=>$info->[1], 
                        workspace_name=>$info->[7],
                        save_to_shock=>1
                    });
    print('Got sbml file in shock nodes: '.Dumper($ret)."\n");

    # also doesn't work to reupload sbml that was downloaded
    #my $retObj = $impl->sbml_file_to_model({
    #                    model_name=>'sbml_test_Rhodobacter.fbamdl2', 
    #                    workspace_name=>get_ws_name(),
    #                    model_file=>{shock_id=>$ret->{shock_id}}
    #                });
    #print('Reuploaded Model SBML from shock: '.$retObj->{'ref'}."\n");
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
    my $ret = $impl->media_to_excel_file({
                        media_name=>$info->[1], 
                        workspace_name=>$info->[7],
                        save_to_shock=>1
                    });
    print('Got excel file in shock nodes: '.$ret->{shock_id}."\n");

    # Again, does not work.
    #my $retObj = $impl->excel_file_to_media({
    #                    media_name=>'excel_test_media', 
    #                    workspace_name=>get_ws_name(),
    #                    media_file=>{shock_id=>$ret->{shock_id}}
    #                });
    #print('Reuploaded Media Ref from shock: '.$retObj->{'ref'}."\n");

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
    my $ret = $impl->media_to_tsv_file({
                        media_name=>$info->[1], 
                        workspace_name=>$info->[7],
                        save_to_shock=>1
                    });
    print('Got tsv file in shock node: '.$ret->{shock_id}."\n");

    my $retObj = $impl->tsv_file_to_media({
                        media_name=>'tsv_test_media', 
                        workspace_name=>get_ws_name(),
                        media_file=>{shock_id=>$ret->{shock_id}}
                    });
    print('Reuploaded Media Ref tsv from shock: '.$retObj->{'ref'}."\n");
}

sub test_phenotype_set_import_export {

    # requires a media, so save an example
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
                        phenotype_set_name=>'tsv_test_phenotype_set', 
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
    my $ret = $impl->phenotype_set_to_tsv_file({
                        phenotype_set_name=>$info->[1], 
                        workspace_name=>$info->[7],
                        save_to_shock=>1
                    });
    print('Got tsv file in shock node: '.$ret->{shock_id}."\n");

    my $retObj = $impl->tsv_file_to_phenotype_set({
                        phenotype_set_name=>'tsv_test_phenotype_set2', 
                        workspace_name=>get_ws_name(),
                        phenotype_set_file=>{shock_id=>$ret->{shock_id}}
                    });
    print('Reuploaded Phenotype Set Ref from shock: '.$retObj->{'ref'}."\n");
}


sub test_fba_export {

    # TODO: save fba from local file

    my $fba_ref = '8378/49/1';
    my $info = $ws_client->get_object_info_new({ objects=>[ { ref=>$fba_ref } ] })->[0];

    my $ret = $impl->fba_to_excel_file({
                        fba_name=>$info->[1], 
                        workspace_name=>$info->[7]
                    });
    print('Got FBA excel file: '.$ret->{path}."\n");
    my $ret = $impl->fba_to_excel_file({
                        fba_name=>$info->[1], 
                        workspace_name=>$info->[7],
                        save_to_shock=>1
                    });
    print('Got FBA excel file in shock node: '.$ret->{shock_id}."\n");

    my $ret = $impl->fba_to_tsv_file({
                        fba_name=>$info->[1], 
                        workspace_name=>$info->[7]
                    });
    print('Got FBA tsv file: '.Dumper($ret)."\n");

    my $ret = $impl->fba_to_tsv_file({
                        fba_name=>$info->[1], 
                        workspace_name=>$info->[7],
                        save_to_shock=>1
                    });
    print('Got FBA tsv file in shock node: '.$ret->{shock_id}."\n");
}


sub test_phenotype_simulation_set_export {

    # requires a model and phenotype set, and phenotype set requires a media, so save an example of each
    my $current_ws_name = get_ws_name();
    my $retObj = $impl->tsv_file_to_media({
                        media_name=>'tsv_test_media', 
                        workspace_name=>$current_ws_name,
                        media_file=>{path=>'/kb/module/test/data/media_example.txt'}
                    });
    my $media_ref = $retObj->{'ref'};
    #my $media_info = $ws_client->get_object_info_new({ objects=>[ { ref=>$media_ref } ] })->[0];

    # now a model
    my $retObj = $impl->tsv_file_to_model({
                        model_name=>'tsv_test_Rhodobacter.fbamdl', 
                        workspace_name=>get_ws_name(),
                        model_file=>{path=>'/kb/module/test/data/Reactions.txt'},
                        compounds_file=>{path=>'/kb/module/test/data/compounds.txt'}
                    });
    my $model_ref = $retObj->{'ref'};
    #my $model_info = $ws_client->get_object_info_new({ objects=>[ { ref=>$model_ref } ] })->[0];

    # now a phenotype
    my $filename = '/kb/module/test/data/temp_test_phenotype_set_data.txt';
    open(my $fh, '>', $filename) or die "Could not open file '$filename' $!";
    print $fh "media\tmediaws\tgrowth\tgeneko\taddtlCpd\n";
    print $fh "tsv_test_media\t$current_ws_name\t1\tnone\tnone\n";
    close $fh;

    my $retObj = $impl->tsv_file_to_phenotype_set({
                        phenotype_set_name=>'test_phenotype_set', 
                        workspace_name=>get_ws_name(),
                        phenotype_set_file=>{path=>'/kb/module/test/data/temp_test_phenotype_set_data.txt'}
                    });
    my $phenotype_ref = $retObj->{'ref'};
    #my $phenotype_info = $ws_client->get_object_info_new({ objects=>[ { ref=>$phenotype_ref } ] })->[0];
    my $phenotype_data = $ws_client->get_objects([ { ref=>$phenotype_ref } ] )->[0]->{data};
    #print('phenotype data: '.Dumper($phenotype_data)."\n");

    # now create a simple phenotype simulation set object and save it directly to the ws:
    # Example:
    #{
    #    "__VERSION__": 1,
    #    "fbamodel_ref": "1985/25/2",
    #    "id": "Rhodobacter_sphaeroides_2.4.1.phe.4.phenosim1",
    #    "phenotypeSimulations": [
    #        {
    #            "id": "Rhodobacter_sphaeroides_2.4.1.phe.4.phe.1.sim",
    #            "phenoclass": "CP",
    #            "phenotype_ref": "1985/38/1/phenotypes/id/Rhodobacter_sphaeroides_2.4.1.phe.4.phe.1",
    #            "simulatedGrowth": 1.09122,
    #            "simulatedGrowthFraction": 1
    #        }
    #    ],
    #    "phenotypeset_ref": "1985/38/1"
    #}
    my $pss = {
        '__VERSRION__'=>1,
        'id'=>'pheonsim1',
        'fbamodel_ref'=>$model_ref,
        'phenotypeset_ref'=>$phenotype_ref,
        'phenotypeSimulations'=>[
            {
                'id'=>'sim1',
                'phenoclass'=>'CP',
                'simulatedGrowth'=>1.09122,
                'simulatedGrowthFraction'=>1,
                'phenotype_ref'=>$phenotype_ref.'/phenotypes/id/'.$phenotype_data->{phenotypes}->[0]->{id}
            }
        ]
    };

    my $saveDataParams = {
        'type'=>'KBasePhenotypes.PhenotypeSimulationSet',
        'data'=>$pss,
        'name'=>'test_phenotype_simulation_set'
    };

    my $pss_info = $ws_client->save_objects({ workspace=>get_ws_name(), objects=>[ $saveDataParams ] } )->[0];

    # OK, finally we can try out the two downloader functions
    my $ret = $impl->phenotype_simulation_set_to_excel_file({
                        phenotype_simulation_set_name=>$pss_info->[1], 
                        workspace_name=>$pss_info->[7]
                    });
    print('Got phenotype_simulation_set excel file: '.$ret->{path}."\n");
    my $ret = $impl->phenotype_simulation_set_to_excel_file({
                        phenotype_simulation_set_name=>$pss_info->[1], 
                        workspace_name=>$pss_info->[7],
                        save_to_shock=>1
                    });
    print('Got phenotype_simulation_set excel file in shock node: '.$ret->{shock_id}."\n");
    ok(exists $ret->{shock_id} && $ret->{shock_id} ne '');

    my $ret = $impl->phenotype_simulation_set_to_tsv_file({
                        phenotype_simulation_set_name=>$pss_info->[1], 
                        workspace_name=>$pss_info->[7]
                    });
    print('Got phenotype_simulation_set tsv file: '.$ret->{path}."\n");
    ok(exists $ret->{path} && $ret->{path} ne '');
    my $ret = $impl->phenotype_simulation_set_to_tsv_file({
                        phenotype_simulation_set_name=>$pss_info->[1], 
                        workspace_name=>$pss_info->[7],
                        save_to_shock=>1
                    });
    print('Got phenotype_simulation_set tsv file in shock node: '.$ret->{shock_id}."\n");
    ok(exists $ret->{shock_id} && $ret->{shock_id} ne '');
}



#######  actually run the tests here
eval {

    test_model_import_export();

    test_media_import_export();

    # comment out this test because it requires FBA available in WS
    test_fba_export();

    test_phenotype_set_import_export();

    test_phenotype_simulation_set_export();

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
