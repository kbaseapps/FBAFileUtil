package us.kbase.fbafileutil;

import com.fasterxml.jackson.core.type.TypeReference;
import java.io.File;
import java.io.IOException;
import java.net.URL;
import java.util.ArrayList;
import java.util.List;
import us.kbase.auth.AuthToken;
import us.kbase.common.service.JsonClientCaller;
import us.kbase.common.service.JsonClientException;
import us.kbase.common.service.RpcContext;
import us.kbase.common.service.UnauthorizedException;

/**
 * <p>Original spec-file module name: FBAFileUtil</p>
 * <pre>
 * </pre>
 */
public class FBAFileUtilClient {
    private JsonClientCaller caller;
    private String serviceVersion = null;


    /** Constructs a client with a custom URL and no user credentials.
     * @param url the URL of the service.
     */
    public FBAFileUtilClient(URL url) {
        caller = new JsonClientCaller(url);
    }
    /** Constructs a client with a custom URL.
     * @param url the URL of the service.
     * @param token the user's authorization token.
     * @throws UnauthorizedException if the token is not valid.
     * @throws IOException if an IOException occurs when checking the token's
     * validity.
     */
    public FBAFileUtilClient(URL url, AuthToken token) throws UnauthorizedException, IOException {
        caller = new JsonClientCaller(url, token);
    }

    /** Constructs a client with a custom URL.
     * @param url the URL of the service.
     * @param user the user name.
     * @param password the password for the user name.
     * @throws UnauthorizedException if the credentials are not valid.
     * @throws IOException if an IOException occurs when checking the user's
     * credentials.
     */
    public FBAFileUtilClient(URL url, String user, String password) throws UnauthorizedException, IOException {
        caller = new JsonClientCaller(url, user, password);
    }

    /** Get the token this client uses to communicate with the server.
     * @return the authorization token.
     */
    public AuthToken getToken() {
        return caller.getToken();
    }

    /** Get the URL of the service with which this client communicates.
     * @return the service URL.
     */
    public URL getURL() {
        return caller.getURL();
    }

    /** Set the timeout between establishing a connection to a server and
     * receiving a response. A value of zero or null implies no timeout.
     * @param milliseconds the milliseconds to wait before timing out when
     * attempting to read from a server.
     */
    public void setConnectionReadTimeOut(Integer milliseconds) {
        this.caller.setConnectionReadTimeOut(milliseconds);
    }

    /** Check if this client allows insecure http (vs https) connections.
     * @return true if insecure connections are allowed.
     */
    public boolean isInsecureHttpConnectionAllowed() {
        return caller.isInsecureHttpConnectionAllowed();
    }

    /** Deprecated. Use isInsecureHttpConnectionAllowed().
     * @deprecated
     */
    public boolean isAuthAllowedForHttp() {
        return caller.isAuthAllowedForHttp();
    }

    /** Set whether insecure http (vs https) connections should be allowed by
     * this client.
     * @param allowed true to allow insecure connections. Default false
     */
    public void setIsInsecureHttpConnectionAllowed(boolean allowed) {
        caller.setInsecureHttpConnectionAllowed(allowed);
    }

    /** Deprecated. Use setIsInsecureHttpConnectionAllowed().
     * @deprecated
     */
    public void setAuthAllowedForHttp(boolean isAuthAllowedForHttp) {
        caller.setAuthAllowedForHttp(isAuthAllowedForHttp);
    }

    /** Set whether all SSL certificates, including self-signed certificates,
     * should be trusted.
     * @param trustAll true to trust all certificates. Default false.
     */
    public void setAllSSLCertificatesTrusted(final boolean trustAll) {
        caller.setAllSSLCertificatesTrusted(trustAll);
    }
    
