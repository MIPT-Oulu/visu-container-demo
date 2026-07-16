# VISU Tutorial — Predicting Heart Failure from Clinical Data

This demo shows how to train and interpret a machine learning classifier using clinical measurements from heart failure patients. The tutorial covers data splitting, model training with cross-validation, evaluation metrics, and feature importance analysis with SHAP.

The analysis runs inside a container, which bundles all the required software so that it works the same way on any machine.

---

## Contents

| File | Description |
|---|---|
| `VISU_tutorial.ipynb` | Main tutorial notebook |
| `Dockerfile` | Defines the container environment |
| `requirements.txt` | Python packages installed in the container |

---

## Step 1 — Download the dataset

Download the heart failure dataset from the UCI Machine Learning Repository:

https://archive.ics.uci.edu/dataset/519/heart+failure+clinical+records

Extract the zip file. Move the file `heart_failure_clinical_records_dataset.csv` to the `data` folder in the repository.

---

## Step 2 — Build the container image

Make sure [Docker](https://docs.docker.com/get-docker/) is installed and running, then build the image from the project folder:

```bash
docker build -t visu-demo-image:jupyter-notebook .
```

This downloads the base environment and installs all required packages. It may take a few minutes the first time.
The image is named `visu-demo-image` and tagged `jupyter-notebook`. 

---

## (Optional) — Run the notebook locally using a Docker container

Start JupyterLab using the below command. You can replace `./data` with the folder where you saved the dataset if necessary.

```bash
docker run --rm -p 8888:8888 -v ./data:/code/data visu-demo-image:jupyter-notebook
```

Open the URL printed in the terminal (starting with `http://127.0.0.1:8888/...`) in your browser, then open `VISU_tutorial.ipynb`.
You can go through the tutorial by running the individual code cells one after another or all at once.

> Using `-v ./data:/code/data` makes your local data folder available inside the container at the path `/code/data`. 
> The dataset file should be at `/code/data/heart_failure_clinical_records_dataset.csv` inside the container.

---

## Step 3 — Run Apptainer container in a sensitive data environment

On VISU, and other research platforms that use [Apptainer](https://apptainer.org/), the Docker image is first converted to an Apptainer image (`.sif` file). 
Sensitive data is not included in the image. 
It is provided to VISU staff by University of Oulu research services according to the research permit and made available inside the computing environment at `data/import`.

**Export the Docker image to a .tar file**

```bash
docker save -o visu-demo-image.tar visu-demo-image:jupyter-notebook
```

**Transfer the image (visu-demo-image.tar) and  to the research environment via sftp**, along with your dataset if required for the demo.

- Files are transferred to VISU using a secure shell file transfer protocol (SFTP).
- Create SSH-keypair
  - Command line → ssh-keygen -t ed25519 → Input file path → optional password → repeat password
	https://u.oulu.fi/sshkeys: login with University of Oulu account
- Add the previously saved public key (id_ed25519.pub) by copying the contents to the text field
- Default folder typically home/.ssh or C:/Users/username/.ssh
- Transfer files on the command line using sftp user@files.visu.oulu.fi 
- List available environments with ls and move to the import folder of the computing environment using cd visu-202xxxxx/import
- Transfer files to the import folder from the current local folder: put <path/filename>


**Convert the Docker image:**
```bash
apptainer build visu-demo-container.sif docker-archive:visu-demo-image.tar
```

**Run the notebook:**
```bash
apptainer exec --bind /data/import/data:/code/data visu-demo-container.sif \
    jupyter lab --ip=0.0.0.0 --no-browser
```

---

## Dataset reference

Chicco, D., Jurman, G. Machine learning can predict survival of patients with heart failure from serum creatinine and ejection fraction alone. *BMC Med Inform Decis Mak* **20**, 16 (2020). https://doi.org/10.1186/s12911-020-1023-5
