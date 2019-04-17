# docker-g4beamline
This build will contain Geant4 data.  So the final image size is >7GB.

## Versions
- G4beamline 3.06
- Geant4 10.5.0

From Docker image mazurov/cern-root
- CentOS 7.3
- Root 6.09.02
- CMake 3.6.3

## Usage
Build and run scripts are included to ensure reproducibility.
- docker-build.sh
- docker-run.sh

A test file is 
also included to verify installation.  

```
$> cd /root
$> ./g4bl-run.sh
$> root outputFile.root
  new TBrowser()
  exit(0)
```

