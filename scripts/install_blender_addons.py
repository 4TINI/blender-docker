#!/usr/bin/python3

import bpy
import addon_utils
import os
import yaml
import subprocess

def download_file(url, download_path, addon_name):
    # Construct the local file path
    local_filename = os.path.join(download_path, addon_name + '.zip')
    
    # Use wget to download the file
    subprocess.run(["wget", "-O", local_filename, url], check=True)
    
    return local_filename

def install_addon(addon_name, addon_path=None):
    # Check if the addon is already installed
    mod = None

    if addon_name not in bpy.context.preferences.addons:
        print(f"{addon_name}: Addon not installed.")
        if addon_path:
            bpy.ops.preferences.addon_install(overwrite=True, filepath=addon_path)
            addon_utils.enable(addon_name, default_set=True, persistent=True)
            bpy.ops.preferences.addon_enable(module=addon_name)
    else:
        default, state = addon_utils.check(addon_name)
        if not state:
            try:
                mod = addon_utils.enable(addon_name, default_set=False, persistent=False)
            except Exception as e:
                print(f"{addon_name}: Could not enable Addon on the fly. Error: {e}")
    
    if mod:
        print(f"{addon_name}: enabled and running.")

def main():
    # Load the YAML file
    with open("/addons.yaml", "r") as file:
        addons_config = yaml.safe_load(file)
    
    # Refresh the list of available addons
    bpy.ops.preferences.addon_refresh()

    download_path = "/tmp"

    for item in addons_config['addons']:
        addon_name = item['name']
        print(addon_name)
        if 'link' in item:
            # If the addon has a link, download and install it
            addon_url = item['link']
            addon_file_path = download_file(addon_url, download_path, addon_name)

            install_addon(addon_name, addon_file_path)
        else:
            # If no link is provided, just enable the addon
            install_addon(addon_name)

if __name__ == "__main__":
    main()
