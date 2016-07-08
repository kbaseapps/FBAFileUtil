
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
 * <p>Original spec-file type: PhenotypeSetObjectSelection</p>
 * 
 * 
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
@Generated("com.googlecode.jsonschema2pojo")
@JsonPropertyOrder({
    "workspace_name",
    "phenotype_set_name"
})
public class PhenotypeSetObjectSelection {

    @JsonProperty("workspace_name")
    private String workspaceName;
    @JsonProperty("phenotype_set_name")
    private String phenotypeSetName;
    private Map<String, Object> additionalProperties = new HashMap<String, Object>();

    @JsonProperty("workspace_name")
    public String getWorkspaceName() {
        return workspaceName;
    }

    @JsonProperty("workspace_name")
    public void setWorkspaceName(String workspaceName) {
        this.workspaceName = workspaceName;
    }

    public PhenotypeSetObjectSelection withWorkspaceName(String workspaceName) {
        this.workspaceName = workspaceName;
        return this;
    }

    @JsonProperty("phenotype_set_name")
    public String getPhenotypeSetName() {
        return phenotypeSetName;
    }

    @JsonProperty("phenotype_set_name")
    public void setPhenotypeSetName(String phenotypeSetName) {
        this.phenotypeSetName = phenotypeSetName;
    }

    public PhenotypeSetObjectSelection withPhenotypeSetName(String phenotypeSetName) {
        this.phenotypeSetName = phenotypeSetName;
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
        return ((((((("PhenotypeSetObjectSelection"+" [workspaceName=")+ workspaceName)+", phenotypeSetName=")+ phenotypeSetName)+", additionalProperties=")+ additionalProperties)+"]");
    }

}