from std.python import Python

struct ServiceLauncher:
    """
    Infrastructure Layer: Handles the execution of external service instances.
    Enables Ararat to orchestrate Docker, Singularity, and Local processes.
    As specified in NEXUS Section I.E: 'supports services running across multiple execution environments'.
    """
    
    def __init__(out self):
        pass

    def launch_container(mut self, platform: String, image: String, params: String) raises:
        """
        Launches a service safely using argument lists without shell=True to prevent command injection.
        """
        var subprocess = Python.import_module("subprocess")
        var shlex = Python.import_module("shlex")
        var builtins = Python.import_module("builtins")
        var sys = Python.import_module("sys")

        print("   [Launcher] Initializing " + platform + " instance: " + image)
        
        var cmd_list = builtins.list()
        if platform == "docker":
            cmd_list.append("docker")
            cmd_list.append("run")
            cmd_list.append("--rm")
            cmd_list.append(image)
        elif platform == "singularity":
            cmd_list.append("singularity")
            cmd_list.append("run")
            cmd_list.append(image)
        else:
            cmd_list.append(sys.executable)
            cmd_list.append(image)
            
        if params != "":
            var param_args = shlex.split(params)
            for i in range(len(param_args)):
                cmd_list.append(param_args[i])

        var max_retries = 3
        var attempt = 0
        var success = False
        var last_error = Error("Service execution failed")
        
        while attempt < max_retries and not success:
            attempt += 1
            try:
                if attempt > 1:
                    print("   [Launcher] Retry attempt " + String(attempt) + "/" + String(max_retries) + " for " + image)
                subprocess.run(cmd_list, shell=False, check=True)
                print("   [Launcher] Service execution completed successfully.")
                success = True
            except err:
                last_error = Error(String(err))
                if attempt == max_retries:
                    print("   [Launcher] ERROR: All " + String(max_retries) + " attempts failed for " + image + ": " + String(err))
                    raise last_error^



    def exec_shell_script(mut self, script_path: String) raises:
        """
        Executes a standalone research script safely without shell injection.
        """
        var subprocess = Python.import_module("subprocess")
        var builtins = Python.import_module("builtins")
        var sys = Python.import_module("sys")

        print("   [Launcher] Executing Script: " + script_path)
        var cmd_list = builtins.list()
        if script_path.endswith(".py"):
            cmd_list.append(sys.executable)
            cmd_list.append(script_path)
        elif script_path.endswith(".sh"):
            cmd_list.append("bash")
            cmd_list.append(script_path)
        else:
            cmd_list.append(script_path)

        subprocess.run(cmd_list, shell=False, check=True)

