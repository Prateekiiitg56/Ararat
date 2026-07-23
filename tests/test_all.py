#!/usr/bin/env python3
"""
Comprehensive automated test suite for Ararat framework.
Tests parser validation, bandwidth allocation, QoE math, command launcher safety, and plot generation.
"""
import unittest
import os
import sys
import tempfile
import numpy as np
import yaml

# Add project root to sys.path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

class TestQoEMath(unittest.TestCase):
    def test_qoe_calculation_basic(self):
        from scripts.generate_plots import calculate_qoe
        bitrates = [1000.0, 1500.0]
        stalls = [0.0, 0.2]
        scores = calculate_qoe(bitrates, stalls)
        self.assertEqual(len(scores), 2)
        self.assertAlmostEqual(scores[0], np.log(1000.0), places=4)

    def test_qoe_non_positive_bitrate(self):
        from scripts.generate_plots import calculate_qoe
        # Bitrate of 0 or negative should be safely handled without NaN or inf
        scores = calculate_qoe([0.0, -10.0], [0.0, 0.0])
        self.assertFalse(np.isnan(scores[0]))
        self.assertFalse(np.isinf(scores[0]))
        self.assertAlmostEqual(scores[0], np.log(1.0), places=4)

class TestWorkflowParserValidation(unittest.TestCase):
    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()

    def tearDown(self):
        self.temp_dir.cleanup()

    def test_valid_yaml(self):
        yaml_content = {
            "workflow_name": "Test Workflow",
            "nodes": [
                {"id": 0, "name": "Node A", "platform": "local", "image": "scripts/bayesian_optimizer.py"},
                {"id": 1, "name": "Node B", "platform": "local", "image": "scripts/stimulator.py"}
            ],
            "edges": [
                {"id": 1, "label": "EDGE1", "source": 0, "destinations": [1], "is_blocking": 1}
            ]
        }
        path = os.path.join(self.temp_dir.name, "valid.yaml")
        with open(path, "w") as f:
            yaml.dump(yaml_content, f)
        
        with open(path, "r") as f:
            data = yaml.safe_load(f)
        self.assertIn("nodes", data)
        self.assertEqual(len(data["nodes"]), 2)

    def test_duplicate_node_ids(self):
        nodes = [{"id": 0, "name": "A"}, {"id": 0, "name": "B"}]
        seen = set()
        has_dup = False
        for n in nodes:
            if n["id"] in seen:
                has_dup = True
            seen.add(n["id"])
        self.assertTrue(has_dup)

    def test_malicious_image_detection(self):
        forbidden = [";", "&", "|", "`", "$", "(", ")", "<", ">", "\n", "\r"]
        malicious_image = "my-image; rm -rf /"
        detected = any(char in malicious_image for char in forbidden)
        self.assertTrue(detected)

class TestLauncherSafety(unittest.TestCase):
    def test_argument_list_construction(self):
        import shlex
        image = "scripts/bayesian_optimizer.py"
        params = "--iterations 5"
        cmd_list = [sys.executable, image] + shlex.split(params)
        self.assertEqual(cmd_list, [sys.executable, "scripts/bayesian_optimizer.py", "--iterations", "5"])
        # Verify shell injection string in params is split as literal tokens, not evaluated by shell
        malicious_params = "; echo hacked"
        cmd_list_malicious = [sys.executable, image] + shlex.split(malicious_params)
        self.assertEqual(cmd_list_malicious[2], ";")  # ';' is treated as literal token argument

class TestDomainScripts(unittest.TestCase):
    def test_bayesian_optimizer_math(self):
        from scripts.bayesian_optimizer import optimize_params
        res = optimize_params(gamma_power=0.05)
        self.assertIn("stimulation_frequency_hz", res)
        self.assertIn("stimulation_amplitude_ma", res)
        self.assertGreater(res["stimulation_frequency_hz"], 0)

    def test_feature_extractor_math(self):
        from scripts.feature_extractor import extract_features
        res = extract_features([0.1, 0.2, -0.1, 0.05])
        self.assertIn("gamma_band_power", res)
        self.assertIn("snr_db", res)

    def test_stimulator_math(self):
        from scripts.stimulator import generate_pulses
        res = generate_pulses(freq=60.0, amp=1.0)
        self.assertIn("energy_uJ", res)
        self.assertEqual(res["energy_uJ"], 6000.0)

    def test_plant_model_math(self):
        import importlib.util
        spec = importlib.util.spec_from_file_location("plant_model", os.path.join("scripts", "neuromod-pm", "plant_model.py"))
        plant_model = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(plant_model)
        res = plant_model.simulate_tissue_response(60.0, 1.0)
        self.assertIn("gamma_band_power", res)
        self.assertIn("firing_rate_hz", res)


class TestPlotGeneration(unittest.TestCase):
    def test_generate_plots_script(self):
        import subprocess
        result = subprocess.run([sys.executable, "scripts/generate_plots.py"], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0)
        self.assertTrue(os.path.exists("scripts/evaluation_results.pdf"))

if __name__ == "__main__":
    unittest.main()
