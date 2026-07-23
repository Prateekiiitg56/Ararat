from std.math import log


struct EvaluationEngine:
    """
    Evaluation suite for ARARAT framework performance and QoE.
    Implements standard HAS (HTTP Adaptive Streaming) metrics.
    """
    var alpha: Float64 # Weight for quality
    var beta: Float64  # Weight for switching penalty
    var gamma: Float64 # Weight for stalling penalty
    
    def __init__(out self):
        self.alpha = 1.0
        self.beta = 1.0
        self.gamma = 4.3 # Typical penalty weight for stalling in research

    def calculate_segment_qoe(
        self, 
        bitrate: Float64, 
        previous_bitrate: Float64, 
        stall_time: Float64
    ) -> Float64:
        """
        Computes the QoE for a single video segment.
        Formula: alpha * log(bitrate) - (beta * abs_change) - (gamma * stall_time)
        """
        var safe_bitrate = bitrate if bitrate > 0.0 else 1.0
        var safe_prev_bitrate = previous_bitrate if previous_bitrate > 0.0 else 0.0
        
        # Quality utility: logarithmic for diminishing returns, scaled by alpha
        var quality = self.alpha * log(safe_bitrate)
        
        # Switching penalty
        var switching_penalty: Float64 = 0.0
        if safe_prev_bitrate > 0.0:
            switching_penalty = self.beta * abs(log(safe_bitrate) - log(safe_prev_bitrate))
            
        # Stalling penalty
        var stalling_penalty = self.gamma * stall_time
        
        return quality - switching_penalty - stalling_penalty


    def calculate_network_cost(
        self, 
        bandwidth_used: Float64, 
        cpu_used: Float64, 
        is_edge_served: Bool
    ) -> Float64:
        """
        Computes the operational cost of serving the request.
        Edge-served requests may have higher compute costs but lower core bandwidth costs.
        """
        var bw_price = 0.1
        var cpu_price = 0.5
        
        var cost = (bandwidth_used * bw_price) + (cpu_used * cpu_price)
        
        # Adjust cost based on deployment (edge vs core)
        if is_edge_served:
            cost *= 0.8 # ARARAT aims for ~47% reduction in network costs
            
        return cost
