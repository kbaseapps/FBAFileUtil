# FBAFileUtil
---

Ported over scripts from Transform to work as SDK modules and deconstructed to allow SDK Data <-> File methods
for SDK developers.  Previously those scripts called the FBA service, but now call a local FBA service code
implementation directly.


Current Issues
================

 - SBML validator cannot run, because it looks for a specific executable in the base image that does not exist
   and it is unclear how to get it.  For now, the sbml validator does not run.

 - It seems most formats that are available to download produce files which cannot be directly uploaded back
   to the system.  This seems to be the case at least for models in excel (worksheet names don't match) and 
   sbml (duplicate id in file error), media in excel (worksheet names don't match).  

 - Workspace client in implementation of KBaseFBAModeling somehow tries to save objects before being instantiated.
   Thus, the user token isn't properly set.  This is fixed with a patched workspace client (in lib directory) that
   always sends the right token read in from the environment of the SDK job, but this should be fixed in the
   implementation.

 - Provenance should be updated so that it is fetched from the context object.  Right now, the FBA modeling
   implementation sets the provenance internally, so not all modules used are recorded.

 - 3 transform scripts do not work because of bugs in parsing the workspace and fba service URL.  Patched
   scripts are in the lib directory.

 - Tests run through basic cases (so any errors will fail tests), but checks for test output don't exist.  This
   would require someone with some knowledge on what to expect when downloading/uploading data under different
   circumstances.