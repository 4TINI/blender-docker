# Boosting Blender with Docker

Managing multiple Blender installations with distinct requirements and addons can be a complex and cumbersome task, especially when dealing with diverse project needs and software configurations. Using Docker to handle this process can significantly streamline and simplify the workflow. Docker allows each Blender instance to run in its own isolated container, ensuring that different versions, addons, and dependencies do not conflict with one another. This isolation not only prevents compatibility issues but also makes it easier to manage and switch between different setups without altering the system's core environment. Additionally, Docker's containerization facilitates consistent and reproducible environments, which is particularly beneficial for collaborative projects and version control. By leveraging Docker, users can efficiently maintain multiple Blender configurations, enhance productivity, and reduce the risk of errors or system conflicts.

## Requirements
- Docker (check [here](https://gist.github.com/4TINI/d05cf36d17826d775d007ac2d0a887d2) to install it autmatically)
- Enable your graphic card, if you have one. Follow [this guide](https://medium.com/@luca4tini/guide-to-easily-enable-the-graphic-card-in-ubuntu-4a0b21625bec) if you don't know how to do it.

For Python requirements in the Docker edit the [requirements.txt](config/requirements.txt) file.

## Adding Addons to a YAML Configuration File
Under the config folder you should find a file [addons.yaml](config/addons.yaml) that should list the addons you want to manage. Each addon can have a name and optionally a link if it's a custom addon that needs to be downloaded.

```yaml
addons:
  - name: <addon_name>
    link: <url_to_zip>  # Optional, only if it's a custom addon
  - name: <another_addon_name>

```

#### Add Custom Addons (From URLs)

Custom addons are those not included with Blender by default. They usually come as zip files hosted online.

```yaml
addons:
  - name: rokoko-studio-live-blender
    link: https://github.com/Rokoko/rokoko-studio-live-blender/archive/refs/heads/master.zip
```

#### Add Built-in Addons

Built-in addons are those that come with Blender by default. You don't need to provide a download link; just specify the name.

```yaml
addons:
  - name: measureit
```

> :warning: **Carefull with the indentation**: yaml file is particularly sensitive to indentation. the tags name and link should be equally indented.

## Build the Docker image
To build the docker run the following command

```bash
./docker_blender_build.sh <blender-release>
```

Check releases at https://download.blender.org/release/. If no release is provided it will default to Blender 4.1.1.

## Run the Docker Container
To simplify as much as possible the run process a custom alias have been crafted in the file [blender_aliases.sh](blender_aliases.sh). 

Modify the following path in the [blender_aliases.sh](blender_aliases.sh) file accordingly with the location where you cloned the repo.

```bash
# Alias for the blender script
alias blender='. $HOME/git/blender-docker/docker_blender_run.sh'
```

To make it available from everywhere run within the repo the following command:

```bash
echo "source $PWD/blender_aliases.sh" >> ~/.bashrc
```

From now on you should be able to run blender from every terminal location just running the command `blender`. If multiple blender images are built it will ask you to choose which one you want to run otherwise you can specify it from the beginning exploiting also the autocompletion

```bash
blender blender:4.1
```

The first time the run command is executed a folder called `blender` will be created in you HOME and automatically mounted within your container. Keep there the blender material created in order to save it locally. All the files won't be protected and will be owned by your hostname since the Dockerfile has been designed following the guidelines in [this guide](https://medium.com/@luca4tini/simplifying-the-use-of-a-custom-non-root-user-in-a-docker-container-72473ebd7482).
