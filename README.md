# workforce-to-warehouse

## Description
This repo holds work for FY25 for Mercer County. The goal of the project is to find ways to connect workforce to warehouses. 
This repo represents the technical analysis portion of the project, which includes importing GTFS data and building isochrones on the transit and pedestrian network.

The idea is to start with a bounding box, a start time, and and end time, and build isochrones that use GTFS data plus sidewalk walksheds to create isochrones.

The isochrones are used to classify warehouses on their accessibility or lack thereof.

GTFS feeds used for the project, pulled in August 2024, are in the /data folder.

## Dependencies
Although not strictly necessary, this project uses the nix package manager to ensure dependability and reproducibility across systems. If you don't use nix, a requirements.txt will also be generated.

Other dependencies:
- PostgreSQL
- PostGIS
- PGRouting
- gdal/ogr2ogr

It's also worth noting that some of the input and output scripts utilize the U: drive behind DVRPC's firewall. 
If you're replicating on another machine (not behind DVRPC firewall), you'll need to update the .env file and point to your own warehouse data and your own path for outputs.

## Installation/Setup

### Environment setup
#### Nix
Clone the repo, activate the nix-shell with `nix-shell`.

#### Venv
Clone the repo, activate the virtual environment. Activate however you typically do in your shell.

| Platform | Shell      | Command to activate virtual environment |
|----------|------------|-----------------------------------------|
| POSIX    | bash/zsh   | $ source <venv>/bin/activate            |
|          | fish       | $ source <venv>/bin/activate.fish       |
|          | csh/tcsh   | $ source <venv>/bin/activate.csh        |
|          | PowerShell | $ <venv>/bin/Activate.ps1               |
| Windows  | cmd.exe    | C:\> <venv>\Scripts\activate.bat        |
|          | PowerShell | PS C:\> <venv>\Scripts\Activate.ps1     |

Install the required packages with `pip install -r requirements.txt`


### Makefile
The provided makefile runs all necessary commands to stand up the analysis.

Make sure all dependencies are installed. 

Set up your .env file matching the one below, then run `make all`.
```
PG_USER=postgres
PW=your_password
HOST=localhost
PORT=5555
DB=warehouse
DB_URI=postgresql://${PG_USER}@${HOST}:${PORT}/${DB}
UDRIVE_INPUT_GPKG=/mnt/u/FY2025/Transportation/WorkforceToWarehousesShuttleStudy/project_input/Costar/costar.gpkg
UDRIVE_OUTPUT_GPKG=/mnt/u/FY2025/Transportation/WorkforceToWarehousesShuttleStudy/project_output/isochrones/isochrone_shells.gpkg

```

You can review the makefile to see which specific files are being run, in which order, and which variables are passed in.  

If you want to update the GTFS data, update what is in the data folder with newer feeds, ensuring that the commands in `make load` point to your new data.


You can also run `make udrive` to push the isoshells tables into a geopackage.

Note that the U drive geopackage variables are in unix format- change them to Windows formatted paths if necessary (e.g., U:\here\is\a\windows\formatted\path)


## Project usage

## License
