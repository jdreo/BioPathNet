import argparse
import subprocess, sys

parser = argparse.ArgumentParser(description="Arguments to access the main functions of BioPathNets")
parser.add_argument("-f", "--function",    type=str, nargs=1,   default="run", help="the script to be called (run, predict, visualize, ...)")
parser.add_argument("-c", "--config",      type=str, nargs=1,   default="config/mock/mock_data_run.yaml", help="path to the YAML configuration file.")
parser.add_argument("-g", "--gpus",        type=str, nargs=1,   default="null", help="the list of gpus to be used. Eg [0]")
parser.add_argument("-s", "--seed",        type=int, nargs="?", default=None)
parser.add_argument("-cp", "--checkpoint", type=str, nargs="?", default=None, help="path to the stored trained model to be used.")
args = parser.parse_args()

cmd = []
function = args.function

if function.equals("run"):
    cmd = ["python", f"script/{function}.py",
                "-c", args.config,
                "--gpus", args.gpus
            ]

elif function.equals("predict")
    or function.equals("eval_and_predict")
    or function.equals("eval_and_predict_inductive")
    or function.equals("visualize")
    or function.equals("visualize_inductive"):
    if not args.checkpoint:
        logging.error(f"ERROR: Missing --checkpoint option for the {function} function")
    cmd = ["python", f"script/{function}.py",
                "-c", args.config,
                "--gpus", args.gpus,
                "--checkpoint", args.checkpoint
    ]

else:
    logging.error(f"Function {function} is not supported by the api.")
    logging.error(f"Supported functions: run, predict, eval_and_predict, eval_and_predict_inductive, visualize, visualize_inductive")

if args.seed:
    cmd.append([cmd, "-s", args.seed])

logging.debug(f"BioPathNet call command = {cmd}")

subprocess.run(command)
