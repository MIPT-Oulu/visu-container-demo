# Container computing tutorial for the VISU sensitive data computing environment

This demo shows how to train and interpret a machine learning classifier using clinical measurements from heart failure patients. The tutorial covers data splitting, model training with cross-validation, evaluation metrics, and feature importance analysis with SHAP.

The analysis runs inside a container, which bundles all the required software so that it works the same way on any machine and can be easily transferred to a sensitive data computing environment.

---

## Contents

| File                   | Description                                |
|------------------------|--------------------------------------------|
| `VISU_tutorial.ipynb`  | Jupyter notebook for computing results     |
| `Dockerfile`           | Defines the container environment          |
| `requirements.txt`     | Python packages installed in the container |

---

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) installed and running (Docker Desktop, Docker Compose or Docker Engine)
- At least a few GB of free disk space to build the Docker image (5.27 GB) and extract it (1.26 GB)
- For Step 3 (sensitive data / VISU environment): an active research permit, [computing envieonment order](https://eforms.oulu.fi/en) and an SSH key registered at https://u.oulu.fi/sshkeys

---

## Step 1 — Download the dataset

Download the heart failure dataset from the UCI Machine Learning Repository:

https://archive.ics.uci.edu/dataset/519/heart+failure+clinical+records

Extract the zip file. Move the file `heart_failure_clinical_records_dataset.csv` to the `data` folder in the repository.
Make sure that your user has access to the directory (Properties → Permissions)

---

## Step 2 — Build the Docker image

Make sure [Docker](https://docs.docker.com/get-docker/) is running and build the image from the project folder:

```bash
docker build -t visu-demo-image:jupyter-notebook .
```

This downloads the jupyter/scipy-notebook base environment and installs all required packages. It may take a few minutes the first time.
The image is named `visu-demo-image` and tagged `jupyter-notebook`. 

---

## (Optional) — Run the notebook locally using a Docker container

Start JupyterLab using the below command. You can replace `./data` with the folder where you saved the dataset if necessary.

```bash
docker run --rm -p 8888:8888 -v ./data:/code/data visu-demo-image:jupyter-notebook
```

Open the URL printed in the terminal (starting with `http://127.0.0.1:8888/...`) in your browser, then open `VISU_tutorial.ipynb`.
You can go through the notebook by running the individual code cells one after another or all at once.

> Using `-v ./data:/code/data` makes your local data folder available inside the container at the path `/code/data`. 
> The dataset file should be at `/code/data/heart_failure_clinical_records_dataset.csv` inside the container.

> The printed URL address contains an access token (character sequence after `?token=` parameter).
> JupyterLab uses this for user identification. No login is needed when the full URL address is used.
---

## Step 3 — Run Apptainer container in a sensitive data environment

On VISU, and other research platforms that use [Apptainer](https://apptainer.org/), the Docker image is first converted to an Apptainer image (`.sif` file). 
Sensitive data is not included in the image. 
It is provided to VISU staff by University of Oulu research services according to the research permit and made available inside the computing environment at `data/import`.

**Export the Docker image to a .tar file**

```bash
docker save -o visu-demo-image.tar visu-demo-image:jupyter-notebook
```

**Transfer the image (visu-demo-image.tar) to the computing environment via sftp**. Also, transfer the dataset for the demo.

- Files are transferred to VISU using a secure shell file transfer protocol (SFTP).
- Create SSH-keypair
  - Command line → `ssh-keygen -t ed25519` → optional file path → optional password → repeat password
	https://u.oulu.fi/sshkeys: login with the University of Oulu account
- Add the previously saved public key (`id_ed25519.pub`) by copying the contents to the text field
- The default folder is typically `home/.ssh` or `C:/Users/username/.ssh`
- Transfer files on the command line using `sftp user@files.visu.oulu.fi 
- List available environments with `ls` and move to the import folder of the computing environment using cd `visu-202xxxxx/import`
- Transfer files to the import folder from the current local folder: `put <path/filename>


**Convert the Docker image:**
```bash
apptainer build visu-demo-container.sif docker-archive:visu-demo-image.tar
```

**Run the notebook:**
```bash
apptainer exec \
    --bind ./data:/code/data \
    --env JUPYTER_RUNTIME_DIR=./tmp/jupyter-runtime \
    --env JUPYTER_DATA_DIR=./tmp/jupyter-data \
    visu-demo-container.sif \
    jupyter lab --ip=0.0.0.0 --no-browser --notebook-dir=/code
```

> The `--bind` flag allows access to the local data directory inside the container. 
> A code directory could also be bind-mounted here with a `,`separator. 
> The `--env` flags redirect Jupyter's runtime and data directories to `/tmp`, which is writable inside the container.
> Without these, Jupyter tries to write to your home directory (`/users/…`), which is read-only in the VISU environment.
> The `--notebook-dir` flag sets the working directory of JupyterLab to `/code` inside the container. 

---

## Stopping the container

- **Docker:** Press `Ctrl+C` in the terminal running JupyterLab, or run `docker stop <container_id>` from another terminal (find the ID with `docker ps`). If the container is started with `--rm`, it is removed automatically once stopped and no separate cleanup is needed.
- **Apptainer:** Press `Ctrl+C` in the terminal running JupyterLab. Apptainer containers do not need to be removed separately.

---

## Troubleshooting

- **Port 8888 already in use:** Stop the service using it, or change the port mapping, e.g. `-p 8889:8888`, and open `http://127.0.0.1:8889/...` instead.
- **Permission errors on the bind-mounted data folder:** Check that the local `data` folder exists and that your user has read/write access to it.
- **Apptainer build fails / runs out of space:** Building the `.sif` file requires temporary disk space beyond the final image size. Free up space, or set `APPTAINER_TMPDIR` to a location with more room.
- **Jupyter tries to write to a read-only home directory:** Make sure the `--env` flags from Step 3 are included exactly as shown; without them Jupyter defaults to your home directory, which is read-only in VISU.

---

## Support

For questions regarding Sensitive data computing environment VISU and its access or research permits, contact the University of Oulu VISU support or research services.  

---

## Dataset reference

Chicco, D., Jurman, G. Machine learning can predict survival of patients with heart failure from serum creatinine and ejection fraction alone. *BMC Med Inform Decis Mak* **20**, 16 (2020). https://doi.org/10.1186/s12911-020-1023-5
