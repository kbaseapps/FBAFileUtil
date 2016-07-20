/*

*/
module FBAFileUtil {

    /* A boolean - 0 for false, 1 for true.
       @range (0, 1)
    */
    typedef int boolean;

    typedef structure {
        string path;
        string shock_id;
    } File;

    typedef structure {
        string ref;
    } WorkspaceRef;


    /*  input and output structure functions for standard downloaders */
    typedef structure {
        string input_ref;
    } ExportParams;

    typedef structure {
        string shock_id;
    } ExportOutput;


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
        boolean save_to_shock;
    } ModelObjectSelectionParams;

    funcdef model_to_excel_file(ModelObjectSelectionParams model) returns(File f) authentication required;
    funcdef model_to_sbml_file(ModelObjectSelectionParams model) returns(File f) authentication required;

    typedef structure {
        File compounds_file;
        File reactions_file;
    } ModelTsvFiles;
    funcdef model_to_tsv_file(ModelObjectSelectionParams model) returns(ModelTsvFiles files) authentication required;

    funcdef export_model_as_excel_file(ExportParams params) returns (ExportOutput output) authentication required;
    funcdef export_model_as_tsv_file(ExportParams params) returns (ExportOutput output) authentication required;
    funcdef export_model_as_sbml_file(ExportParams params) returns (ExportOutput output) authentication required;



    /******* FBA Result Converters *******/

    typedef structure {
        string workspace_name;
        string fba_name;
        boolean save_to_shock;
    } FBAObjectSelectionParams;

    funcdef fba_to_excel_file(FBAObjectSelectionParams fba) returns(File f) authentication required;

    typedef structure {
        File compounds_file;
        File reactions_file;
    } FBATsvFiles;
    funcdef fba_to_tsv_file(FBAObjectSelectionParams fba) returns(FBATsvFiles files) authentication required;

    funcdef export_fba_as_excel_file(ExportParams params) returns (ExportOutput output) authentication required;
    funcdef export_fba_as_tsv_file(ExportParams params) returns (ExportOutput output) authentication required;
   

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
        boolean save_to_shock;
    } MediaObjectSelectionParams;

    funcdef media_to_tsv_file(MediaObjectSelectionParams media) returns(File f) authentication required;
    funcdef media_to_excel_file(MediaObjectSelectionParams media) returns(File f) authentication required;

    funcdef export_media_as_excel_file(ExportParams params) returns (ExportOutput output) authentication required;
    funcdef export_media_as_tsv_file(ExportParams params) returns (ExportOutput output) authentication required;
   

    /******* Phenotype Data Converters ********/

    typedef structure {
        File phenotype_set_file;
        string phenotype_set_name;
        string workspace_name;
        string genome;
    } PhenotypeSetCreationParams;

    funcdef tsv_file_to_phenotype_set(PhenotypeSetCreationParams p) returns (WorkspaceRef) authentication required;

    typedef structure {
        string workspace_name;
        string phenotype_set_name;
        boolean save_to_shock;
    } PhenotypeSetObjectSelectionParams;

    funcdef phenotype_set_to_tsv_file(PhenotypeSetObjectSelectionParams phenotype_set) returns (File f) authentication required;

    funcdef export_phenotype_set_as_tsv_file(ExportParams params) returns (ExportOutput output) authentication required;
    

    typedef structure {
        string workspace_name;
        string phenotype_simulation_set_name;
        boolean save_to_shock;
    } PhenotypeSimulationSetObjectSelectionParams;

    funcdef phenotype_simulation_set_to_excel_file(PhenotypeSimulationSetObjectSelectionParams pss) returns (File f) authentication required;
    funcdef phenotype_simulation_set_to_tsv_file(PhenotypeSimulationSetObjectSelectionParams pss) returns (File f) authentication required;

    funcdef export_phenotype_simulation_set_as_excel_file(ExportParams params) returns (ExportOutput output) authentication required;
    funcdef export_phenotype_simulation_set_as_tsv_file(ExportParams params) returns (ExportOutput output) authentication required;
    


};