    /** Check if this client trusts all SSL certificates, including
     * self-signed certificates.
     * @return true if all certificates are trusted.
     */
    public boolean isAllSSLCertificatesTrusted() {
        return caller.isAllSSLCertificatesTrusted();
    }
    /** Sets streaming mode on. In this case, the data will be streamed to
     * the server in chunks as it is read from disk rather than buffered in
     * memory. Many servers are not compatible with this feature.
     * @param streamRequest true to set streaming mode on, false otherwise.
     */
    public void setStreamingModeOn(boolean streamRequest) {
        caller.setStreamingModeOn(streamRequest);
    }

    /** Returns true if streaming mode is on.
     * @return true if streaming mode is on.
     */
    public boolean isStreamingModeOn() {
        return caller.isStreamingModeOn();
    }

    public void _setFileForNextRpcResponse(File f) {
        caller.setFileForNextRpcResponse(f);
    }

    public String getServiceVersion() {
        return this.serviceVersion;
    }

    public void setServiceVersion(String newValue) {
        this.serviceVersion = newValue;
    }

    /**
     * <p>Original spec-file function name: excel_file_to_model</p>
     * <pre>
     * </pre>
     * @param   p   instance of type {@link us.kbase.fbafileutil.ModelCreationParams ModelCreationParams}
     * @return   instance of type {@link us.kbase.fbafileutil.WorkspaceRef WorkspaceRef}
     * @throws IOException if an IO exception occurs
     * @throws JsonClientException if a JSON RPC exception occurs
     */
    public WorkspaceRef excelFileToModel(ModelCreationParams p, RpcContext... jsonRpcContext) throws IOException, JsonClientException {
        List<Object> args = new ArrayList<Object>();
        args.add(p);
        TypeReference<List<WorkspaceRef>> retType = new TypeReference<List<WorkspaceRef>>() {};
        List<WorkspaceRef> res = caller.jsonrpcCall("FBAFileUtil.excel_file_to_model", args, retType, true, true, jsonRpcContext, this.serviceVersion);
        return res.get(0);
    }

    /**
     * <p>Original spec-file function name: sbml_file_to_model</p>
     * <pre>
     * </pre>
     * @param   p   instance of type {@link us.kbase.fbafileutil.ModelCreationParams ModelCreationParams}
     * @return   instance of type {@link us.kbase.fbafileutil.WorkspaceRef WorkspaceRef}
     * @throws IOException if an IO exception occurs
     * @throws JsonClientException if a JSON RPC exception occurs
     */
    public WorkspaceRef sbmlFileToModel(ModelCreationParams p, RpcContext... jsonRpcContext) throws IOException, JsonClientException {
        List<Object> args = new ArrayList<Object>();
        args.add(p);
        TypeReference<List<WorkspaceRef>> retType = new TypeReference<List<WorkspaceRef>>() {};
        List<WorkspaceRef> res = caller.jsonrpcCall("FBAFileUtil.sbml_file_to_model", args, retType, true, true, jsonRpcContext, this.serviceVersion);
        return res.get(0);
    }

    /**
     * <p>Original spec-file function name: tsv_file_to_model</p>
     * <pre>
     * </pre>
     * @param   p   instance of type {@link us.kbase.fbafileutil.ModelCreationParams ModelCreationParams}
     * @return   instance of type {@link us.kbase.fbafileutil.WorkspaceRef WorkspaceRef}
     * @throws IOException if an IO exception occurs
     * @throws JsonClientException if a JSON RPC exception occurs
     */
    public WorkspaceRef tsvFileToModel(ModelCreationParams p, RpcContext... jsonRpcContext) throws IOException, JsonClientException {
        List<Object> args = new ArrayList<Object>();
        args.add(p);
        TypeReference<List<WorkspaceRef>> retType = new TypeReference<List<WorkspaceRef>>() {};
        List<WorkspaceRef> res = caller.jsonrpcCall("FBAFileUtil.tsv_file_to_model", args, retType, true, true, jsonRpcContext, this.serviceVersion);
        return res.get(0);
    }

