
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
 * <p>Original spec-file type: PhenotypeObjectSelection</p>
 * 
 * 
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
@Generated("com.googlecode.jsonschema2pojo")
@JsonPropertyOrder({
    "workspace_name",
    "phenotype_name"
})
public class PhenotypeObjectSelection {

    @JsonProperty("workspace_name")
    private String workspaceName;
    @JsonProperty("phenotype_name")
    private String phenotypeName;
    private Map<String, Object> additionalProperties = new HashMap<String, Object>();

    @JsonProperty("workspace_name")
    public String getWorkspaceName() {
        return workspaceName;
    }

    @JsonProperty("workspace_name")
    public void setWorkspaceName(String workspaceName) {
        this.workspaceName = workspaceName;
    }

    public PhenotypeObjectSelection withWorkspaceName(String workspaceName) {
        this.workspaceName = workspaceName;
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

    public PhenotypeObjectSelection withPhenotypeName(String phenotypeName) {
        this.phenotypeName = phenotypeName;
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
        return ((((((("PhenotypeObjectSelection"+" [workspaceName=")+ workspaceName)+", phenotypeName=")+ phenotypeName)+", additionalProperties=")+ additionalProperties)+"]");
    }

}
