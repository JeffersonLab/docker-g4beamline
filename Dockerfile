FROM mazurov/cern-root

COPY tarballs/G4beamline-3.06-source.tgz /tmp/G4beamline.tgz
COPY tarballs/geant4-v10.5.0.tar.gz /tmp/geant4.tgz
COPY test/g4bl-run.sh /root/g4bl-run.sh
COPY test/g4bl-test.g4bl /root/g4bl-test.g4bl

# JLAB SSL-decryption
#RUN cd /etc/pki/ca-trust/source/anchors \
#    && curl -sLO http://pki.jlab.org/JLabCA.crt \
#    && update-ca-trust

# Dependencies
RUN yum install -y \
        # Geant4
        expat-devel \
        libXmu-devel \
        qt5-qtbase-devel \
        # G4beamline
        fftw-devel \
        gsl-devel \
        # needed for GUIs
        gtk2 \
        libxkbcommon \
    && yum clean all
ENV PATH     "/usr/lib64/qt5/bin:$PATH"
ENV GSL_DIR  "/usr"
ENV FFTW_DIR "/usr"

# Geant4
ENV GEANT4_DIR /opt/geant4
WORKDIR $GEANT4_DIR
RUN mkdir /opt/geant4-source \
    && tar xzf /tmp/geant4.tgz -C /opt/geant4-source --strip-components 1 \
    && rm /tmp/geant4.tgz \
    && cmake -DCMAKE_INSTALL_PREFIX=/opt/geant4 -DGEANT4_USE_QT=ON \
        -DBUILD_SHARED_LIBS=OFF -DBUILD_STATIC_LIBS=ON \
        -DGEANT4_BUILD_MUONIC_ATOMS_IN_USE=ON -DGEANT4_USE_SYSTEM_EXPAT=OFF \
        -DGEANT4_FORCE_QT4=OFF -DGEANT4_INSTALL_DATA=ON ../geant4-source \
    && make -j `nproc` install \
    && source bin/geant4.sh
ENV PATH "$GEANT4_DIR/bin:$PATH"

# G4Beamline
# fix: add env variable that g4bl looks for
ENV Geant4_DIR /opt/geant4
ENV G4BL_DIR /opt/G4beamline
WORKDIR $G4BL_DIR
RUN mkdir /opt/G4beamline-source \
    && tar xzf /tmp/G4beamline.tgz -C /opt/G4beamline-source --strip-components 1 \
    && rm /tmp/G4beamline.tgz \
    # fix: issue with CMakeLists.txt filenames (cmake dependent??).
    && find /opt/G4beamline-source -name CMakelists.txt -exec rename lists.txt Lists.txt '{}' \; \
    # fix: symlink G4DATA to expected location 
    && ln -s $GEANT4_DIR/share/*/data /root/Geant4Data \
    && cmake ../G4beamline-source \ 
    && make -j `nproc` install \
    # turn off echo so it doesn't show up every login
    && sed -i 's/echo/#echo/g' bin/g4bl-setup.sh

# Set up running environment and clean-up
WORKDIR /root
RUN rm -rf /opt/*source $G4BL_DIR/*.tgz \
    && echo "source $GEANT4_DIR/bin/geant4.sh" >> ~/.bashrc \
    && echo "source $G4BL_DIR/bin/g4bl-setup.sh" >> ~/.bashrc \
    # fix: g4bl won't run with empty /etc/machine-id
    && systemd-machine-id-setup \
    # remove "^M" that sneaks in
    && sed -i 's/\r//g' g4bl-run.sh

CMD [ "/bin/bash" ]
