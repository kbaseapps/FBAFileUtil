FROM kbase/kbase:sdkbase.latest
MAINTAINER KBase Developer


# update perl modules
RUN cpanm -i Config::IniFiles

# Install KBase Transform Scripts + dependencies
# Note: may not always be safe to copy things to /kb/deployment/lib
RUN mkdir -p /kb/module && cd /kb/module && git clone https://github.com/kbase/transform && \
    cd transform && git checkout 53633ed && \
    cp -ar lib/Bio/KBase/Transform /kb/deployment/lib/Bio/KBase

# Update FBA Modeling in the image.  This doesn't update any other dependencies, but
# we could do that here easily too if needed.  Note that pod2html has to be copied because
# the fba makefile expects it to be in the root bin directory!!
RUN cd /kb/dev_container/modules && \
    rm -rf KBaseFBAModeling && \
    git clone https://github.com/msneddon/KBaseFBAModeling && cd KBaseFBAModeling && \
    git checkout c8b2a0f && \
    cp /kb/runtime/bin/pod2html /bin/. && \
    make deploy TARGET=/kb/deployment KB_TOP=/kb/dev_container

# For right now, we need to patch the WS client to get the proper auth token.  Somehow
# with the script calling the Impl file calling the perl modules, the setup of the
# ws client is broken in some calls, and the ws client constructor seems to be never called
# before a function is called, leading to uninitialized authentication headers.  This
# uses the SDK user token and stuffs it in.  This should be fixed.  Do not copy this ever.
RUN rm -f /kb/deployment/lib/Bio/KBase/workspace/Client.pm
COPY lib/wsClientPatch.pm /kb/deployment/lib/Bio/KBase/workspace/Client.pm

COPY ./ /kb/module
RUN mkdir -p /kb/module/work
RUN chmod 777 /kb/module
RUN ls -l /kb/module/lib

WORKDIR /kb/module

RUN make all

ENTRYPOINT [ "./scripts/entrypoint.sh" ]

CMD [ ]
