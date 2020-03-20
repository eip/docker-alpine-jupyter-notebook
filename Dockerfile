FROM alpine:3.11

MAINTAINER eip
# docker container run -d --name jupyter-notebook -p 8888:8888 -v "$PWD":/opt/notebook eipdev/alpine-jupyter-notebook

ENV LANGUAGE=C.UTF-8 LC_ALL=C.UTF-8 LANG=C.UTF-8

ARG OPENCV_VERSION=4.2.0

RUN  apk update && apk upgrade \
	&& apk add --update --no-cache blas blas-dev build-base ca-certificates clang clang-dev cmake eigen eigen-dev freetype freetype-dev lapack lapack-dev libjpeg-turbo libjpeg-turbo-dev libpng libpng-dev libwebp libwebp-dev linux-headers openblas openblas-dev openexr openexr-dev pkgconf python3 python3-dev tiff tiff-dev tini wget \
	&& apk add --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing --update --no-cache libtbb libtbb-dev \
	&& apk add --repository http://dl-cdn.alpinelinux.org/alpine/v3.10/main --update --no-cache jasper-libs jasper-dev \
	&& pip3 install --no-cache-dir --upgrade pip setuptools \
	&& ln -fs /usr/include/libpng16 /usr/include/libpng \
	&& ln -fs /usr/include/locale.h /usr/include/xlocale.h \
	&& pip3 install --no-cache-dir --upgrade numpy \
	&& cd /tmp \
	&& echo "Downloading opencv" && wget --quiet https://github.com/opencv/opencv/archive/$OPENCV_VERSION.tar.gz \
	&& tar -xzf $OPENCV_VERSION.tar.gz \
	&& rm -rf $OPENCV_VERSION.tar.gz \
	&& mkdir -p /tmp/opencv-$OPENCV_VERSION/build && cd /tmp/opencv-$OPENCV_VERSION/build && echo "Building opencv..." \
	&& cmake -D CMAKE_BUILD_TYPE=RELEASE \
		-D CMAKE_C_COMPILER=/usr/bin/clang \
		-D CMAKE_CXX_COMPILER=/usr/bin/clang++ \
		-D CMAKE_INSTALL_PREFIX=/usr \
		-D INSTALL_C_EXAMPLES=NO \
		-D INSTALL_PYTHON_EXAMPLES=NO \
		-D WITH_IPP=NO \
		-D WITH_TBB=YES \
		-D WITH_FFMPEG=NO \
		-D WITH_1394=NO \
		-D WITH_LIBV4L=NO \
		-D WITH_V4l=NO \
		-D BUILD_DOCS=NO \
		-D BUILD_TESTS=NO \
		-D BUILD_PERF_TESTS=NO \
		-D BUILD_EXAMPLES=NO \
		-D BUILD_opencv_java=NO \
		-D BUILD_opencv_python2=NO \
		-D BUILD_ANDROID_EXAMPLES=NO \
		-D PYTHON3_LIBRARY=`find /usr -name libpython3.so` \
		-D PYTHON_EXECUTABLE=`which python3` \
		-D PYTHON3_EXECUTABLE=`which python3` \
		-D BUILD_opencv_python3=YES .. \
	&& make -j`grep -c '^processor' /proc/cpuinfo` && make install && echo "Successfully installed opencv" \
	&& cd / && rm -rf /tmp/opencv-$OPENCV_VERSION \
	&& mkdir -p /opt/notebook \
	&& pip3 install --no-cache-dir --upgrade matplotlib jupyter ipywidgets \
	&& jupyter nbextension enable --py widgetsnbextension \
	&& echo "c.NotebookApp.token = ''" > /root/.jupyter/jupyter_notebook_config.py \
	&& apk del --purge blas-dev build-base clang clang-dev cmake eigen-dev freetype-dev jasper-dev lapack-dev libjpeg-turbo-dev libpng-dev libtbb-dev libwebp-dev linux-headers openblas-dev openexr-dev pkgconf python3-dev tiff-dev wget \
	&& rm -r /root/.cache && rm -rf /var/cache/apk/* \
	&& find /usr/lib/python3.8/ -type d -name tests -depth -exec rm -rf {} \; \
	&& find /usr/lib/python3.8/ -type d -name test -depth -exec rm -rf {} \; \
	&& find /usr/lib/python3.8/ -name __pycache__ -depth -exec rm -rf {} \;

EXPOSE 8888
WORKDIR /opt/notebook
ENTRYPOINT ["/sbin/tini", "--"]
CMD ["jupyter", "notebook", "--ip=0.0.0.0", "--port=8888", "--no-browser", "--allow-root"]
