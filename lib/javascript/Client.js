

function FBAFileUtil(url, auth, auth_cb, timeout, async_job_check_time_ms, service_version) {
    var self = this;

    this.url = url;
    var _url = url;

    this.timeout = timeout;
    var _timeout = timeout;
    
    this.async_job_check_time_ms = async_job_check_time_ms;
    if (!this.async_job_check_time_ms)
        this.async_job_check_time_ms = 5000;
    this.service_version = service_version;

    var _auth = auth ? auth : { 'token' : '', 'user_id' : ''};
    var _auth_cb = auth_cb;

     this.excel_file_to_model = function (p, _callback, _errorCallback) {
        if (typeof p === 'function')
            throw 'Argument p can not be a function';
        if (_callback && typeof _callback !== 'function')
            throw 'Argument _callback must be a function if defined';
        if (_errorCallback && typeof _errorCallback !== 'function')
            throw 'Argument _errorCallback must be a function if defined';
        if (typeof arguments === 'function' && arguments.length > 1+2)
            throw 'Too many arguments ('+arguments.length+' instead of '+(1+2)+')';
        return json_call_ajax(_url, "FBAFileUtil.excel_file_to_model",
            [p], 1, _callback, _errorCallback);
    };
 
     this.sbml_file_to_model = function (p, _callback, _errorCallback) {
        if (typeof p === 'function')
            throw 'Argument p can not be a function';
        if (_callback && typeof _callback !== 'function')
            throw 'Argument _callback must be a function if defined';
        if (_errorCallback && typeof _errorCallback !== 'function')
            throw 'Argument _errorCallback must be a function if defined';
        if (typeof arguments === 'function' && arguments.length > 1+2)
            throw 'Too many arguments ('+arguments.length+' instead of '+(1+2)+')';
        return json_call_ajax(_url, "FBAFileUtil.sbml_file_to_model",
            [p], 1, _callback, _errorCallback);
    };
 
     this.tsv_file_to_model = function (p, _callback, _errorCallback) {
        if (typeof p === 'function')
            throw 'Argument p can not be a function';
        if (_callback && typeof _callback !== 'function')
            throw 'Argument _callback must be a function if defined';
        if (_errorCallback && typeof _errorCallback !== 'function')
            throw 'Argument _errorCallback must be a function if defined';
        if (typeof arguments === 'function' && arguments.length > 1+2)
            throw 'Too many arguments ('+arguments.length+' instead of '+(1+2)+')';
        return json_call_ajax(_url, "FBAFileUtil.tsv_file_to_model",
            [p], 1, _callback, _errorCallback);
    };
 
     this.model_to_excel_file = function (model, _callback, _errorCallback) {
        if (typeof model === 'function')
            throw 'Argument model can not be a function';
        if (_callback && typeof _callback !== 'function')
            throw 'Argument _callback must be a function if defined';
        if (_errorCallback && typeof _errorCallback !== 'function')
            throw 'Argument _errorCallback must be a function if defined';
        if (typeof arguments === 'function' && arguments.length > 1+2)
            throw 'Too many arguments ('+arguments.length+' instead of '+(1+2)+')';
        return json_call_ajax(_url, "FBAFileUtil.model_to_excel_file",
            [model], 1, _callback, _errorCallback);
    };
 
     this.model_to_sbml_file = function (model, _callback, _errorCallback) {
        if (typeof model === 'function')
            throw 'Argument model can not be a function';
        if (_callback && typeof _callback !== 'function')
            throw 'Argument _callback must be a function if defined';
        if (_errorCallback && typeof _errorCallback !== 'function')
            throw 'Argument _errorCallback must be a function if defined';
        if (typeof arguments === 'function' && arguments.length > 1+2)
            throw 'Too many arguments ('+arguments.length+' instead of '+(1+2)+')';
        return json_call_ajax(_url, "FBAFileUtil.model_to_sbml_file",
            [model], 1, _callback, _errorCallback);
    };
 
     this.model_to_tsv_file = function (model, _callback, _errorCallback) {
        if (typeof model === 'function')
            throw 'Argument model can not be a function';
        if (_callback && typeof _callback !== 'function')
            throw 'Argument _callback must be a function if defined';
        if (_errorCallback && typeof _errorCallback !== 'function')
            throw 'Argument _errorCallback must be a function if defined';
        if (typeof arguments === 'function' && arguments.length > 1+2)
            throw 'Too many arguments ('+arguments.length+' instead of '+(1+2)+')';
        return json_call_ajax(_url, "FBAFileUtil.model_to_tsv_file",
            [model], 1, _callback, _errorCallback);
    };
 
     this.fba_to_excel_file = function (fba, _callback, _errorCallback) {
        if (typeof fba === 'function')
            throw 'Argument fba can not be a function';
        if (_callback && typeof _callback !== 'function')
            throw 'Argument _callback must be a function if defined';
        if (_errorCallback && typeof _errorCallback !== 'function')
            throw 'Argument _errorCallback must be a function if defined';
        if (typeof arguments === 'function' && arguments.length > 1+2)
            throw 'Too many arguments ('+arguments.length+' instead of '+(1+2)+')';
        return json_call_ajax(_url, "FBAFileUtil.fba_to_excel_file",
            [fba], 1, _callback, _errorCallback);
    };
 
     this.fba_to_tsv_file = function (fba, _callback, _errorCallback) {
        if (typeof fba === 'function')
            throw 'Argument fba can not be a function';
        if (_callback && typeof _callback !== 'function')
            throw 'Argument _callback must be a function if defined';
        if (_errorCallback && typeof _errorCallback !== 'function')
            throw 'Argument _errorCallback must be a function if defined';
        if (typeof arguments === 'function' && arguments.length > 1+2)
            throw 'Too many arguments ('+arguments.length+' instead of '+(1+2)+')';
        return json_call_ajax(_url, "FBAFileUtil.fba_to_tsv_file",
            [fba], 1, _callback, _errorCallback);
    };
 
     this.tsv_file_to_media = function (_callback, _errorCallback) {
        if (_callback && typeof _callback !== 'function')
            throw 'Argument _callback must be a function if defined';
        if (_errorCallback && typeof _errorCallback !== 'function')
            throw 'Argument _errorCallback must be a function if defined';
        if (typeof arguments === 'function' && arguments.length > 0+2)
            throw 'Too many arguments ('+arguments.length+' instead of '+(0+2)+')';
        return json_call_ajax(_url, "FBAFileUtil.tsv_file_to_media",
            [], 0, _callback, _errorCallback);
    };
 
     this.media_to_tsv_file = function (media, _callback, _errorCallback) {
        if (typeof media === 'function')
            throw 'Argument media can not be a function';
        if (_callback && typeof _callback !== 'function')
            throw 'Argument _callback must be a function if defined';
        if (_errorCallback && typeof _errorCallback !== 'function')
            throw 'Argument _errorCallback must be a function if defined';
        if (typeof arguments === 'function' && arguments.length > 1+2)
            throw 'Too many arguments ('+arguments.length+' instead of '+(1+2)+')';
        return json_call_ajax(_url, "FBAFileUtil.media_to_tsv_file",
            [media], 1, _callback, _errorCallback);
    };
 
     this.tsv_file_to_phenotype_set = function (_callback, _errorCallback) {
        if (_callback && typeof _callback !== 'function')
            throw 'Argument _callback must be a function if defined';
        if (_errorCallback && typeof _errorCallback !== 'function')
            throw 'Argument _errorCallback must be a function if defined';
        if (typeof arguments === 'function' && arguments.length > 0+2)
            throw 'Too many arguments ('+arguments.length+' instead of '+(0+2)+')';
        return json_call_ajax(_url, "FBAFileUtil.tsv_file_to_phenotype_set",
            [], 0, _callback, _errorCallback);
    };
 
     this.phenotype_set_to_tsv_file = function (phenotype, _callback, _errorCallback) {
        if (typeof phenotype === 'function')
            throw 'Argument phenotype can not be a function';
        if (_callback && typeof _callback !== 'function')
            throw 'Argument _callback must be a function if defined';
        if (_errorCallback && typeof _errorCallback !== 'function')
            throw 'Argument _errorCallback must be a function if defined';
        if (typeof arguments === 'function' && arguments.length > 1+2)
            throw 'Too many arguments ('+arguments.length+' instead of '+(1+2)+')';
        return json_call_ajax(_url, "FBAFileUtil.phenotype_set_to_tsv_file",
            [phenotype], 1, _callback, _errorCallback);
    };
 
     this.phenotype_simulation_set_to_excel_file = function (pss, _callback, _errorCallback) {
        if (typeof pss === 'function')
            throw 'Argument pss can not be a function';
        if (_callback && typeof _callback !== 'function')
            throw 'Argument _callback must be a function if defined';
        if (_errorCallback && typeof _errorCallback !== 'function')
            throw 'Argument _errorCallback must be a function if defined';
        if (typeof arguments === 'function' && arguments.length > 1+2)
            throw 'Too many arguments ('+arguments.length+' instead of '+(1+2)+')';
        return json_call_ajax(_url, "FBAFileUtil.phenotype_simulation_set_to_excel_file",
            [pss], 1, _callback, _errorCallback);
    };
 
     this.phenotype_simulation_set_to_tsv_file = function (pss, _callback, _errorCallback) {
        if (typeof pss === 'function')
            throw 'Argument pss can not be a function';
        if (_callback && typeof _callback !== 'function')
            throw 'Argument _callback must be a function if defined';
        if (_errorCallback && typeof _errorCallback !== 'function')
            throw 'Argument _errorCallback must be a function if defined';
        if (typeof arguments === 'function' && arguments.length > 1+2)
            throw 'Too many arguments ('+arguments.length+' instead of '+(1+2)+')';
        return json_call_ajax(_url, "FBAFileUtil.phenotype_simulation_set_to_tsv_file",
            [pss], 1, _callback, _errorCallback);
    };
 
     this.phenotype_simulation_set_to_excel_file = function (pss, _callback, _errorCallback) {
        if (typeof pss === 'function')
            throw 'Argument pss can not be a function';
        if (_callback && typeof _callback !== 'function')
            throw 'Argument _callback must be a function if defined';
        if (_errorCallback && typeof _errorCallback !== 'function')
            throw 'Argument _errorCallback must be a function if defined';
        if (typeof arguments === 'function' && arguments.length > 1+2)
            throw 'Too many arguments ('+arguments.length+' instead of '+(1+2)+')';
        return json_call_ajax(_url, "FBAFileUtil.phenotype_simulation_set_to_excel_file",
            [pss], 1, _callback, _errorCallback);
    };
  

    /*
     * JSON call using jQuery method.
     */
    function json_call_ajax(srv_url, method, params, numRets, callback, errorCallback, json_rpc_context) {
        var deferred = $.Deferred();

        if (typeof callback === 'function') {
           deferred.done(callback);
        }

        if (typeof errorCallback === 'function') {
           deferred.fail(errorCallback);
        }

        var rpc = {
            params : params,
            method : method,
            version: "1.1",
            id: String(Math.random()).slice(2),
        };
        if (json_rpc_context)
            rpc['context'] = json_rpc_context;

        var beforeSend = null;
        var token = (_auth_cb && typeof _auth_cb === 'function') ? _auth_cb()
            : (_auth.token ? _auth.token : null);
        if (token != null) {
            beforeSend = function (xhr) {
                xhr.setRequestHeader("Authorization", token);
            }
        }

        var xhr = jQuery.ajax({
            url: srv_url,
            dataType: "text",
            type: 'POST',
            processData: false,
            data: JSON.stringify(rpc),
            beforeSend: beforeSend,
            timeout: _timeout,
            success: function (data, status, xhr) {
                var result;
                try {
                    var resp = JSON.parse(data);
                    result = (numRets === 1 ? resp.result[0] : resp.result);
                } catch (err) {
                    deferred.reject({
                        status: 503,
                        error: err,
                        url: srv_url,
                        resp: data
                    });
                    return;
                }
                deferred.resolve(result);
            },
            error: function (xhr, textStatus, errorThrown) {
                var error;
                if (xhr.responseText) {
                    try {
                        var resp = JSON.parse(xhr.responseText);
                        error = resp.error;
                    } catch (err) { // Not JSON
                        error = "Unknown error - " + xhr.responseText;
                    }
                } else {
                    error = "Unknown Error";
                }
                deferred.reject({
                    status: 500,
                    error: error
                });
            }
        });

        var promise = deferred.promise();
        promise.xhr = xhr;
        return promise;
    }
}


