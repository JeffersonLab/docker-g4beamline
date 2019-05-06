FROM wmoore28/geant4:10.5.0_with_source

COPY tarballs/G4beamline-3.06-source.tgz /tmp/G4beamline.tgz
COPY test/g4bl-run.sh /share/g4bl-run.sh
COPY test/g4bl-test.g4bl /share/g4bl-test.g4bl

# Dependencies
RUN yum install -q -y \
        # G4beamline
        fftw-devel \
        gsl-devel \
        # needed for GUIs
        gtk2 \
        libxkbcommon \
    && yum clean all
ENV GSL_DIR  "/usr"
ENV FFTW_DIR "/usr"

# G4Beamline
# fix: add env variable that g4bl looks for
ENV Geant4_DIR /opt/geant4
ENV G4BL_DIR /opt/G4beamline
WORKDIR $G4BL_DIR
RUN mkdir /opt/G4beamline-source \
    && tar xzf /tmp/G4beamline.tgz -C /opt/G4beamline-source --strip-components 1 \
    # fix: issue with CMakeLists.txt filenames (cmake dependent??).
    && find /opt/G4beamline-source -name CMakelists.txt -exec rename lists.txt Lists.txt '{}' \; \
    && cmake ../G4beamline-source > /dev/null \ 
    && make -j `nproc` install > /dev/null \
    && sed -i 's/echo/#echo/g' bin/g4bl-setup.sh \
    # override default of $HOME/Geant4Data
    && echo $GEANT4_DIR/share/*/data > $G4BL_DIR/.data 
ENV PATH "$G4BL_DIR/bin:$PATH"

# Set up running environment and clean-up
WORKDIR /root
RUN rm -rf /opt/G4beamline-source $G4BL_DIR/*.tgz /tmp/G4beamline.tgz \
    && echo "source $G4BL_DIR/bin/g4bl-setup.sh" >> ~/.bashrc \
    # fix: g4bl won't run with empty /etc/machine-id
    && systemd-machine-id-setup \
    # remove "^M" that sneaks in
    && sed -i 's/\r//g' /share/g4bl-run.sh

CMD [ "/bin/bash" ]
