
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
 * <p>Original spec-file type: ModelCreationParams</p>
 * 
 * 
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
@Generated("com.googlecode.jsonschema2pojo")
@JsonPropertyOrder({
    "model_file",
    "model_name",
    "workspace_name"
})
public class ModelCreationParams {

    /**
     * <p>Original spec-file type: File</p>
     * <pre>
     * ***** FBA Model Converters *******
     * </pre>
     * 
     */
    @JsonProperty("model_file")
    private File modelFile;
    @JsonProperty("model_name")
    private String modelName;
    @JsonProperty("workspace_name")
    private String workspaceName;
    private Map<String, Object> additionalProperties = new HashMap<String, Object>();

    /**
     * <p>Original spec-file type: File</p>
     * <pre>
     * ***** FBA Model Converters *******
     * </pre>
     * 
     */
    @JsonProperty("model_file")
    public File getModelFile() {
        return modelFile;
    }

    /**
     * <p>Original spec-file type: File</p>
     * <pre>
     * ***** FBA Model Converters *******
     * </pre>
     * 
     */
    @JsonProperty("model_file")
    public void setModelFile(File modelFile) {
        this.modelFile = modelFile;
    }

    public ModelCreationParams withModelFile(File modelFile) {
        this.modelFile = modelFile;
        return this;
    }

    @JsonProperty("model_name")
    public String getModelName() {
        return modelName;
    }

    @JsonProperty("model_name")
    public void setModelName(String modelName) {
        this.modelName = modelName;
    }

    public ModelCreationParams withModelName(String modelName) {
        this.modelName = modelName;
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

    public ModelCreationParams withWorkspaceName(String workspaceName) {
        this.workspaceName = workspaceName;
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
        return ((((((((("ModelCreationParams"+" [modelFile=")+ modelFile)+", modelName=")+ modelName)+", workspaceName=")+ workspaceName)+", additionalProperties=")+ additionalProperties)+"]");
    }

}
