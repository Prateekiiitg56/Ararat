from std.python import Python
from src.core.workflow_node import WorkflowNode
from src.core.hyperedge import Hyperedge
from std.collections import List

struct WorkflowParser:
    """
    Infrastructure Layer: Parses visual or JSON workflow definitions into the DHG structure.
    Implements Algorithm 1: parse(workflow) -> wfRepresentation with strict input validation.
    """
    
    def __init__(out self):
        pass

    def _validate_image_name(self, image: String) raises:
        """
        Validates image name to ensure no malicious shell injection characters exist.
        """
        var forbidden = List[String]()
        forbidden.append(";")
        forbidden.append("&")
        forbidden.append("|")
        forbidden.append("`")
        forbidden.append("$")
        forbidden.append("(")
        forbidden.append(")")
        forbidden.append("<")
        forbidden.append(">")
        forbidden.append("\n")
        forbidden.append("\r")
        for i in range(len(forbidden)):
            if forbidden[i] in image:
                raise Error("[Parser Error] Malicious character '" + forbidden[i] + "' detected in image name: " + image)


    def load_nodes_from_yaml(mut self, yaml_path: String) raises -> List[WorkflowNode]:
        """
        Loads and validates node definitions from a YAML workflow file.
        """
        var yaml = Python.import_module("yaml")
        var builtins = Python.import_module("builtins")
        var os = Python.import_module("os")
        
        if not os.path.exists(yaml_path):
            raise Error("[Parser Error] Workflow file not found: " + yaml_path)

        print("[Parser] Loading nodes from: " + yaml_path)
        
        var f = builtins.open(yaml_path, "r")
        var data = yaml.safe_load(f)
        f.close()
        
        if data is None or not builtins.isinstance(data, builtins.dict):
            raise Error("[Parser Error] Invalid YAML structure in file: " + yaml_path)

        if "nodes" not in data or data["nodes"] is None:
            raise Error("[Parser Error] Missing required 'nodes' section in workflow file: " + yaml_path)

        var nodes = List[WorkflowNode]()
        var seen_node_ids = List[Int]()
        var yaml_nodes = data["nodes"]
        if not builtins.isinstance(yaml_nodes, builtins.list):
            raise Error("[Parser Error] 'nodes' section must be a list in workflow file: " + yaml_path)
        
        for i in range(len(yaml_nodes)):

            var y_node = yaml_nodes[i]
            if "id" not in y_node:
                raise Error("[Parser Error] Node at index " + String(i) + " is missing required field 'id'")
            if "name" not in y_node:
                raise Error("[Parser Error] Node at index " + String(i) + " is missing required field 'name'")
            
            var id_val: Int
            try:
                id_val = atol(String(y_node["id"]))
            except:
                raise Error("[Parser Error] Node ID must be a numeric integer, got: " + String(y_node["id"]))

                
            for j in range(len(seen_node_ids)):
                if seen_node_ids[j] == id_val:
                    raise Error("[Parser Error] Duplicate Node ID found: " + String(id_val))
            seen_node_ids.append(id_val)
            
            var name = String(y_node["name"])
            var platform = String(y_node.get("platform", ""))
            var image = String(y_node.get("image", ""))
            
            if platform != "" and platform != "local" and platform != "docker" and platform != "singularity":
                raise Error("[Parser Error] Unsupported platform '" + platform + "' for node ID " + String(id_val))
                
            self._validate_image_name(image)
            
            print("   -> Node " + String(id_val) + ": " + name +
                  " [" + platform + "] " + image)
            nodes.append(WorkflowNode(id_val, name, platform, image))
            
        return nodes^

    def load_edges_from_yaml(mut self, yaml_path: String) raises -> List[Hyperedge]:
        """
        Parses and validates hyperedge definitions from a YAML file.
        """
        var yaml = Python.import_module("yaml")
        var builtins = Python.import_module("builtins")
        var os = Python.import_module("os")
        
        if not os.path.exists(yaml_path):
            raise Error("[Parser Error] Workflow file not found: " + yaml_path)

        print("[Parser] Loading edges from: " + yaml_path)
        
        var f = builtins.open(yaml_path, "r")
        var data = yaml.safe_load(f)
        f.close()

        if data is None or not builtins.isinstance(data, builtins.dict):
            raise Error("[Parser Error] Invalid YAML structure in file: " + yaml_path)
            
        if "edges" not in data or data["edges"] is None:
            raise Error("[Parser Error] Missing required 'edges' section in workflow file: " + yaml_path)
            
        var edges = List[Hyperedge]()
        var seen_edge_ids = List[Int]()
        var yaml_edges = data["edges"]
        if not builtins.isinstance(yaml_edges, builtins.list):
            raise Error("[Parser Error] 'edges' section must be a list in workflow file: " + yaml_path)
        
        for i in range(len(yaml_edges)):

            var y_edge = yaml_edges[i]
            if "id" not in y_edge or "label" not in y_edge or "source" not in y_edge or "destinations" not in y_edge:
                raise Error("[Parser Error] Hyperedge at index " + String(i) + " is missing required fields (id, label, source, destinations)")
                
            var id_val: Int
            var source: Int
            try:
                id_val = atol(String(y_edge["id"]))
                source = atol(String(y_edge["source"]))
            except:
                raise Error("[Parser Error] Hyperedge ID and source must be numeric integers")


            for j in range(len(seen_edge_ids)):
                if seen_edge_ids[j] == id_val:
                    raise Error("[Parser Error] Duplicate Hyperedge ID found: " + String(id_val))
            seen_edge_ids.append(id_val)
            
            var label = String(y_edge["label"])
            var blocking_int: Int = 1
            if "is_blocking" in y_edge:
                try:
                    blocking_int = atol(String(y_edge["is_blocking"]))
                except:
                    blocking_int = 1
            var sync = blocking_int == 1
            
            var dests = List[Int]()
            var y_dests = y_edge["destinations"]
            for j in range(len(y_dests)):
                var dest: Int = atol(String(y_dests[j]))
                dests.append(dest)
                
            print("   -> Hyperedge [" + label + "]: " + String(source) + " -> destinations")
            edges.append(Hyperedge(id_val, label, source, dests, sync))
            
        return edges^

