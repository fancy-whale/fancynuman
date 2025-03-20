
def get_config_file [] {
    return (open $nu.config-path | split row "\n")
}

def get_mod_lines [] {
    let start_line = (get_config_file | enumerate | where item == "# start fancynugets" | get index | to text )
    let end_line = (get_config_file | enumerate | where item == "# end fancynugets" | get index | to text )
    return [["start", "end"]; [$start_line, $end_line]]
}

def check_git_repo [
    path
]: string -> bool {
    if ($path | path type | str ends-with "file") {
        log debug $"Skipping ($path | path split | last) as it is not a git repo"
        return false
    }
    if not (($path | path join ".git") | path exists) {
        log debug $"Skipping ($path | path split | last) as it is not a git repo"
        return false
    }
    return true
}

def list_numan_modules [] {
    let mod_lines = (get_mod_lines)
    let start = $mod_lines | get start | first | into int
    let end = $mod_lines | get end | first | into int
    let config_file = (get_config_file)
    let managed_lines = ($config_file | range $start..$end)
    let potential_managed_modules = ($managed_lines | where {$in | str starts-with "use"} | split column " " | get column2)
    mut managed_modules = []
    for module in $potential_managed_modules {
        let module_path = ($nu.default-config-dir | path join "modules" | path join $module | path split | drop 1 | path join)
        if (check_git_repo $module_path) {
            $managed_modules = ($managed_modules | append $module)
        }
    }
    return $managed_modules
}

def list_numan_scripts [] {
    let mod_lines = (get_mod_lines)
    let start = $mod_lines | get start | first | into int
    let end = $mod_lines | get end | first | into int
    let config_file = (get_config_file)
    let managed_lines = ($config_file | range $start..$end)
    let potential_managed_scripts = ($managed_lines | where {$in | str starts-with "source"} | split column " " | get column2)
    mut managed_scripts = []
    for script in $potential_managed_scripts {
        let script_path = ($nu.default-config-dir | path join "scripts" | path join $script | path split | drop 1 | path join)
        if (check_git_repo $script_path) {
            $managed_scripts = ($managed_scripts | append $script)
        }
    }
    return $managed_scripts
}

export def "numan list" [] {
    let managed_modules = (list_numan_modules | each {|module| [["Name", "Type"]; [$module, "Module"]]})
    let managed_scripts = (list_numan_scripts | each {|script| [["Name", "Type"]; [$script, "Script"]]})
    return ($managed_modules | append $managed_scripts | flatten)
}

export def "numan list modules" [] {
    return (list_numan_modules | each {|module| [["Name", "Type"]; [$module, "Module"]]} | flatten)
}

export def "numan list scripts" [] {
    return (list_numan_scripts | each {|script| [["Name", "Type"]; [$script, "Script"]]} | flatten)
}

# Numanagement
export def "numan mod add" [
    url: string # The URL of the module to be added; GitHub URLs only for now
] {
    let module_name = (echo $url | path basename | str replace ".git" "")
    let module_path = ($nu.default-config-dir | path join "modules" | path join $module_name)
    if ($module_path | path exists) {
        error make {msg: "Module already exists"}
    }
    git clone $url $module_path
    if not ($module_path | path join "mod.nu" | path exists) {
        rm -rf $module_path
        error make {msg: "Module does not contain a mod.nu file"}
    }
    let mod_lines = (get_mod_lines)
    let start = $mod_lines | get start | first | into int
    let end = $mod_lines | get end | first | into int
    let config_file = (get_config_file)
    let new_line = $"use ($module_name) *"
    $config_file | insert ($start + 1) $new_line | save -f $nu.config-path
    print $"Module ($module_name) added successfully"
}

def numan_modules [] {
    return (numan list modules | get Name | split column "/" | get column1)
}
    
export def "numan mod remove" [
    module_name: string@numan_modules # The name of the module to be removed
] {
    let module_path = ($nu.default-config-dir | path join "modules" | path join $module_name)
    if not ($module_path | path exists) {
        error make {msg: "Module doesn't exist"}
    }
    rm -rf $module_path
    let mod_lines = (get_mod_lines)
    let start = $mod_lines | get start | first | into int
    let end = $mod_lines | get end | first | into int
    let config_file = (get_config_file)
    let line_to_remove = $"use ($module_name) *"
    let fancynuget_lines = ($config_file | range $start..$end)
    let line_index = ($fancynuget_lines | enumerate | where item == $line_to_remove | get index | first | into int)
    let line_to_remove_index = ($start + $line_index)
    $config_file | drop nth $line_to_remove_index | save -f $nu.config-path
}

export def "numan script add" [
    url: string # The URL of the script to be added; GitHub URLs only for now
] {
    let script_name = (echo $url | path basename | str replace ".git" "")
    let script_path = ($nu.default-config-dir | path join "scripts" | path join $script_name)
    if ($script_path | path exists) {
        error make {msg: "Script already exists"}
    }
    git clone $url $script_path
    if not ($script_path | path join $"($script_name).nu" | path exists) {
        rm -rf $script_path
        error make {msg: "Script does not contain a .nu file with the same name as the script repository"}
    }
    let mod_lines = (get_mod_lines)
    let start = $mod_lines | get start | first | into int
    let end = $mod_lines | get end | first | into int
    let config_file = (get_config_file)
    let new_line = $"source ($script_name)/($script_name).nu"
    $config_file | insert ($start + 1) $new_line | save -f $nu.config-path
    print $"Script ($script_name) added successfully"
}


def numan_scripts [] {
    return (numan list scripts | get Name | split column "/" | get column1)
}

export def "numan script remove" [
    script_name: string@numan_scripts # The name of the script to be removed
] {
    let script_path = ($nu.default-config-dir | path join "scripts" | path join $script_name)
    if not ($script_path | path exists) {
        error make {msg: "Script doesn't exist"}
    }
    rm -rf $script_path
    let mod_lines = (get_mod_lines)
    let start = $mod_lines | get start | first | into int
    let end = $mod_lines | get end | first | into int
    let config_file = (get_config_file)
    let line_to_remove = $"source ($script_name)/($script_name).nu"
    let fancynuget_lines = ($config_file | range $start..$end)
    let line_index = ($fancynuget_lines | enumerate | where item == $line_to_remove | get index | first | into int)
    let line_to_remove_index = ($start + $line_index)
    $config_file | drop nth $line_to_remove_index | save -f $nu.config-path
}