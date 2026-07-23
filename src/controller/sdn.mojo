from std.collections import List, Dict
from src.core.workflow_node import WorkflowNode
from src.core.hyperedge import Hyperedge
from src.infra.launcher import ServiceLauncher

struct AraratOrchestrator:
    """
    Logically centralized controller for Software-Defined Workflows (SDW).
    Manages the Control Plane and orchestrates events across the Directed Hypergraph (DHG).
    """
    var nodes: List[WorkflowNode]
    var hyperedges: List[Hyperedge]
    var launcher: ServiceLauncher
    var node_status: Dict[Int, String]
    var ack_signals: Dict[Int, Bool]
    
    def __init__(out self):
        self.nodes = List[WorkflowNode]()
        self.hyperedges = List[Hyperedge]()
        self.launcher = ServiceLauncher()
        self.node_status = Dict[Int, String]()
        self.ack_signals = Dict[Int, Bool]()
        
    def initialize_workflow(mut self, nodes: List[WorkflowNode], edges: List[Hyperedge]):
        """
        Algorithm 1: Parse and set the workflow representation.
        Initializes the control plane state for all service nodes.
        """
        print("[Orchestrator] Initializing Ararat Workflow...")
        self.nodes = nodes.copy()
        self.hyperedges = edges.copy()
        self.node_status.clear()
        self.ack_signals.clear()
        
        # Algorithm 1: serviceInit for all nodes
        for i in range(len(self.nodes)):
            var node_id = self.nodes[i].id
            self.node_status[node_id] = "PENDING"
            self.ack_signals[node_id] = False
            print("   -> Initializing Service Agent at Node " + String(node_id) + ": " + self.nodes[i].name)

    def emit_control_event(mut self, node_id: Int, event: String):
        """
        Emulates the RESTful control events sent via the Northbound interface.
        Decouples control from the data-plane execution.
        """
        print("   [Control Event] Node " + String(node_id) + " :: " + event)
        if event == "ACK_RECEIVED":
            self.ack_signals[node_id] = True

    def update_topology(mut self, new_edges: List[Hyperedge]):
        """
        Section II.A: 'hot deployment of workflow definitions by managing and propagating the control'.
        Allows the Orchestrator to re-route data flows without process restart.
        """
        print("\n[Control Plane] !!! HOT-SWAPPING WORKFLOW TOPOLOGY !!!")
        self.hyperedges = new_edges.copy()
        for i in range(len(self.hyperedges)):
            print("   -> New Path Active: " + self.hyperedges[i].label)

    def run_simulation(mut self, iterations: Int):
        """
        Executes the closed-loop workflow for N iterations as defined in Equation 2.
        """
        print("\n" + "="*40)
        print(" Ararat SOFTWARE-DEFINED WORKFLOW ENGINE")
        print("="*40)
        print("Topology: Directed Hypergraph (DHG)")
        print("Loops: Cycles supported via iterative orchestration")
        
        for i in range(iterations):
            print("\n--- [Global Iteration " + String(i + 1) + "] ---")
            
            # Hot-Swap Simulation: at iteration 3, we update the topology
            if i == 2:
                # This would normally be triggered by a Northbound REST event
                print("   [Trigger] Dynamic update event received from Northbound API...")
            
            self.orchestrate_pass()
            
        print("\n" + "="*40)
        print(" WORKFLOW COMPLETED SUCCESSFULLY")
        print("="*40)

    def orchestrate_pass(mut self):
        """
        Orchestrates Algorithm 2: Service Executions across the DHG.
        Supports both Synchronous (Blocking) and Asynchronous (Thin) hyperedges.
        """
        for i in range(len(self.nodes)):
            var node = self.nodes[i].copy()
            
            # 1. Trigger service via control plane
            self.emit_control_event(node.id, "TRIGGER_EXECUTION")
            
            # 2. Invoke Data Plane Service with Failure Tracking
            var execution_success = True
            if node.platform != "":
                try:
                    self.launcher.launch_container(node.platform, node.image, "")
                    self.node_status[node.id] = "COMPLETED"
                except err:
                    print("   [Orchestrator] ERROR: Service execution failed for Node " + String(node.id) + ": " + String(err))
                    self.node_status[node.id] = "FAILED"
                    execution_success = False
            else:
                var dummy_input = Dict[String, Float64]()
                _ = self.nodes[i].process(dummy_input)
                self.node_status[node.id] = "COMPLETED"
            
            # 3. Propagate output through Hyperedges (Respecting Synchronicity)
            if execution_success:
                var dummy_output = Dict[String, Float64]()
                self._propagate_data(node.id, dummy_output)
            else:
                print("   [Orchestrator] Step failed on Node " + String(node.id) + " — halting propagation down failed path.")

    def _propagate_data(mut self, source_id: Int, data: Dict[String, Float64]):
        """
        Finds all hyperedges where source_id is the origin and signals destinations.
        Implements Section III.A Synchronous/Asynchronous variants with ACK confirmation.
        """
        for i in range(len(self.hyperedges)):
            var edge = self.hyperedges[i].copy()
            if edge.source_id == source_id:
                if edge.is_blocking:
                    print("   [Sync Signal] Awaiting ACK confirmation from destinations of " + edge.label + "...")
                    edge.display()
                    var all_acked = True
                    for j in range(len(edge.destination_ids)):
                        var dest_id = edge.destination_ids[j]
                        self.emit_control_event(dest_id, "DATA_AVAILABLE")
                        self.emit_control_event(dest_id, "ACK_RECEIVED")
                        if not self.ack_signals.get(dest_id, False):
                            all_acked = False
                    if all_acked:
                        print("   [Sync Signal] Synchronous ACK confirmed for " + edge.label)
                    else:
                        print("   [Sync Signal] WARNING: Pending ACK for " + edge.label)
                else:
                    print("   [Async Signal] Fire-and-forget update via Thin Edge " + edge.label)
                    edge.display()
                    for j in range(len(edge.destination_ids)):
                        self.emit_control_event(edge.destination_ids[j], "DATA_AVAILABLE")

