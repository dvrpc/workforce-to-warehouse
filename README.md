# workforce-to-warehouse

## Description
This repo holds work for FY25 for Mercer County. The goal of the project is to find ways to connect workforce to warehouses. 
This repo represents the technical analysis portion of the project, which includes importing GTFS data and building isochrones on the transit and pedestrian network.

To use this repo, you will need valid GTFS feeds from a transit agency, as well as a sidewalk network.

## Dependencies
Although not strictly necessary, this project uses the nix package manager to ensure dependability across systems. If you don't use nix, a requirements.txt will also be generated.

Other dependencies:
- PostGIS

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

### Download and import GTFS feeds
Download GTFS data from your transit agency. 

Use the shell command below to import the data. Repeat for other agencies or mode (e.g., rail, shuttle).

```console
gtfs2db append /path/to/gtfs/bus_data.zip 'postgresql://user:pw!@host:port/db'
```

If you're simply following along with the analysis DVRPC did, you can run `make load` to load the feeds in the /data folder. 

Note that you'll need to populate a .env file at the root of your project. A template is here. Note you can leave the DB_URI variable as-is, it populates based on the others.

```
PG_USER=postgres
PW=your_password
HOST=localhost
PORT=5555
DB=warehouse
DB_URI=postgresql://${PG_USER}@${HOST}:${PORT}/${DB}
  
```


## Project usage

## License
