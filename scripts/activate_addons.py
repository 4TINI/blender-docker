import addon_utils
import bpy
import yaml

def main():
    # Load the YAML file
    with open("/addons.yaml", "r") as file:
        addons_config = yaml.safe_load(file)
    
    # Refresh the list of available addons
    bpy.ops.preferences.addon_refresh()
    
    for item in addons_config['addons']:
        addon_name = item['name']
        addon_utils.enable(addon_name, default_set=True, persistent=True)

if __name__ == "__main__":
    main()