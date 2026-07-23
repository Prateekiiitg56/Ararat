import sys
from src.controller.sdn import AraratOrchestrator
from src.infra.parser import WorkflowParser

def run_workflow(yaml_path: String, iterations: Int = 5) raises:
    """
    Utility function to load and execute a user-developed workflow safely.
    This is exported and can be imported by other scripts using 'from main import run_workflow'.
    """
    from std.python import Python
    var os = Python.import_module("os")
    
    if not (yaml_path.endswith(".yaml") or yaml_path.endswith(".yml")):
        raise Error("[Security Error] Workflow file must have a .yaml or .yml extension: " + yaml_path)

    if not os.path.exists(yaml_path):
        raise Error("[Error] Specified workflow file does not exist: " + yaml_path)

    print("[Ararat Framework] Initializing workflow execution...")
    var parser = WorkflowParser()
    var orchestrator = AraratOrchestrator()
    
    var nodes = parser.load_nodes_from_yaml(yaml_path)
    var edges = parser.load_edges_from_yaml(yaml_path)
    
    orchestrator.initialize_workflow(nodes^, edges^)
    orchestrator.run_simulation(iterations)


def main() raises:
    var args = sys.argv()
    if len(args) < 2:
        print("====================================================")
        print(" Ararat Software-Defined Workflow Framework")
        print("====================================================")
        print("Usage:")
        print("  pixi run mojo main.mojo <workflow_yaml_path> [--iterations <N>]")
        print("\nExample:")
        print("  pixi run mojo main.mojo workflows/neuromodulation.yaml --iterations 5")
        print("====================================================")
        return

    var yaml_path = args[1]
    var iterations = 5
    
    if len(args) >= 4 and args[2] == "--iterations":
        try:
            iterations = atol(args[3])
        except:
            print("[Warning] Invalid iteration count format. Defaulting to 5.")
            
    run_workflow(yaml_path, iterations)
