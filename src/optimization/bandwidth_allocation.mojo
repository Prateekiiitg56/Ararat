from src.core.link import Link
from std.collections import List

struct BandwidthAllocator:
    """
    Handles dynamic bandwidth allocation between collaborating edge nodes.
    Supports ARARAT's network-assisted video streaming optimization.
    """
    def __init__(out self):
        pass

    def allocate_bandwidth(
        self, 
        mut links: List[Link], 
        source_id: Int, 
        dest_id: Int, 
        amount: Float64
    ) -> Bool:
        """
        Allocates bandwidth on a specific link if available and subtracts the reserved amount.
        """
        for i in range(len(links)):
            if links[i].source_id == source_id and links[i].dest_id == dest_id:
                if links[i].available_bandwidth >= amount:
                    links[i].available_bandwidth -= amount
                    return True
        return False


    def calculate_required_bandwidth(mut self, bitrate: Float64, safety_factor: Float64) -> Float64:
        """
        Calculates required bandwidth based on video bitrate and a safety factor.
        """
        return bitrate * safety_factor