    /**
     * <p>Original spec-file function name: model_to_excel_file</p>
     * <pre>
     * </pre>
     * @param   model   instance of type {@link us.kbase.fbafileutil.ObjectSelection ObjectSelection}
     * @return   parameter "f" of type {@link us.kbase.fbafileutil.File File}
     * @throws IOException if an IO exception occurs
     * @throws JsonClientException if a JSON RPC exception occurs
     */
    public us.kbase.fbafileutil.File modelToExcelFile(ObjectSelection model, RpcContext... jsonRpcContext) throws IOException, JsonClientException {
        List<Object> args = new ArrayList<Object>();
        args.add(model);
        TypeReference<List<us.kbase.fbafileutil.File>> retType = new TypeReference<List<us.kbase.fbafileutil.File>>() {};
        List<us.kbase.fbafileutil.File> res = caller.jsonrpcCall("FBAFileUtil.model_to_excel_file", args, retType, true, true, jsonRpcContext, this.serviceVersion);
        return res.get(0);
    }

    /**
     * <p>Original spec-file function name: model_to_sbml_file</p>
     * <pre>
     * </pre>
     * @param   model   instance of type {@link us.kbase.fbafileutil.ObjectSelection ObjectSelection}
     * @return   parameter "f" of type {@link us.kbase.fbafileutil.File File}
     * @throws IOException if an IO exception occurs
     * @throws JsonClientException if a JSON RPC exception occurs
     */
    public us.kbase.fbafileutil.File modelToSbmlFile(ObjectSelection model, RpcContext... jsonRpcContext) throws IOException, JsonClientException {
        List<Object> args = new ArrayList<Object>();
        args.add(model);
        TypeReference<List<us.kbase.fbafileutil.File>> retType = new TypeReference<List<us.kbase.fbafileutil.File>>() {};
        List<us.kbase.fbafileutil.File> res = caller.jsonrpcCall("FBAFileUtil.model_to_sbml_file", args, retType, true, true, jsonRpcContext, this.serviceVersion);
        return res.get(0);
    }

    /**
     * <p>Original spec-file function name: model_to_tsv_file</p>
     * <pre>
     * </pre>
     * @param   model   instance of type {@link us.kbase.fbafileutil.ObjectSelection ObjectSelection}
     * @return   parameter "f" of type {@link us.kbase.fbafileutil.File File}
     * @throws IOException if an IO exception occurs
     * @throws JsonClientException if a JSON RPC exception occurs
     */
    public us.kbase.fbafileutil.File modelToTsvFile(ObjectSelection model, RpcContext... jsonRpcContext) throws IOException, JsonClientException {
        List<Object> args = new ArrayList<Object>();
        args.add(model);
        TypeReference<List<us.kbase.fbafileutil.File>> retType = new TypeReference<List<us.kbase.fbafileutil.File>>() {};
        List<us.kbase.fbafileutil.File> res = caller.jsonrpcCall("FBAFileUtil.model_to_tsv_file", args, retType, true, true, jsonRpcContext, this.serviceVersion);
        return res.get(0);
    }

    /**
     * <p>Original spec-file function name: fba_to_excel_file</p>
     * <pre>
     * ****** FBA Result Converters ******
     * </pre>
     * @param   fba   instance of type {@link us.kbase.fbafileutil.ObjectSelection ObjectSelection}
     * @return   parameter "f" of type {@link us.kbase.fbafileutil.File File}
     * @throws IOException if an IO exception occurs
     * @throws JsonClientException if a JSON RPC exception occurs
     */
    public us.kbase.fbafileutil.File fbaToExcelFile(ObjectSelection fba, RpcContext... jsonRpcContext) throws IOException, JsonClientException {
        List<Object> args = new ArrayList<Object>();
        args.add(fba);
        TypeReference<List<us.kbase.fbafileutil.File>> retType = new TypeReference<List<us.kbase.fbafileutil.File>>() {};
        List<us.kbase.fbafileutil.File> res = caller.jsonrpcCall("FBAFileUtil.fba_to_excel_file", args, retType, true, true, jsonRpcContext, this.serviceVersion);
        return res.get(0);
    }

