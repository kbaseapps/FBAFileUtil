/*

*/
module FBAFileUtil {

    typedef structure {
        string path;
    } File;

    typedef structure {
        string ref;
    } WorkspaceRef;


    /****** FBA Model Converters ********/

    /* compounds_file is not used for excel file creations */
    typedef structure {
        File model_file;

        string model_name;
        string workspace_name;

        string genome;
        list <string> biomass;
        File compounds_file;

    } ModelCreationParams;

    funcdef excel_file_to_model(ModelCreationParams p) returns(WorkspaceRef) authentication required;
    funcdef sbml_file_to_model(ModelCreationParams p) returns(WorkspaceRef) authentication required;
    funcdef tsv_file_to_model(ModelCreationParams p) returns(WorkspaceRef) authentication required;


    typedef structure {
        string workspace_name;
        string model_name;
    } ModelObjectSelection;

    funcdef model_to_excel_file(ModelObjectSelection model) returns(File f) authentication required;
    funcdef model_to_sbml_file(ModelObjectSelection model) returns(File f) authentication required;

    typedef structure {
        File compounds_file;
        File reactions_file;
    } ModelTsvFiles;
    funcdef model_to_tsv_file(ModelObjectSelection model) returns(ModelTsvFiles files) authentication required;




    /******* FBA Result Converters *******/

    typedef structure {
        string workspace_name;
        string fba_name;
    } FBAObjectSelection;

    funcdef fba_to_excel_file(FBAObjectSelection fba) returns(File f) authentication required;
    funcdef fba_to_tsv_file(FBAObjectSelection fba) returns(File f) authentication required;



    /******* Media Converters **********/

    typedef structure {
        File media_file;
        string media_name;
        string workspace_name;
    } MediaCreationParams;

    funcdef tsv_file_to_media(MediaCreationParams p) returns(WorkspaceRef) authentication required;
    funcdef excel_file_to_media(MediaCreationParams p) returns(WorkspaceRef) authentication required;


    typedef structure {
        string workspace_name;
        string media_name;
    } MediaObjectSelection;

    funcdef media_to_tsv_file(MediaObjectSelection media) returns(File f) authentication required;
    funcdef media_to_excel_file(MediaObjectSelection media) returns(File f) authentication required;


    /******* Phenotype Data Converters ********/

    typedef structure {
        File phenotype_file;
        string phenotype_name;
        string workspace_name;
        string genome;
    } PhenotypeCreationParams;

    funcdef tsv_file_to_phenotype_set(PhenotypeCreationParams p) returns (WorkspaceRef) authentication required;


    typedef structure {
        string workspace_name;
        string phenotype_name;
    } PhenotypeObjectSelection;

    funcdef phenotype_set_to_tsv_file(PhenotypeObjectSelection phenotype) returns (File f) authentication required;

    typedef structure {
        string workspace_name;
        string phenotype_name;
    } PhenotypeSetObjectSelection;

    funcdef phenotype_simulation_set_to_excel_file(PhenotypeSetObjectSelection pss) returns (File f) authentication required;
    funcdef phenotype_simulation_set_to_tsv_file(PhenotypeSetObjectSelection pss) returns (File f) authentication required;
    funcdef phenotype_simulation_set_to_excel_file(PhenotypeSetObjectSelection pss) returns (File f) authentication required;



};
