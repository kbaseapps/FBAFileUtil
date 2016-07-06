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

    typedef structure {
        File model_file;

        string model_name;
        string workspace_name;


    } ModelCreationParams;

    funcdef excel_file_to_model(ModelCreationParams p) returns(WorkspaceRef) authentication required;
    funcdef sbml_file_to_model(ModelCreationParams p) returns(WorkspaceRef) authentication required;
    funcdef tsv_file_to_model(ModelCreationParams p) returns(WorkspaceRef) authentication required;


    typedef structure {
        string workspace_name;
        string model_name;
    } ObjectSelection;

    funcdef model_to_excel_file(ObjectSelection model) returns(File f) authentication required;
    funcdef model_to_sbml_file(ObjectSelection model) returns(File f) authentication required;
    funcdef model_to_tsv_file(ObjectSelection model) returns(File f) authentication required;




    /******* FBA Result Converters *******/

    funcdef fba_to_excel_file(ObjectSelection fba) returns(File f) authentication required;
    funcdef fba_to_tsv_file(ObjectSelection fba) returns(File f) authentication required;



    /******* Media Converters **********/

    funcdef tsv_file_to_media() returns() authentication required;
    funcdef media_to_tsv_file(ObjectSelection media) returns(File f) authentication required;


    /******* Phenotype Data Converters ********/
    funcdef tsv_file_to_phenotype_set() returns () authentication required;
    funcdef phenotype_set_to_tsv_file(ObjectSelection phenotype) returns (File f) authentication required;


    funcdef phenotype_simulation_set_to_excel_file(ObjectSelection pss) returns (File f) authentication required;
    funcdef phenotype_simulation_set_to_tsv_file(ObjectSelection pss) returns (File f) authentication required;
    funcdef phenotype_simulation_set_to_excel_file(ObjectSelection pss) returns (File f) authentication required;



};