    /**
     * <p>Original spec-file function name: fba_to_tsv_file</p>
     * <pre>
     * </pre>
     * @param   fba   instance of type {@link us.kbase.fbafileutil.ObjectSelection ObjectSelection}
     * @return   parameter "f" of type {@link us.kbase.fbafileutil.File File}
     * @throws IOException if an IO exception occurs
     * @throws JsonClientException if a JSON RPC exception occurs
     */
    public us.kbase.fbafileutil.File fbaToTsvFile(ObjectSelection fba, RpcContext... jsonRpcContext) throws IOException, JsonClientException {
        List<Object> args = new ArrayList<Object>();
        args.add(fba);
        TypeReference<List<us.kbase.fbafileutil.File>> retType = new TypeReference<List<us.kbase.fbafileutil.File>>() {};
        List<us.kbase.fbafileutil.File> res = caller.jsonrpcCall("FBAFileUtil.fba_to_tsv_file", args, retType, true, true, jsonRpcContext, this.serviceVersion);
        return res.get(0);
    }

    /**
     * <p>Original spec-file function name: tsv_file_to_media</p>
     * <pre>
     * ****** Media Converters *********
     * </pre>
     * @throws IOException if an IO exception occurs
     * @throws JsonClientException if a JSON RPC exception occurs
     */
    public void tsvFileToMedia(RpcContext... jsonRpcContext) throws IOException, JsonClientException {
        List<Object> args = new ArrayList<Object>();
        TypeReference<Object> retType = new TypeReference<Object>() {};
        caller.jsonrpcCall("FBAFileUtil.tsv_file_to_media", args, retType, false, true, jsonRpcContext, this.serviceVersion);
    }

    /**
     * <p>Original spec-file function name: media_to_tsv_file</p>
     * <pre>
     * </pre>
     * @param   media   instance of type {@link us.kbase.fbafileutil.ObjectSelection ObjectSelection}
     * @return   parameter "f" of type {@link us.kbase.fbafileutil.File File}
     * @throws IOException if an IO exception occurs
     * @throws JsonClientException if a JSON RPC exception occurs
     */
    public us.kbase.fbafileutil.File mediaToTsvFile(ObjectSelection media, RpcContext... jsonRpcContext) throws IOException, JsonClientException {
        List<Object> args = new ArrayList<Object>();
        args.add(media);
        TypeReference<List<us.kbase.fbafileutil.File>> retType = new TypeReference<List<us.kbase.fbafileutil.File>>() {};
        List<us.kbase.fbafileutil.File> res = caller.jsonrpcCall("FBAFileUtil.media_to_tsv_file", args, retType, true, true, jsonRpcContext, this.serviceVersion);
        return res.get(0);
    }

    /**
     * <p>Original spec-file function name: tsv_file_to_phenotype_set</p>
     * <pre>
     * ****** Phenotype Data Converters *******
     * </pre>
     * @throws IOException if an IO exception occurs
     * @throws JsonClientException if a JSON RPC exception occurs
     */
    public void tsvFileToPhenotypeSet(RpcContext... jsonRpcContext) throws IOException, JsonClientException {
        List<Object> args = new ArrayList<Object>();
        TypeReference<Object> retType = new TypeReference<Object>() {};
        caller.jsonrpcCall("FBAFileUtil.tsv_file_to_phenotype_set", args, retType, false, true, jsonRpcContext, this.serviceVersion);
    }

