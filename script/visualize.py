import os
import sys
import pprint
import logging

import torch

from torchdrug import core
from torchdrug.utils import comm

from hlif_metrics.structures import conceptualGraph as cg 

sys.path.append(os.path.dirname(os.path.dirname(__file__)))
from biopathnet import dataset, layer, model, task, util


logger = util.get_root_logger()
logger.setLevel(logging.DEBUG)

def solver_load(checkpoint, load_optimizer=True):

    if comm.get_rank() == 0:
        logger.warning("Load checkpoint from %s" % checkpoint)
    checkpoint = os.path.expanduser(checkpoint)
    state = torch.load(checkpoint, map_location=solver.device)
    # some issues with loading back the graphs if present
    # remove
    state["model"].pop("fact_graph", 0)
    state["model"].pop("fact_graph_supervision", 0)
    state["model"].pop("graph", 0)
    state["model"].pop("train_graph", 0)
    state["model"].pop("valid_graph", 0)
    state["model"].pop("test_graph", 0)
    state["model"].pop("full_valid_graph", 0)
    state["model"].pop("full_test_graph", 0)
    # load without
    solver.model.load_state_dict(state["model"], strict=False)


    if load_optimizer:
        solver.optimizer.load_state_dict(state["optimizer"])
        for state in solver.optimizer.state.values():
            for k, v in state.items():
                if isinstance(v, torch.Tensor):
                    state[k] = v.to(solver.device)

    comm.synchronize()
    
def build_solver(cfg):
    cfg.task.model.num_relation = _dataset.num_relation
    _task = core.Configurable.load_config_dict(cfg.task)
    cfg.optimizer.params = _task.parameters()
    optimizer = core.Configurable.load_config_dict(cfg.optimizer)
    if "scheduler" in cfg:
        cfg.scheduler.optimizer = optimizer
        scheduler = core.Configurable.load_config_dict(cfg.scheduler)
    else:
        scheduler = None
    return core.Engine(_task, train_set, valid_set, test_set, optimizer, scheduler, **cfg.engine)



def load_vocab(dataset):
    entity_mapping = {}
    with open(vocab_file, "r") as fin:
        for line in fin:
            k, v = line.strip().split("\t")
            entity_mapping[k] = v
    entity_vocab = [entity_mapping[t] for t in dataset.entity_vocab]
    relation_vocab = ["%s (%d)" % (t[t.rfind("/") + 1:].replace("_", " "), i)
                      for i, t in enumerate(dataset.relation_vocab)]

    return entity_vocab, relation_vocab

def visualize_path(solver, triplet, entity_vocab, relation_vocab):
    num_relation = len(relation_vocab)
    h, t, r = triplet.tolist()
    logger.debug(f"triplet = {triplet}")
    logger.debug(f"head = {entity_vocab[h]}, relation = {relation_vocab[r]}, tail ={entity_vocab[t]}")
    triplet = torch.as_tensor([[h, t, r]], device=solver.device)
    inverse = torch.as_tensor([[t, h, r + num_relation]], device=solver.device)
    solver.model.eval()
    pred, (mask, target) = solver.model.predict_and_target(triplet)
    pos_pred = pred.gather(-1, target.unsqueeze(-1))
    rankings = torch.sum((pos_pred <= pred) & mask, dim=-1) + 1
    rankings = rankings.squeeze(0)

    logger.warning("")
    samples = (triplet, inverse)
    for sample, ranking in zip(samples, rankings):
        h, t, r = sample.squeeze(0).tolist()
        h_name = entity_vocab[h]
        t_name = entity_vocab[t]
        r_name = relation_vocab[r % num_relation]
        logger.debug(f"h_name = {h_name}, r_name = {r_name}, t_name ={t_name}")
        if r >= num_relation:
            r_name += "^(-1)"
        logger.warning(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>")
        logger.warning("rank(%s | %s, %s) = %g" % (h_name, r_name, t_name, ranking))

        paths, weights = solver.model.visualize(sample)
        for path, weight in zip(paths, weights):
            triplets = []
            cg_relations = []
            cg_concepts = []
            for h, t, r in path:
                cg_rel = {}
                cg_c1 = {}
                cg_c2 = {}
                h_name = entity_vocab[h]
                t_name = entity_vocab[t]
                r_name = relation_vocab[r % num_relation]
                cg_c1["ctype"] = ""
                cg_c1["referent"] = "h_name"
                cg_c2["ctype"] = ""
                cg_c2["referent"] = "t_name"
                if r >= num_relation:
                    r_name += "^(-1)"
                    cg_rel["rtype"] = r_name
                    cg_rel["args"] = [t_name, c_name]
                else:
                    cg_rel["rtype"] = r_name
                    cg_rel["args"] = [h_name, t_name]
                triplets.append("<%s, %s, %s>" % (h_name, r_name, t_name))
                cg_concepts.append(cg_c1)
                cg_concepts.append(cg_c2)
                cg_relations.append(cg_rel)
                cg_graph = cg.ConceptualGraph(cg_concepts, cg_relations)
                
            logger.warning("weight: %g\n\t%s" % (weight, " ->\n\t".join(triplets)))


if __name__ == "__main__":
    args, vars = util.parse_args()
    cfg = util.load_config(args.config, context=vars)
    working_dir = util.create_working_directory(cfg)
    vocab_file = os.path.join(os.path.dirname(__file__), cfg.dataset.path, "entity_names.txt")
    vocab_file = os.path.abspath(vocab_file)
    torch.manual_seed(args.seed + comm.get_rank())

    logger.warning("Working directory: %s" % working_dir)
    logger.warning("Config file: %s" % args.config)
    logger.warning(pprint.pformat(cfg))

    _dataset = core.Configurable.load_config_dict(cfg.dataset)
    train_set, valid_set, test_set = _dataset.split()
    solver = build_solver(cfg)
    
    if "checkpoint" in cfg:
        solver_load(cfg.checkpoint)
        
    entity_vocab, relation_vocab = load_vocab(_dataset)

    for i in range(len(solver.test_set)):
        visualize_path(solver, solver.test_set[i], entity_vocab, relation_vocab)
