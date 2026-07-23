# Ararat User Guide

This guide details how to create and manage custom Directed Hypergraph (DHG) topologies for your simulations in Ararat. Ararat natively supports defining these topologies either through human-readable **YAML** definitions or via programmatic initialization in **Mojo**. 

## 1. YAML-Driven Automation (Recommended)

The YAML-driven approach allows domain researchers to configure nodes and complex hyperedges without touching any underlying code. The `WorkflowParser` reads the YAML file, validates schema definitions, unique IDs, platform options, and path safety, and instantiates the required objects into the Ararat Orchestrator.

### Step 1: Defining the YAML Schema
Create a `.yaml` file within the `workflows/` directory. Your file must specify the global workflow name alongside two primary lists: `nodes` and `edges`.

Here is an example `neuromodulation.yaml` structure:
```yaml
workflow_name: Closed-Loop Neuromodulation
nodes:
  - id: 0
    name: Plant Model (PM)
    platform: docker
    image: kathiravelulab/neuromod-pm:latest
  - id: 1
    name: Bayesian Optimizer (CTL)
    platform: local
    image: scripts/bayesian_optimizer.py
edges:
  - id: 1
    label: NEURAL_RECORDING
    source: 0
    destinations:
      - 1
    is_blocking: 1
  - id: 2
    label: STIMULATION_PARAMS
    source: 1
    destinations:
      - 0
    is_blocking: 1
```

* `platform`: Allows you to map execution to standard operating systems (`local`) or container runtimes (`docker`, `singularity`).
* `is_blocking`: Setting this to `1` creates a synchronous link (the orchestrator blocks until an ACK is received), whereas `0` yields an asynchronous, fire-and-forget telemetry stream.

### Step 2: Instantiation in Mojo
Use the parser to load the workflow and bootstrap the Orchestrator with zero-code logic mapping:

```mojo
from src.infra.parser import WorkflowParser
from src.controller.sdn import AraratOrchestrator

var parser = WorkflowParser()
var workflow_data = parser.load_from_yaml("workflows/neuromodulation.yaml")

var orchestrator = AraratOrchestrator()
orchestrator.initialize_workflow(workflow_data.0, workflow_data.1)
orchestrator.run_simulation(10)
```

## 2. Programmatic Initialization (Mojo API)

If dynamically rendering topologies internally, you can construct `WorkflowNode` and `Hyperedge` primitives directly in Mojo. This leverages the strict memory ownership models to guarantee concurrent thread safety.

### Direct Instantiation
You must manually wrap components into lists and explicitly transfer ownership limits via reference syntax (`^`).

```mojo
from src.core.workflow_node import WorkflowNode
from src.core.hyperedge import Hyperedge
from src.controller.sdn import AraratOrchestrator
from std.collections import List

var orchestrator = AraratOrchestrator()

# Initialize decoupled Nodes
var sensing_node = WorkflowNode(0, "Sensing Agent")
var controller_node = WorkflowNode(1, "Controller Node")

var nodes = List[WorkflowNode](sensing_node^, controller_node^)

# Create a Directed Hyperedge targeting multiple destinations
var dests = List[Int](1)
var h_edge = Hyperedge(
    id=0, 
    label="TELEMETRY_SYNC", 
    source_id=0, 
    destination_ids=dests, 
    is_blocking=True  # Ensure synchronous feedback loop compliance
)
var edges = List[Hyperedge](h_edge^)

# Bootstrap Control Plane
orchestrator.initialize_workflow(nodes, edges)
orchestrator.run_simulation(10)
```
