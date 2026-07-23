from std.collections import Dict, List

struct WorkflowNode(Copyable, Movable):
    var id: Int
    var name: String
    var platform: String
    var image: String
    var contextual_variables: Dict[String, Float64]
    
    def __init__(out self, id: Int, name: String, platform: String = "", image: String = ""):
        self.id = id
        self.name = name
        self.platform = platform
        self.image = image
        self.contextual_variables = Dict[String, Float64]()
        
    def __copyinit__(out self, other: Self):
        self.id = other.id
        self.name = other.name
        self.platform = other.platform
        self.image = other.image
        self.contextual_variables = other.contextual_variables.copy()

    def __moveinit__(out self, owned other: Self):
        self.id = other.id
        self.name = other.name
        self.platform = other.platform^
        self.image = other.image^
        self.contextual_variables = other.contextual_variables^

    def copy(self) -> Self:
        var res = WorkflowNode(self.id, self.name, self.platform, self.image)
        res.contextual_variables = self.contextual_variables.copy()
        return res^

    def update_context(mut self, key: String, value: Float64):
        self.contextual_variables[key] = value
        
    def get_context(self, key: String) -> Float64:
        return self.contextual_variables.get(key, 0.0)

    def process(mut self, input_vars: Dict[String, Float64]) -> Dict[String, Float64]:
        print("   [Service]", self.name, "processing iteration data...")
        # Merge incoming input variables into contextual variables
        var output = self.contextual_variables.copy()
        output["processed_timestamp"] = 1.0
        return output^


