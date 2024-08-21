# Function to list Docker images that start with the word "blender"
_docker_images() {
    docker images --format "{{.Repository}}:{{.Tag}}" | grep '^blender' 
}

# Completion function for blender
_blender_run_completions() {
    local cur
    _get_comp_words_by_ref -n : cur
    # Generate the possible completions
    COMPREPLY=( $(compgen -W "$(_docker_images)" -- "$cur") )
    __ltrim_colon_completions "$cur"
}

# Alias for the blender script
alias blender='. $HOME/git/blender-docker/docker_blender_run.sh'

# Register the completion function
complete -F _blender_run_completions blender