    /**
     * <p>Original spec-file function name: phenotype_set_to_tsv_file</p>
     * <pre>
     * </pre>
     * @param   phenotype   instance of type {@link us.kbase.fbafileutil.ObjectSelection ObjectSelection}
     * @return   parameter "f" of type {@link us.kbase.fbafileutil.File File}
     * @throws IOException if an IO exception occurs
     * @throws JsonClientException if a JSON RPC exception occurs
     */
    public us.kbase.fbafileutil.File phenotypeSetToTsvFile(ObjectSelection phenotype, RpcContext... jsonRpcContext) throws IOException, JsonClientException {
        List<Object> args = new ArrayList<Object>();
        args.add(phenotype);
        TypeReference<List<us.kbase.fbafileutil.File>> retType = new TypeReference<List<us.kbase.fbafileutil.File>>() {};
        List<us.kbase.fbafileutil.File> res = caller.jsonrpcCall("FBAFileUtil.phenotype_set_to_tsv_file", args, retType, true, true, jsonRpcContext, this.serviceVersion);
        return res.get(0);
    }

    /**
     * <p>Original spec-file function name: phenotype_simulation_set_to_excel_file</p>
     * <pre>
     * </pre>
     * @param   pss   instance of type {@link us.kbase.fbafileutil.ObjectSelection ObjectSelection}
     * @return   parameter "f" of type {@link us.kbase.fbafileutil.File File}
     * @throws IOException if an IO exception occurs
     * @throws JsonClientException if a JSON RPC exception occurs
     */
    public us.kbase.fbafileutil.File phenotypeSimulationSetToExcelFile(ObjectSelection pss, RpcContext... jsonRpcContext) throws IOException, JsonClientException {
        List<Object> args = new ArrayList<Object>();
        args.add(pss);
        TypeReference<List<us.kbase.fbafileutil.File>> retType = new TypeReference<List<us.kbase.fbafileutil.File>>() {};
        List<us.kbase.fbafileutil.File> res = caller.jsonrpcCall("FBAFileUtil.phenotype_simulation_set_to_excel_file", args, retType, true, true, jsonRpcContext, this.serviceVersion);
        return res.get(0);
    }

    /**
     * <p>Original spec-file function name: phenotype_simulation_set_to_tsv_file</p>
     * <pre>
     * </pre>
     * @param   pss   instance of type {@link us.kbase.fbafileutil.ObjectSelection ObjectSelection}
     * @return   parameter "f" of type {@link us.kbase.fbafileutil.File File}
     * @throws IOException if an IO exception occurs
     * @throws JsonClientException if a JSON RPC exception occurs
     */
    public us.kbase.fbafileutil.File phenotypeSimulationSetToTsvFile(ObjectSelection pss, RpcContext... jsonRpcContext) throws IOException, JsonClientException {
        List<Object> args = new ArrayList<Object>();
        args.add(pss);
        TypeReference<List<us.kbase.fbafileutil.File>> retType = new TypeReference<List<us.kbase.fbafileutil.File>>() {};
        List<us.kbase.fbafileutil.File> res = caller.jsonrpcCall("FBAFileUtil.phenotype_simulation_set_to_tsv_file", args, retType, true, true, jsonRpcContext, this.serviceVersion);
        return res.get(0);
    }

    /**
     * <p>Original spec-file function name: phenotype_simulation_set_to_excel_file</p>
     * <pre>
     * </pre>
     * @param   pss   instance of type {@link us.kbase.fbafileutil.ObjectSelection ObjectSelection}
     * @return   parameter "f" of type {@link us.kbase.fbafileutil.File File}
     * @throws IOException if an IO exception occurs
     * @throws JsonClientException if a JSON RPC exception occurs
     */
    public us.kbase.fbafileutil.File phenotypeSimulationSetToExcelFile(ObjectSelection pss, RpcContext... jsonRpcContext) throws IOException, JsonClientException {
        List<Object> args = new ArrayList<Object>();
        args.add(pss);
        TypeReference<List<us.kbase.fbafileutil.File>> retType = new TypeReference<List<us.kbase.fbafileutil.File>>() {};
        List<us.kbase.fbafileutil.File> res = caller.jsonrpcCall("FBAFileUtil.phenotype_simulation_set_to_excel_file", args, retType, true, true, jsonRpcContext, this.serviceVersion);
        return res.get(0);
    }
}
