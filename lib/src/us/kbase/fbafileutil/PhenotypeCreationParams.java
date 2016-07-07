
package us.kbase.fbafileutil;

import java.util.HashMap;
import java.util.Map;
import javax.annotation.Generated;
import com.fasterxml.jackson.annotation.JsonAnyGetter;
import com.fasterxml.jackson.annotation.JsonAnySetter;
import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.annotation.JsonPropertyOrder;


/**
 * <p>Original spec-file type: PhenotypeCreationParams</p>
 * <pre>
 * ****** Phenotype Data Converters *******
 * </pre>
 * 
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
@Generated("com.googlecode.jsonschema2pojo")
@JsonPropertyOrder({
    "phenotype_file",
    "phenotype_name",
    "workspace_name",
    "genome"
})
public class PhenotypeCreationParams {

    /**
     * <p>Original spec-file type: File</p>
     * 
     * 
     */
    @JsonProperty("phenotype_file")
    private File phenotypeFile;
    @JsonProperty("phenotype_name")
    private String phenotypeName;
    @JsonProperty("workspace_name")
    private String workspaceName;
    @JsonProperty("genome")
    private String genome;
    private Map<String, Object> additionalProperties = new HashMap<String, Object>();

    /**
     * <p>Original spec-file type: File</p>
     * 
     * 
     */
    @JsonProperty("phenotype_file")
    public File getPhenotypeFile() {
        return phenotypeFile;
    }

    /**
     * <p>Original spec-file type: File</p>
     * 
     * 
     */
    @JsonProperty("phenotype_file")
    public void setPhenotypeFile(File phenotypeFile) {
        this.phenotypeFile = phenotypeFile;
    }

    public PhenotypeCreationParams withPhenotypeFile(File phenotypeFile) {
        this.phenotypeFile = phenotypeFile;
        return this;
    }

    @JsonProperty("phenotype_name")
    public String getPhenotypeName() {
        return phenotypeName;
    }

    @JsonProperty("phenotype_name")
    public void setPhenotypeName(String phenotypeName) {
        this.phenotypeName = phenotypeName;
    }

    public PhenotypeCreationParams withPhenotypeName(String phenotypeName) {
        this.phenotypeName = phenotypeName;
        return this;
    }

    @JsonProperty("workspace_name")
    public String getWorkspaceName() {
        return workspaceName;
    }

    @JsonProperty("workspace_name")
    public void setWorkspaceName(String workspaceName) {
        this.workspaceName = workspaceName;
    }

    public PhenotypeCreationParams withWorkspaceName(String workspaceName) {
        this.workspaceName = workspaceName;
        return this;
    }

    @JsonProperty("genome")
    public String getGenome() {
        return genome;
    }

    @JsonProperty("genome")
    public void setGenome(String genome) {
        this.genome = genome;
    }

    public PhenotypeCreationParams withGenome(String genome) {
        this.genome = genome;
        return this;
    }

    @JsonAnyGetter
    public Map<String, Object> getAdditionalProperties() {
        return this.additionalProperties;
    }

    @JsonAnySetter
    public void setAdditionalProperties(String name, Object value) {
        this.additionalProperties.put(name, value);
    }

    @Override
    public String toString() {
        return ((((((((((("PhenotypeCreationParams"+" [phenotypeFile=")+ phenotypeFile)+", phenotypeName=")+ phenotypeName)+", workspaceName=")+ workspaceName)+", genome=")+ genome)+", additionalProperties=")+ additionalProperties)+"]");
    }

}
