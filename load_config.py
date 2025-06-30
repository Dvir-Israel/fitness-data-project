import os
import yaml

def load_config(env="local"):
    """
    Load configuration settings from config.yaml for the specified environment.
    Defaults to 'local' if no environment is passed in.
    """
    config_path = "config.yaml"
    
    if not os.path.exists(config_path):
        raise FileNotFoundError(f"Could not find config.yaml at: {config_path}")
    
    with open(config_path, "r") as f:
        all_configs = yaml.safe_load(f)

    if env not in all_configs:
        raise ValueError(f"Environment '{env}' not found in config.yaml.")
    
    return all_configs[env]
